import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

import '../booking/booking_map.dart';
import '../booking/booking_shell.dart';
import '../booking/places.dart';
import '../providers/app_providers.dart';
import '../providers/history_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';
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
  Timer? _scheduledPoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(bookingMapProvider.notifier).showHome();
      ref.read(bookingDraftProvider.notifier).state = null;
      ref.read(passengerLiveLocationProvider.notifier).refresh();
      ref.read(activeTripProvider.notifier).refresh();
      ref.invalidate(scheduledRidesProvider);
      final loc = ref.read(passengerLiveLocationProvider);
      if (loc != null) unawaited(_syncPickupFromCoords(loc.lat, loc.lng));
    });
    _scheduledPoll = Timer.periodic(const Duration(seconds: 30), (_) => _pollScheduledRides());
  }

  @override
  void dispose() {
    _scheduledPoll?.cancel();
    super.dispose();
  }

  /// Push is the primary signal, but if it is missed Home still picks up a
  /// reservation that has been dispatched into a live trip.
  void _pollScheduledRides() {
    if (!mounted) return;
    final upcoming = ref.read(scheduledRidesProvider).valueOrNull;
    if (upcoming == null || upcoming.isEmpty) return;
    final next = upcoming.first.scheduledAt;
    if (next == null || next.difference(DateTime.now()) > const Duration(minutes: 35)) return;
    ref.invalidate(scheduledRidesProvider);
    ref.read(activeTripProvider.notifier).refresh();
  }

  Future<void> _syncPickupFromCoords(double lat, double lng) async {
    if (!mounted) return;
    // GPS jitters every few seconds; only re-resolve after a real move so the
    // pickup address stays put.
    if (_pickupLat != null &&
        _pickupLng != null &&
        !_locationError &&
        _pickupAddress.isNotEmpty &&
        const Distance().as(LengthUnit.Meter, LatLng(_pickupLat!, _pickupLng!), LatLng(lat, lng)) < 30) {
      return;
    }
    var address = '';
    try {
      address = (await ref.read(mapsServiceProvider).reverseGeocode(lat, lng)).address;
    } catch (_) {
      // Coordinates are still bookable without a street name.
    }
    if (!mounted) return;
    setState(() {
      _pickupLat = lat;
      _pickupLng = lng;
      _pickupAddress = address.isNotEmpty ? address : context.l10n.currentLocation;
      _locationError = false;
    });
    ref.read(homeMapPickupProvider.notifier).state = (lat: lat, lng: lng, rideTypeId: null);
  }

  Future<void> _retryLocation() async {
    await ref.read(passengerLiveLocationProvider.notifier).refresh();
    final loc = ref.read(passengerLiveLocationProvider);
    if (loc != null) {
      await _syncPickupFromCoords(loc.lat, loc.lng);
      ref.read(bookingMapProvider.notifier).recenter();
    } else if (mounted) {
      setState(() => _locationError = true);
    }
  }

  void _openSearch({bool editPickup = false}) {
    ref.read(scheduledPickupProvider.notifier).state = null;
    context.push(editPickup ? '/destination?focus=pickup' : '/destination');
  }

  Future<void> _scheduleRide() async {
    final choice = await showPickupTimeSheet(context, initial: earliestScheduledPickup());
    if (choice == null || !mounted) return;
    ref.read(scheduledPickupProvider.notifier).state = choice.at;
    context.push('/destination');
  }

  void _bookTo({required String address, required double lat, required double lng}) {
    if (_pickupLat == null || _pickupLng == null) {
      showRawanaMessage(context, context.l10n.waitingForLocation);
      return;
    }
    ref.read(scheduledPickupProvider.notifier).state = null;
    ref.read(bookingDraftProvider.notifier).state = TripBookingDraft(
      pickupLat: _pickupLat!,
      pickupLng: _pickupLng!,
      pickupAddress: _pickupAddress,
      dropoffLat: lat,
      dropoffLng: lng,
      dropoffAddress: address,
    );
    context.go('/ride-selection');
  }

  Future<void> _onSavedChip(String label, List<SavedPlace> saved) async {
    final place = findSavedPlace(saved, label);
    if (place != null) {
      _bookTo(address: place.address.isNotEmpty ? place.address : label, lat: place.lat, lng: place.lng);
      return;
    }
    final title = savedPlaceTitle(context, label);
    final add = await RawanaActionSheet.confirm(
      context,
      title: context.l10n.noSavedAddressTitle(title),
      message: context.l10n.noSavedAddressBody(title),
      confirmLabel: context.l10n.addAddress,
      cancelLabel: context.l10n.cancel,
      icon: savedPlaceIcon(label),
    );
    if (add && mounted) {
      await context.push('/saved-addresses');
      ref.invalidate(savedAddressesProvider);
    }
  }

  Future<void> _openPendingRating(Trip trip) async {
    final resumed = await ref.read(activeTripProvider.notifier).resumeTrip(trip.id);
    if (!mounted) return;
    if (resumed == null || resumed.status != TripStatus.completed) {
      ref.invalidate(pendingRatingProvider);
      return;
    }
    context.go('/trip-complete');
  }

  void _openActiveTrip(Trip trip) =>
      context.go(trip.status == TripStatus.searching ? '/searching' : '/active-trip');

  void _openMenu(Map<String, dynamic>? profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => _HomeMenuSheet(
        name: profile?['name'] as String?,
        photoUrl: profile?['profile_photo_url'] as String?,
        onSelect: (path) {
          Navigator.pop(sheet);
          context.push(path);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(passengerLiveLocationProvider, (prev, next) {
      if (next != null) {
        unawaited(_syncPickupFromCoords(next.lat, next.lng));
      } else if (mounted && _pickupLat == null) {
        setState(() => _locationError = true);
      }
    });

    final isOffline = !ref.watch(connectivityProvider);
    final profile = ref.watch(passengerProfileProvider).valueOrNull;
    final activeTrip = ref.watch(activeTripProvider).valueOrNull;
    final liveTrip = activeTrip != null && activeTrip.status.isActive ? activeTrip : null;
    final pendingRating = ref.watch(pendingRatingProvider).valueOrNull;
    final upcoming = ref.watch(scheduledRidesProvider).valueOrNull ?? const <Trip>[];
    final saved = parseSavedPlaces(ref.watch(savedAddressesProvider).valueOrNull ?? const []);
    final recent = ref.watch(recentPlacesProvider).valueOrNull ?? const <RecentPlace>[];
    final banners = ref.watch(bannersProvider).valueOrNull ?? const [];
    final firstName = (profile?['name'] as String?)?.trim().split(' ').first;

    Widget? notice;
    if (liveTrip == null && pendingRating != null) {
      notice = _NoticeRow(
        icon: LucideIcons.star,
        color: RawanaColors.warning,
        title: context.l10n.rateLastTripTitle,
        subtitle: pendingRating.dropoffAddress,
        actionLabel: context.l10n.rateNow,
        onTap: () => _openPendingRating(pendingRating),
        onDismiss: () => ref
            .read(dismissedRatingPromptsProvider.notifier)
            .update((s) => {...s, pendingRating.id}),
      );
    } else if (liveTrip == null && upcoming.isNotEmpty) {
      final next = upcoming.first;
      notice = _NoticeRow(
        icon: LucideIcons.calendarClock,
        color: RawanaColors.primary,
        title: context.l10n.scheduledFor(
          next.scheduledAt != null ? formatScheduledTime(context, next.scheduledAt!) : '',
        ),
        subtitle: next.hasReservedDriver ? context.l10n.driverConfirmed : next.dropoffAddress,
        actionLabel: upcoming.length > 1 ? '+${upcoming.length - 1}' : null,
        onTap: () => context.push('/scheduled-rides'),
      );
    } else if (liveTrip == null && banners.isNotEmpty) {
      final b = banners.first;
      final message = (b['message'] as String?) ?? (b['title'] as String?) ?? '';
      if (message.isNotEmpty) {
        notice = _NoticeRow(icon: LucideIcons.sparkles, color: RawanaColors.primary, title: message);
      }
    }

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MenuButton(
                  name: profile?['name'] as String?,
                  photoUrl: profile?['profile_photo_url'] as String?,
                  onTap: () => _openMenu(profile),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: liveTrip != null
                      ? Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _ActiveTripChip(trip: liveTrip, onTap: () => _openActiveTrip(liveTrip)),
                        )
                      : _PickupChip(
                          address: _locationError
                              ? context.l10n.locationOffTitle
                              : (_pickupAddress.isEmpty ? context.l10n.gettingYourLocation : _pickupAddress),
                          error: _locationError,
                          onTap: _locationError ? _retryLocation : () => _openSearch(editPickup: true),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (isOffline)
          const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner(isOffline: true)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: MapInsetReporter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16, bottom: 12),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: MapRecenterButton(onPressed: _retryLocation),
                  ),
                ),
                RawanaSheetPanel(
                  child: liveTrip != null
                      ? _LiveTripSummary(trip: liveTrip, onTap: () => _openActiveTrip(liveTrip))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (firstName != null && firstName.isNotEmpty) ...[
                              Text(context.l10n.helloName(firstName), style: context.text.caption),
                              const SizedBox(height: 8),
                            ],
                            _WhereToBar(
                              enabled: !isOffline,
                              onTap: () => _openSearch(),
                              onLater: isOffline ? null : _scheduleRide,
                            ),
                            const SizedBox(height: 12),
                            _SavedChips(
                              saved: saved,
                              onTap: (label) => _onSavedChip(label, saved),
                            ),
                            if (recent.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              for (final place in recent.take(2))
                                Builder(builder: (context) {
                                  final (title, subtitle) = splitAddress(place.address);
                                  return PlaceRow(
                                    icon: LucideIcons.clock,
                                    title: title,
                                    subtitle: subtitle,
                                    onTap: isOffline
                                        ? null
                                        : () => _bookTo(address: place.address, lat: place.lat, lng: place.lng),
                                  );
                                }),
                            ],
                            if (notice != null) ...[const SizedBox(height: 8), notice],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.name, required this.photoUrl, required this.onTap});

  final String? name;
  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.menuLabel,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: RawanaShadows.floating),
            child: RawanaAvatar(name: name ?? '', photoUrl: photoUrl, size: 42),
          ),
        ),
      ),
    );
  }
}

