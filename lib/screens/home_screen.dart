import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/app_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';
import '../widgets/schedule_pickup_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _pickupAddress = '';
  double? _pickupLat;
  double? _pickupLng;
  bool _locationError = false;
  int _recenterRevision = 0;
  Timer? _scheduledPoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passengerLiveLocationProvider.notifier).refresh();
      ref.read(activeTripProvider.notifier).refresh();
      ref.invalidate(scheduledRidesProvider);
      final loc = ref.read(passengerLiveLocationProvider);
      if (loc != null) {
        unawaited(_syncPickupFromCoords(loc.lat, loc.lng));
      }
    });
    _scheduledPoll = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollScheduledRides(),
    );
  }

  @override
  void dispose() {
    _scheduledPoll?.cancel();
    super.dispose();
  }

  /// Push is the primary signal, but if it is missed the home screen still
  /// picks up a reservation that has been dispatched into a live trip.
  void _pollScheduledRides() {
    if (!mounted) return;
    final upcoming = ref.read(scheduledRidesProvider).valueOrNull;
    if (upcoming == null || upcoming.isEmpty) return;
    final next = upcoming.first.scheduledAt;
    if (next == null ||
        next.difference(DateTime.now()) > const Duration(minutes: 35)) {
      return;
    }
    ref.invalidate(scheduledRidesProvider);
    ref.read(activeTripProvider.notifier).refresh();
  }

  void _startBooking({DateTime? scheduledAt}) {
    ref.read(scheduledPickupProvider.notifier).state = scheduledAt;
    context.push('/destination');
  }

  Future<void> _scheduleRide() async {
    final choice = await showPickupTimeSheet(
      context,
      initial: earliestScheduledPickup(),
    );
    if (choice == null || !mounted) return;
    _startBooking(scheduledAt: choice.at);
  }

  Future<void> _syncPickupFromCoords(double lat, double lng) async {
    if (!mounted) return;
    // GPS jitters every few seconds; only re-resolve after a real move so the
    // map and pickup address stay put.
    if (_pickupLat != null &&
        _pickupLng != null &&
        !_locationError &&
        _pickupAddress.isNotEmpty &&
        const Distance().as(
              LengthUnit.Meter,
              LatLng(_pickupLat!, _pickupLng!),
              LatLng(lat, lng),
            ) <
            30) {
      return;
    }
    var address = '';
    try {
      final place =
          await ref.read(mapsServiceProvider).reverseGeocode(lat, lng);
      address = place.address;
    } catch (_) {
      // Coordinates are still bookable without a street name.
    }
    if (!mounted) return;
    setState(() {
      _pickupLat = lat;
      _pickupLng = lng;
      _pickupAddress =
          address.isNotEmpty ? address : context.l10n.currentLocation;
      _locationError = false;
    });
    ref.read(homeMapPickupProvider.notifier).state = (
      lat: lat,
      lng: lng,
      rideTypeId: null,
    );
  }

  Future<void> _retryLocation() async {
    await ref.read(passengerLiveLocationProvider.notifier).refresh();
    final loc = ref.read(passengerLiveLocationProvider);
    if (loc != null) {
      await _syncPickupFromCoords(loc.lat, loc.lng);
    } else if (mounted) {
      setState(() {
        _locationError = true;
        _pickupAddress = context.l10n.locationUnavailable;
      });
    }
  }

  Future<void> _bookToSavedAddress(String lookupLabel) async {
    final displayLabel = lookupLabel == 'Home'
        ? context.l10n.quickHome
        : lookupLabel == 'Work'
            ? context.l10n.quickWork
            : lookupLabel;
    if (_pickupLat == null || _pickupLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.waitingForLocation)),
      );
      return;
    }
    try {
      final addresses = await ref
          .read(passengerServiceProvider)
          .getSavedAddresses();
      Map<String, dynamic>? match;
      for (final a in addresses) {
        if ((a['label'] as String?)?.toLowerCase() == lookupLabel.toLowerCase()) {
          match = a;
          break;
        }
      }
      if (match == null) {
        if (!mounted) return;
        final add = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.l10n.noSavedAddressTitle(displayLabel)),
            content: Text(ctx.l10n.noSavedAddressBody(displayLabel)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.l10n.addAddress),
              ),
            ],
          ),
        );
        if (add == true && mounted) context.push('/saved-addresses');
        return;
      }
      final dropLat =
          parseWktLat(match['location'] as String?) ??
          (match['lat'] as num?)?.toDouble();
      final dropLng =
          parseWktLng(match['location'] as String?) ??
          (match['lng'] as num?)?.toDouble();
      if (dropLat == null || dropLng == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.invalidSavedAddressCoords)),
        );
        return;
      }
      ref.read(scheduledPickupProvider.notifier).state = null;
      ref.read(bookingDraftProvider.notifier).state = TripBookingDraft(
        pickupLat: _pickupLat!,
        pickupLng: _pickupLng!,
        pickupAddress: _pickupAddress,
        dropoffLat: dropLat,
        dropoffLng: dropLng,
        dropoffAddress: match['address'] as String? ?? lookupLabel,
      );
      if (mounted) context.push('/ride-selection');
    } catch (e) {
      if (mounted) {
        showRawanaError(context, e);
      }
    }
  }

  /// Re-opens an unrated completed trip on the trip-complete screen.
  Future<void> _openPendingRating(Trip trip) async {
    final resumed = await ref.read(activeTripProvider.notifier).resumeTrip(trip.id);
    if (!mounted) return;
    if (resumed == null || resumed.status != TripStatus.completed) {
      ref.invalidate(pendingRatingProvider);
      return;
    }
    context.go('/trip-complete');
  }

  void _openActiveTrip(Trip trip) {
    if (trip.status == TripStatus.searching) {
      context.go('/searching');
      return;
    }
    context.go('/active-trip');
  }

  ({String label, Color color}) _passengerTripStatus(
    TripStatus status,
    AppLocalizations l10n,
  ) =>
      switch (status) {
        TripStatus.searching => (
          label: l10n.findingYourDriver,
          color: RawanaColors.accentDeep,
        ),
        TripStatus.accepted => (
          label: l10n.driverOnTheWay,
          color: RawanaColors.primary,
        ),
        TripStatus.driverArriving => (
          label: l10n.driverIsAtPickup,
          color: RawanaColors.warning,
        ),
        TripStatus.tripStarted => (
          label: l10n.onTripToDestination,
          color: RawanaColors.success,
        ),
        _ => (label: l10n.rideInProgress, color: RawanaColors.primary),
      };

  @override
  Widget build(BuildContext context) {
    final isOffline = !ref.watch(connectivityProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final profileAsync = ref.watch(passengerProfileProvider);
    final activeTripAsync = ref.watch(activeTripProvider);
    final activeTrip = activeTripAsync.valueOrNull;
    final liveTrip =
        activeTrip != null && activeTrip.status.isActive ? activeTrip : null;
    final pendingRating = ref.watch(pendingRatingProvider).valueOrNull;
    final upcomingRides =
        ref.watch(scheduledRidesProvider).valueOrNull ?? const <Trip>[];
    final nextScheduled =
        liveTrip == null && upcomingRides.isNotEmpty ? upcomingRides.first : null;
    final nearbyDrivers = ref.watch(nearbyDriversProvider);

    ref.listen(passengerLiveLocationProvider, (prev, next) {
      if (next != null) {
        unawaited(_syncPickupFromCoords(next.lat, next.lng));
      } else if (mounted) {
        setState(() {
          _locationError = true;
          _pickupAddress = context.l10n.locationUnavailable;
        });
      }
    });

    final liveLoc = ref.watch(passengerLiveLocationProvider);
    final youLat = liveLoc?.lat ?? _pickupLat;
    final youLng = liveLoc?.lng ?? _pickupLng;
    final markers = withCurrentLocationMarker(
      liveTrip == null
          ? buildNearbyDriverMarkers(nearbyDrivers)
          : const <RawanaMapMarker>[],
      lat: youLat,
      lng: youLng,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          RawanaMap(
            centerLat: _pickupLat,
            centerLng: _pickupLng,
            myLocationEnabled: youLat != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            recenterRevision: _recenterRevision,
            markers: markers,
            compassBottom: liveTrip != null ? 340 : 280,
          ),
          // Top safe-area area: greeting + avatar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: profileAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (profile) {
                        final name =
                            (profile['name'] as String?)?.split(' ').first ??
                            context.l10n.greetingNameFallback;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              RawanaSpacing.radiusPill,
                            ),
                            border: Border.all(
                              color: RawanaColors.outline.withValues(alpha: 0.35),
                            ),
                            boxShadow: RawanaShadows.floating,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: RawanaColors.accent.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: profileAsync.maybeWhen(
                                  data: (profile) {
                                    final url = profile['profile_photo_url'] as String?;
                                    if (url != null && url.isNotEmpty) {
                                      return Image.network(url, fit: BoxFit.cover);
                                    }
                                    return const Icon(
                                      LucideIcons.user,
                                      color: RawanaColors.accentDeep,
                                      size: 16,
                                    );
                                  },
                                  orElse: () => const Icon(
                                    LucideIcons.sun,
                                    color: RawanaColors.accentDeep,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  context.l10n.helloName(name),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: RawanaColors.onSurface,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  RawanaCircleIconButton(
                    icon: LucideIcons.user,
                    onPressed: () => context.push('/profile'),
                    tooltip: context.l10n.profile,
                  ),
                ],
              ),
            ),
          ),
          // Offline banner overlay
          if (isOffline)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: OfflineBanner(isOffline: true),
            ),
          // Rating prompt (unrated last trip) + promo banner
          Positioned(
            top: 88,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Column(
                children: [
                  if (liveTrip == null && pendingRating != null)
                    _RateLastTripCard(
                      trip: pendingRating,
                      onRate: () => _openPendingRating(pendingRating),
                      onDismiss: () => ref
                          .read(dismissedRatingPromptsProvider.notifier)
                          .update((s) => {...s, pendingRating.id}),
                    ),
                  if (nextScheduled != null)
                    Padding(
                      padding: EdgeInsets.only(
                        top: pendingRating != null ? 10 : 0,
                        bottom: 10,
                      ),
                      child: _UpcomingRideCard(
                        trip: nextScheduled,
                        extraCount: upcomingRides.length - 1,
                        onTap: () => context.push('/scheduled-rides'),
                      ),
                    ),
                  bannersAsync.when(
                    data: (banners) {
                      if (banners.isEmpty) return const SizedBox.shrink();
                      final banner = banners.first;
                      return Padding(
                        padding: EdgeInsets.only(
                          top: liveTrip == null && pendingRating != null ? 10 : 0,
                        ),
                        child: RawanaSurfaceCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          gradient: RawanaColors.accentGradient,
                          shadows: const [],
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                color: RawanaColors.primaryDeep,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  banner['message'] as String? ??
                                      banner['title'] as String? ??
                                      '',
                                  style: const TextStyle(
                                    color: RawanaColors.primaryDeep,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: liveTrip != null ? 340 : 280,
            child: MapRecenterButton(
              onPressed: () async {
                await _retryLocation();
                if (!mounted) return;
                final loc = ref.read(passengerLiveLocationProvider);
                setState(() {
                  if (loc != null) {
                    _pickupLat = loc.lat;
                    _pickupLng = loc.lng;
                  }
                  _recenterRevision++;
                });
              },
            ),
          ),
          // Bottom booking sheet or active trip banner
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: liveTrip != null
                  ? _buildActiveTripBanner(liveTrip)
                  : _buildBookingSheet(isOffline),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: RawanaShadows.low,
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(LucideIcons.compass),
                selectedIcon: const Icon(
                  LucideIcons.compass,
                  color: RawanaColors.primary,
                ),
                label: context.l10n.navRide,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.clock),
                selectedIcon: const Icon(
                  LucideIcons.clock,
                  color: RawanaColors.primary,
                ),
                label: context.l10n.history,
              ),
              NavigationDestination(
                icon: const Icon(LucideIcons.lifeBuoy),
                selectedIcon: const Icon(
                  LucideIcons.lifeBuoy,
                  color: RawanaColors.primary,
                ),
                label: context.l10n.help,
              ),
            ],
            onDestinationSelected: (i) {
              if (i == 1) context.push('/history');
              if (i == 2) context.push('/help');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripBanner(Trip trip) {
    final status = _passengerTripStatus(trip.status, context.l10n);

    return ActiveTripBanner(
      statusLabel: status.label,
      subtitle: trip.dropoffAddress,
      statusColor: status.color,
      fare: trip.cashToCollect,
      actionLabel: trip.status == TripStatus.searching
          ? context.l10n.viewSearch
          : context.l10n.viewRide,
      onTap: () => _openActiveTrip(trip),
    );
  }

  Widget _buildBookingSheet(bool isOffline) {
    return RawanaSurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      borderRadius: const BorderRadius.all(Radius.circular(RawanaSpacing.radiusXl)),
      shadows: RawanaShadows.sheet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const RawanaSheetHandle(padding: EdgeInsets.only(bottom: 12)),
          Row(
            children: [
              Text(
                context.l10n.whereTo,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: RawanaColors.onSurface,
                ),
              ),
              const Spacer(),
              _GpsStatusPill(
                state: _locationError
                    ? _GpsPillState.blocked
                    : (_pickupLat != null && _pickupLng != null
                          ? _GpsPillState.locked
                          : _GpsPillState.acquiring),
                onRetry: _locationError ? _retryLocation : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PickupRow(
            address: _pickupAddress.isEmpty
                ? context.l10n.gettingYourLocation
                : _pickupAddress,
            hasError: _locationError,
            onRefresh: _locationError ? _retryLocation : null,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isOffline ? null : () => _startBooking(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: RawanaColors.surfaceAlt,
                borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                border: Border.all(
                  color: isOffline
                      ? RawanaColors.outline.withValues(alpha: 0.5)
                      : RawanaColors.primary.withValues(alpha: 0.22),
                  width: 1.5,
                ),
                boxShadow: isOffline
                    ? null
                    : [
                        BoxShadow(
                          color: RawanaColors.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: isOffline
                          ? null
                          : RawanaColors.primaryGradient,
                      color: isOffline ? RawanaColors.outline : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.search,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.l10n.searchDestination,
                      style: const TextStyle(
                        color: RawanaColors.primaryDeep,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.arrowRight,
                    color: isOffline
                        ? RawanaColors.onSurfaceMuted
                        : RawanaColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.home,
                  label: context.l10n.quickHome,
                  onTap: () => _bookToSavedAddress('Home'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.briefcase,
                  label: context.l10n.quickWork,
                  onTap: () => _bookToSavedAddress('Work'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.bookmark,
                  label: context.l10n.quickSaved,
                  onTap: () => context.push('/saved-addresses'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: LucideIcons.calendarClock,
                  label: context.l10n.pickupLater,
                  onTap: isOffline ? () {} : _scheduleRide,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _GpsPillState { acquiring, locked, blocked }

class _UpcomingRideCard extends StatelessWidget {
  const _UpcomingRideCard({
    required this.trip,
    required this.extraCount,
    required this.onTap,
  });

  final Trip trip;
  final int extraCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final confirmed = trip.hasReservedDriver;
    final when = trip.scheduledAt != null
        ? formatScheduledTime(context, trip.scheduledAt!)
        : '';
    return RawanaSurfaceCard(
      padding: EdgeInsets.zero,
      shadows: RawanaShadows.floating,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: RawanaColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.calendarClock,
                  color: RawanaColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.scheduledFor(when),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      confirmed
                          ? context.l10n.driverConfirmed
                          : trip.dropoffAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: confirmed
                            ? RawanaColors.success
                            : RawanaColors.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (extraCount > 0)
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: RawanaColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(
                      RawanaSpacing.radiusPill,
                    ),
                  ),
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      color: RawanaColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: RawanaColors.onSurfaceFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateLastTripCard extends StatelessWidget {
  const _RateLastTripCard({
    required this.trip,
    required this.onRate,
    required this.onDismiss,
  });

  final Trip trip;
  final VoidCallback onRate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final destination = trip.dropoffAddress.isNotEmpty
        ? trip.dropoffAddress
        : context.l10n.destination;
    return RawanaSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      shadows: RawanaShadows.floating,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RawanaColors.warning.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.star, color: RawanaColors.warning, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.rateLastTripTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(
                  context.l10n.rateLastTripBody(destination),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RawanaColors.onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRate,
            child: Text(context.l10n.rateNow),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(LucideIcons.x, size: 18),
            tooltip: context.l10n.skipRating,
          ),
        ],
      ),
    );
  }
}

class _GpsStatusPill extends StatelessWidget {
  const _GpsStatusPill({required this.state, this.onRetry});

  final _GpsPillState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (color, label, leading) = switch (state) {
      _GpsPillState.locked => (
        RawanaColors.success,
        context.l10n.gpsLocked,
        const _Dot(color: RawanaColors.success),
      ),
      _GpsPillState.acquiring => (
        RawanaColors.warning,
        context.l10n.gpsAcquiring,
        const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            valueColor: AlwaysStoppedAnimation(RawanaColors.warning),
          ),
        ),
      ),
      _GpsPillState.blocked => (
        RawanaColors.error,
        context.l10n.gpsBlocked,
        const _Dot(color: RawanaColors.error),
      ),
    };

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          if (state == _GpsPillState.blocked && onRetry != null) ...[
            const SizedBox(width: 6),
            Icon(LucideIcons.refreshCcw, color: color, size: 12),
          ],
        ],
      ),
    );

    if (state != _GpsPillState.blocked || onRetry == null) return pill;
    return InkWell(
      onTap: onRetry,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      child: pill,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({
    required this.address,
    required this.hasError,
    this.onRefresh,
  });
  final String address;
  final bool hasError;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RawanaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: hasError
                  ? RawanaColors.error.withValues(alpha: 0.15)
                  : RawanaColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError ? LucideIcons.triangleAlert : LucideIcons.mapPin,
              color: hasError ? RawanaColors.error : RawanaColors.success,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.pickupLabel,
                  style: TextStyle(
                    color: RawanaColors.onSurfaceMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasError
                        ? RawanaColors.error
                        : RawanaColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(LucideIcons.refreshCcw, size: 18),
              color: RawanaColors.primary,
              onPressed: onRefresh,
              tooltip: context.l10n.retry,
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: RawanaColors.surfaceAlt,
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
            border: Border.all(
              color: RawanaColors.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: RawanaShadows.low,
                ),
                child: Icon(icon, color: RawanaColors.primary, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: RawanaColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
