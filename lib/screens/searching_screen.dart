import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';
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
  double _sheetHeight = 340;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
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
        ref.read(activeTripProvider.notifier).tryClearLocalTripState();
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
    // The search window is an admin setting and may outlast one polling round,
    // so keep polling until the server moves the trip out of `searching`.
    while (true) {
      await ref.read(activeTripProvider.notifier).pollUntilAccepted(tripId);
      if (!mounted || _userCancelled) return;
      await ref.read(activeTripProvider.notifier).refresh();
      if (!mounted || _userCancelled) return;
      final trip = ref.read(activeTripProvider).valueOrNull;
      if (trip == null || trip.status == TripStatus.cancelled) {
        if (trip != null) {
          _leaveForStatus(trip);
        } else {
          setState(() => _error = context.l10n.noDriversAvailable);
        }
        return;
      }
      if (trip.id != tripId) return;
      if (trip.status != TripStatus.searching) {
        _leaveForStatus(trip);
        return;
      }
    }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cancelFailed(apiErrorMessage(e)))),
        );
      }
      if (mounted) setState(() => _cancelling = false);
      return;
    }
    ref.read(activeTripProvider.notifier).tryClearLocalTripState(keepDraft: true);
    if (mounted) {
      setState(() => _cancelling = false);
      context.go('/ride-selection');
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cancelFailed(apiErrorMessage(e)))),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
    _userCancelled = true;
    ref.read(activeTripProvider.notifier).tryClearLocalTripState();
    if (mounted) context.go('/home');
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
        Future.microtask(() {
          if (!mounted || _userCancelled) return;
          _leaveForStatus(trip);
        });
      }
    });
    final draft = ref.watch(bookingDraftProvider);
    final trip = ref.watch(activeTripProvider).valueOrNull;
    final nearbyDrivers = ref.watch(nearbyDriversProvider);
    final rideTypes = ref.watch(rideTypesProvider).valueOrNull ?? const [];
    final selectedType = rideTypes.cast<RideType?>().firstWhere(
      (type) => type?.id == draft?.rideTypeId,
      orElse: () => rideTypes.isEmpty ? null : rideTypes.first,
    );
    final vehicleKind = VehicleKind.fromIconName(selectedType?.iconName);
    final pickupLat = draft?.pickupLat ?? trip?.pickupLat;
    final pickupLng = draft?.pickupLng ?? trip?.pickupLng;
    final pickupAddress = draft?.pickupAddress ?? trip?.pickupAddress ?? '';
    final dropoffAddress = draft?.dropoffAddress ?? trip?.dropoffAddress ?? '';
    final markers = <RawanaMapMarker>[
      ...buildNearbyDriverMarkers(nearbyDrivers, vehicleKind: vehicleKind),
      if (pickupLat != null && pickupLng != null)
        RawanaMapMarker.pickup(lat: pickupLat, lng: pickupLng, l10n: context.l10n),
    ];
    final hasError = _error != null;
    final title = _error ??
        ((trip?.rematchCount ?? 0) > 0
            ? context.l10n.findingAnotherDriver
            : context.l10n.findingYourDriver);
    final fare = trip?.cashToCollect;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RawanaMap(
                zoom: 15.5,
                centerLat: pickupLat,
                centerLng: pickupLng,
                markers: markers,
                gesturesEnabled: false,
                mapPadding: EdgeInsets.only(bottom: _sheetHeight),
              ),
            ),
            // Radar pulse sits on the pickup: the map centres the pickup in the
            // area above the sheet, and this overlay uses the same area.
            if (!hasError && pickupLat != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: _sheetHeight,
                child: IgnorePointer(
                  child: Center(
                    child: RepaintBoundary(
                      child: _PickupPulse(animation: _controller),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: RawanaCircleIconButton(
                    icon: LucideIcons.arrowLeft,
                    onPressed: _cancel,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: MeasureSize(
                onChange: (size) {
                  if (!mounted || (size.height - _sheetHeight).abs() < 1) return;
                  setState(() => _sheetHeight = size.height);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(RawanaSpacing.radiusXl),
                    ),
                    boxShadow: RawanaShadows.sheet,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const RawanaSheetHandle(),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              title,
                              key: ValueKey(title),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: hasError
                                    ? RawanaColors.error
                                    : RawanaColors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasError
                                ? context.l10n.retryOrCancelBelow
                                : context.l10n.lookingForDriversNearby,
                            style: const TextStyle(
                              color: RawanaColors.onSurfaceMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (!hasError)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                minHeight: 4,
                                color: RawanaColors.primary,
                                backgroundColor: RawanaColors.surfaceAlt,
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (pickupAddress.isNotEmpty || dropoffAddress.isNotEmpty)
                            TripRouteAddresses(
                              pickupAddress: pickupAddress,
                              dropoffAddress: dropoffAddress,
                              dense: true,
                            ),
                          if (fare != null && fare > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.banknote,
                                  size: 18,
                                  color: RawanaColors.success,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.cashFare,
                                  style: const TextStyle(
                                    color: RawanaColors.onSurfaceMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formatTripFare(fare),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (hasError) ...[
                            RawanaPrimaryButton(
                              label: context.l10n.tryAgain,
                              icon: LucideIcons.refreshCcw,
                              onPressed: _cancelling ? null : _tryAgain,
                            ),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton.icon(
                            onPressed: _cancelling ? null : _cancel,
                            icon: const Icon(LucideIcons.x, size: 18),
                            label: Text(context.l10n.cancelRequest),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: RawanaColors.error,
                              side: BorderSide(
                                color: RawanaColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.noCancellationFee,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: RawanaColors.onSurfaceMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uber-style radar: soft rings that ease out from the pickup point.
class _PickupPulse extends StatelessWidget {
  const _PickupPulse({required this.animation});

  final Animation<double> animation;

  static const _size = 240.0;
  static const _rings = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < _rings; i++)
                _ring((animation.value + i / _rings) % 1.0),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double t) {
    final eased = Curves.easeOutCubic.transform(t);
    final opacity = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: 0.12 + eased * 0.88,
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: RawanaColors.primary.withValues(alpha: 0.16),
            border: Border.all(
              color: RawanaColors.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