class _PickupChip extends StatelessWidget {
  const _PickupChip({required this.address, required this.error, required this.onTap});

  final String address;
  final bool error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = error ? RawanaColors.error : RawanaColors.pickupPin;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
          child: Container(
            height: 48,
            padding: const EdgeInsetsDirectional.only(start: 14, end: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
              boxShadow: RawanaShadows.floating,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(error ? LucideIcons.mapPinOff : LucideIcons.circleDot, size: 16, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyStrong.copyWith(color: error ? RawanaColors.error : null),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  error ? LucideIcons.refreshCw : LucideIcons.chevronDown,
                  size: 16,
                  color: RawanaColors.onSurfaceMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhereToBar extends StatelessWidget {
  const _WhereToBar({required this.enabled, required this.onTap, required this.onLater});

  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RawanaColors.surfaceAlt,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 18),
              const Icon(LucideIcons.search, size: 20, color: RawanaColors.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Text(context.l10n.whereTo, style: context.text.title),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
                  child: InkWell(
                    onTap: onLater,
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.calendarClock, size: 16, color: RawanaColors.onSurface),
                          const SizedBox(width: 6),
                          Text(context.l10n.rideLater, style: context.text.bodyStrong),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedChips extends StatelessWidget {
  const _SavedChips({required this.saved, required this.onTap});

  final List<SavedPlace> saved;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final labels = <String>['Home', 'Work'];
    for (final p in saved) {
      if (p.label.isNotEmpty && !labels.any((l) => l.toLowerCase() == p.label.toLowerCase())) {
        labels.add(p.label);
      }
    }
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = labels[i];
          final has = findSavedPlace(saved, label) != null;
          return ActionChip(
            avatar: Icon(savedPlaceIcon(label), size: 16, color: RawanaColors.onSurface),
            label: Text(savedPlaceTitle(context, label)),
            labelStyle: context.text.bodyStrong.copyWith(
              color: has ? RawanaColors.onSurface : RawanaColors.onSurfaceMuted,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: RawanaColors.outline),
            shape: const StadiumBorder(),
            onPressed: () => onTap(label),
          );
        },
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onTap,
    this.onDismiss,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodyStrong),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption),
                  ],
                ),
              ),
              if (actionLabel != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 8),
                  child: Text(actionLabel!, style: context.text.bodyStrong.copyWith(color: color)),
                ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(LucideIcons.x, size: 18),
                  color: RawanaColors.onSurfaceMuted,
                  tooltip: context.l10n.skipRating,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

