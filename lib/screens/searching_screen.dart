import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';

class SearchingScreen extends ConsumerStatefulWidget {
  const SearchingScreen({super.key});

  @override
  ConsumerState<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends ConsumerState<SearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _error;
  bool _userCancelled = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _startSearch();
  }

  Future<void> _startSearch() async {
    await ref.read(activeTripProvider.notifier).refresh();
    if (!mounted) return;
    final activeTrip = ref.read(activeTripProvider).valueOrNull;
    final tripId = activeTrip?.id ?? ref.read(currentTripIdProvider);
    if (activeTrip != null) {
      ref.read(currentTripIdProvider.notifier).state = activeTrip.id;
      if (activeTrip.status == TripStatus.searching) {
        await _waitForMatch(activeTrip.id);
        return;
      }
      _leaveForStatus(activeTrip);
      return;
    }

    if (tripId == null) {
      setState(() => _error = context.l10n.missingTripDetails);
      return;
    }

    await _waitForMatch(tripId);
  }

  void _leaveForStatus(Trip trip) {
    if (trip.status == TripStatus.completed) {
      context.go('/trip-complete');
      return;
    }
    if (trip.status == TripStatus.cancelled) {
      if (_userCancelled) {
        ref.read(activeTripProvider.notifier).clearLocalTripState();
        context.go('/home');
        return;
      }
      // Distinguish "nobody accepted" from a support cancellation.
      setState(() => _error = trip.cancelledForNoDrivers || trip.cancelledBy == null
          ? context.l10n.noDriversAvailable
          : passengerCancellationMessage(context.l10n, trip));
      return;
    }
    context.go('/active-trip');
  }

  Future<void> _waitForMatch(String tripId) async {
    await ref.read(activeTripProvider.notifier).pollUntilAccepted(tripId);
    if (!mounted || _userCancelled) return;
    await ref.read(activeTripProvider.notifier).refresh();
    if (!mounted || _userCancelled) return;
    final trip = ref.read(activeTripProvider).valueOrNull;
    if (trip == null || trip.status == TripStatus.cancelled) {
      setState(() => _error = context.l10n.noDriversAvailable);
      return;
    }
    if (trip.status == TripStatus.searching) {
      return;
    }
    _leaveForStatus(trip);
  }

  Future<void> _tryAgain() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      final current = ref.read(activeTripProvider).valueOrNull;
      if (current != null && current.status == TripStatus.searching) {
        await ref.read(tripServiceProvider).cancelRide(
              current.id,
              reason: 'Passenger cancelled',
            );
      }
      ref.read(activeTripProvider.notifier).clearLocalTripState(keepDraft: true);
      if (mounted) context.go('/ride-selection');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cancelFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _cancel() async {
    if (_cancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.cancelSearchTitle),
        content: Text(ctx.l10n.cancelSearchBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.keepRide),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.l10n.cancelRequest,
              style: const TextStyle(color: RawanaColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(activeTripProvider.notifier).refresh();
      if (!mounted) return;
      final trip = ref.read(activeTripProvider).valueOrNull;
      if (trip != null && trip.status != TripStatus.searching) {
        _leaveForStatus(trip);
        return;
      }
      final tripId = trip?.id ?? ref.read(currentTripIdProvider);
      if (tripId != null) {
        await ref
            .read(tripServiceProvider)
            .cancelRide(tripId, reason: 'Passenger cancelled');
      }
      _userCancelled = true;
      ref.read(activeTripProvider.notifier).clearLocalTripState();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cancelFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Trip?>>(activeTripProvider, (_, next) {
      final trip = next.valueOrNull;
      if (!mounted || _userCancelled || trip == null) return;
      if (trip.status != TripStatus.searching) {
        _leaveForStatus(trip);
      }
    });
    final draft = ref.watch(bookingDraftProvider);
    final trip = ref.watch(activeTripProvider).valueOrNull;
    final nearbyDrivers = ref.watch(nearbyDriversProvider);
    final liveLoc = ref.watch(passengerLiveLocationProvider);
    final rideTypes = ref.watch(rideTypesProvider).valueOrNull ?? const [];
    final selectedType = rideTypes.cast<RideType?>().firstWhere(
      (type) => type?.id == draft?.rideTypeId,
      orElse: () => rideTypes.isEmpty ? null : rideTypes.first,
    );
    final vehicleKind = VehicleKind.fromIconName(selectedType?.iconName);
    final pickupLat = draft?.pickupLat ?? trip?.pickupLat;
    final pickupLng = draft?.pickupLng ?? trip?.pickupLng;
    final dropoffLat = draft?.dropoffLat ?? trip?.dropoffLat;
    final dropoffLng = draft?.dropoffLng ?? trip?.dropoffLng;
    final dropoffAddress = draft?.dropoffAddress ?? trip?.dropoffAddress;
    final markers = withCurrentLocationMarker(
      pickupLat != null &&
              pickupLng != null &&
              dropoffLat != null &&
              dropoffLng != null
          ? buildBookingMapMarkers(
              pickupLat: pickupLat,
              pickupLng: pickupLng,
              dropoffLat: dropoffLat,
              dropoffLng: dropoffLng,
              nearbyDrivers: nearbyDrivers,
              vehicleKind: vehicleKind,
              l10n: context.l10n,
            )
          : const <RawanaMapMarker>[],
      lat: liveLoc?.lat ?? pickupLat,
      lng: liveLoc?.lng ?? pickupLng,
    );
    final centerLat = pickupLat;
    final centerLng = pickupLng;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (pickupLat != null &&
              pickupLng != null &&
              dropoffLat != null &&
              dropoffLng != null)
            Positioned.fill(
              child: TripRouteMap(
                key: ValueKey('search_${trip?.id ?? draft?.rideTypeId ?? 'draft'}'),
                mapsService: ref.read(mapsServiceProvider),
                originLat: pickupLat,
                originLng: pickupLng,
                destLat: dropoffLat,
                destLng: dropoffLng,
                zoom: 14,
                markers: markers,
                showRouteSelector: true,
                routeSelectorBottomInset: 280,
              ),
            )
          else
            Positioned.fill(
              child: RawanaMap(
                zoom: 14,
                centerLat: centerLat,
                centerLng: centerLng,
                markers: markers,
              ),
            ),
          // Dim only the bottom sheet area so the route line stays visible.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      RawanaCircleIconButton(
                        icon: LucideIcons.arrowLeft,
                        onPressed: _cancel,
                      ),
                      const Spacer(),
                      const Spacer(),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children:
                          List.generate(3, (i) {
                            final progress = (_controller.value + i / 3) % 1.0;
                            return Opacity(
                              opacity: (1 - progress).clamp(0.0, 1.0),
                              child: Container(
                                width: 72 + progress * 160,
                                height: 72 + progress * 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: RawanaColors.primary.withValues(
                                      alpha: 0.45 * (1 - progress),
                                    ),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            );
                          })..add(
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                gradient: RawanaColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: RawanaShadows.ctaGlow,
                              ),
                              child: const Icon(
                                      LucideIcons.car,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error ??
                        ((trip?.rematchCount ?? 0) > 0
                            ? context.l10n.findingAnotherDriver
                            : context.l10n.findingYourDriver),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.15,
                      color: _error != null
                          ? RawanaColors.error
                          : RawanaColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _error == null
                        ? context.l10n.connectingToNearbyDrivers
                        : context.l10n.retryOrCancelBelow,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RawanaColors.onSurfaceMuted,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: RawanaPrimaryButton(
                      label: context.l10n.tryAgain,
                      icon: LucideIcons.refreshCcw,
                      onPressed: _cancelling ? null : _tryAgain,
                    ),
                  ),
                ],
                const Spacer(),
                if (dropoffAddress != null && dropoffAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: RawanaSurfaceCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  RawanaColors.primary.withValues(alpha: 0.14),
                                  RawanaColors.primaryBright.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.mapPin,
                              color: RawanaColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.destinationLabel,
                                  style: const TextStyle(
                                    color: RawanaColors.onSurfaceMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dropoffAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _cancelling ? null : _cancel,
                        icon: const Icon(LucideIcons.x, size: 18),
                        label: Text(context.l10n.cancelRequest),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: RawanaColors.error,
                          side: BorderSide(
                            color: RawanaColors.error.withValues(alpha: 0.4),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.noCancellationFee,
                        style: const TextStyle(
                          color: RawanaColors.onSurfaceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