({String label, Color color}) passengerTripStatus(TripStatus status, AppLocalizations l10n) =>
    switch (status) {
      TripStatus.searching => (label: l10n.findingYourDriver, color: RawanaColors.primary),
      TripStatus.accepted => (label: l10n.driverOnTheWay, color: RawanaColors.primary),
      TripStatus.driverArriving => (label: l10n.driverIsAtPickup, color: RawanaColors.success),
      TripStatus.tripStarted => (label: l10n.onTripToDestination, color: RawanaColors.success),
      _ => (label: l10n.rideInProgress, color: RawanaColors.primary),
    };

class _ActiveTripChip extends StatelessWidget {
  const _ActiveTripChip({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = passengerTripStatus(trip.status, context.l10n);
    return Material(
      color: RawanaColors.primaryDeep,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PulseDot(),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  status.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyStrong.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronRight, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(color: RawanaColors.successBright, shape: BoxShape.circle),
      ),
    );
  }
}

class _LiveTripSummary extends StatelessWidget {
  const _LiveTripSummary({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = passengerTripStatus(trip.status, context.l10n);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StatusPill(label: status.label, color: status.color, pulse: true),
            const Spacer(),
            Text(formatTripFare(trip.cashToCollect), style: context.text.price),
          ],
        ),
        const SizedBox(height: 12),
        TripRouteAddresses(pickupAddress: trip.pickupAddress, dropoffAddress: trip.dropoffAddress, dense: true),
        const SizedBox(height: 16),
        RawanaPrimaryButton(
          label: trip.status == TripStatus.searching ? context.l10n.viewSearch : context.l10n.viewRide,
          onPressed: onTap,
        ),
      ],
    );
  }
}

class _HomeMenuSheet extends StatelessWidget {
  const _HomeMenuSheet({required this.name, required this.photoUrl, required this.onSelect});

  final String? name;
  final String? photoUrl;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <(IconData, String, String)>[
      (LucideIcons.clock, l10n.history, '/history'),
      (LucideIcons.calendarClock, l10n.scheduledRides, '/scheduled-rides'),
      (LucideIcons.star, l10n.quickSaved, '/saved-addresses'),
      (LucideIcons.bell, l10n.notifications, '/notifications'),
      (LucideIcons.shieldCheck, l10n.emergencyContacts, '/emergency-contacts'),
      (LucideIcons.lifeBuoy, l10n.help, '/help'),
    ];
    return RawanaSheetPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onSelect('/profile'),
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  RawanaAvatar(name: name ?? '', photoUrl: photoUrl, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (name ?? '').isEmpty ? l10n.profile : name!,
                          style: context.text.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(l10n.account, style: context.text.caption),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 18, color: RawanaColors.onSurfaceMuted),
                ],
              ),
            ),
          ),
          const Divider(height: 8),
          for (final (icon, label, path) in items)
            PlaceRow(icon: icon, title: label, onTap: () => onSelect(path)),
        ],
      ),
    );
  }
}
