import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:share_plus/share_plus.dart';

import '../booking/booking_map.dart';
import '../booking/booking_shell.dart';
import '../booking/places.dart';
import '../booking/trip_parts.dart';
import '../providers/app_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/trip_providers.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  Timer? _pollTimer;
  bool _cancelling = false;
  bool _detailsOpen = false;
  TripStatus? _lastStatus;
  LatLng? _lastDriver;
  CancellationPolicy? _policy;
  DateTime _policyFetchedAt = DateTime.now();
  String? _policyTripKey;
  late final TripChatUnreadPoller _chatPoller;
  int _chatUnread = 0;

  @override
  void initState() {
    super.initState();
    _chatPoller = TripChatUnreadPoller(ref.read(tripChatServiceProvider))..unread.addListener(_onUnreadChanged);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final trip = ref.read(activeTripProvider).valueOrNull;
      if (trip != null) _syncMap(trip);
      _refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _chatPoller.unread.removeListener(_onUnreadChanged);
    _chatPoller.dispose();
    super.dispose();
  }

  void _syncMap(Trip trip) {
    if (trip.pickupLat == null || trip.pickupLng == null || trip.dropoffLat == null || trip.dropoffLng == null) {
      return;
    }
    final loc = ref.read(driverLocationProvider);
    final driver = loc?.lat != null && loc?.lng != null ? LatLng(loc!.lat!, loc.lng!) : _lastDriver;
    ref.read(bookingMapProvider.notifier).showTrip(
          pickup: LatLng(trip.pickupLat!, trip.pickupLng!),
          dropoff: LatLng(trip.dropoffLat!, trip.dropoffLng!),
          started: trip.status == TripStatus.tripStarted,
          driver: driver,
        );
  }

  void _onUnreadChanged() {
    final next = _chatPoller.unread.value;
    if (!mounted || next == _chatUnread) return;
    final increased = next > _chatUnread;
    setState(() => _chatUnread = next);
    final trip = ref.read(activeTripProvider).valueOrNull;
    if (!increased || trip == null) return;
    final name = trip.driver?.name ?? context.l10n.yourDriver;
    showRawanaToast(
      context,
      context.l10n.newMessageFrom(name),
      icon: LucideIcons.messageCircle,
      actionLabel: context.l10n.openChat,
      onAction: () => _openChat(trip),
    );
  }

  Future<void> _openChat(Trip trip) async {
    final driver = trip.driver;
    _chatPoller.pause();
    setState(() => _chatUnread = 0);
    _chatPoller.clear();
    await showTallSheet<void>(
      context,
      TripChatScreen(
        tripId: trip.id,
        service: ref.read(tripChatServiceProvider),
        myRole: 'passenger',
        partyName: driver?.name ?? context.l10n.yourDriver,
        partySubtitle: [vehicleLabelOf(driver), driver?.plateNumber]
            .where((e) => e != null && e.isNotEmpty)
            .join(' · '),
        onCall: () => _callDriver(trip.id),
        onWhatsApp: () => _whatsAppDriver(trip.id),
      ),
    );
    if (mounted) _chatPoller.resume();
  }

  Future<void> _refresh() async {
    await ref.read(activeTripProvider.notifier).refresh();
    if (!mounted) return;
    final trip = ref.read(activeTripProvider).valueOrNull;
    if (trip?.status == TripStatus.completed) {
      context.go('/trip-complete');
    } else if (trip?.status == TripStatus.cancelled) {
      // Explain why the ride disappeared (driver / support / no drivers).
      showRawanaToast(context, passengerCancellationMessage(context.l10n, trip!), icon: LucideIcons.circleX);
      ref.read(activeTripProvider.notifier).tryClearLocalTripState();
      context.go('/home');
    } else if (trip?.driver != null && trip!.status != TripStatus.searching) {
      await _loadCancellationPolicy(trip);
    }
  }

  /// The free-cancel window is an admin setting; fetch it once per trip status
  /// so the countdown shown to the passenger matches what the server charges.
  Future<void> _loadCancellationPolicy(Trip trip) async {
    final key = '${trip.id}:${trip.status.apiValue}';
    if (_policyTripKey == key) return;
    if (trip.status != TripStatus.accepted && trip.status != TripStatus.driverArriving) return;
    try {
      final policy = await ref.read(tripServiceProvider).getCancellationPolicy(trip.id);
      if (!mounted) return;
      setState(() {
        _policy = policy;
        _policyFetchedAt = DateTime.now();
        _policyTripKey = key;
      });
    } catch (_) {}
  }

  Future<void> _callDriver(String tripId) =>
      callTripContact(context, api: ref.read(apiClientProvider), tripId: tripId);

  Future<void> _whatsAppDriver(String tripId) async {
    final ok = await messageTripParty(ref.read(apiClientProvider), tripId);
    if (!ok && mounted) {
      showRawanaToast(context, context.l10n.couldNotOpenWhatsAppMessages, error: true);
    }
  }

  Future<void> _cancelTrip(String tripId) async {
    var feeLine = context.l10n.cancelRideWarning;
    try {
      final policy = await ref.read(tripServiceProvider).getCancellationPolicy(tripId);
      if (!mounted) return;
      feeLine = policy.feeApplies
          ? context.l10n.cancellationFeeAmount(AfnFormatter.format(policy.cancellationFee))
          : context.l10n.noCancellationFee;
      if (policy.graceSeconds > 0) {
        feeLine = '$feeLine\n\n${context.l10n.cancelGraceSeconds('${policy.graceSeconds}')}';
      }
    } catch (_) {}
    if (!mounted) return;
    final confirm = await RawanaActionSheet.confirm(
      context,
      title: context.l10n.cancelThisRide,
      message: feeLine,
      confirmLabel: context.l10n.cancelRide,
      cancelLabel: context.l10n.keepRide,
      destructive: true,
      icon: LucideIcons.circleX,
    );
    if (!confirm || !mounted) return;
    setState(() => _cancelling = true);
    try {
      final result = await ref.read(tripServiceProvider).cancelRide(tripId, reason: 'Passenger cancelled');
      if (!mounted) return;
      if (result.cancellationFee > 0) {
        // Cash-first: the fee is collected on the next ride, so say so now.
        showRawanaToast(
          context,
          context.l10n.cancellationFeeChargedNextRide(AfnFormatter.format(result.cancellationFee)),
          icon: LucideIcons.banknote,
          duration: const Duration(seconds: 6),
        );
      }
    } catch (e) {
      // Most likely the trip already moved on (e.g. driver started the ride).
      await ref.read(activeTripProvider.notifier).refresh();
      if (mounted) showRawanaError(context, e);
      return;
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
    ref.read(activeTripProvider.notifier).tryClearLocalTripState();
    if (mounted) context.go('/home');
  }

  Future<void> _shareTrip(Trip trip) async {
    final driver = trip.driver;
    final loc = ref.read(driverLocationProvider);
    final lat = loc?.lat ?? _lastDriver?.latitude;
    final lng = loc?.lng ?? _lastDriver?.longitude;
    final vehicle = vehicleLabelOf(driver);
    final l10n = context.l10n;
    final lines = [
      l10n.shareTripIntro,
      if (driver?.name != null) l10n.shareDriver(driver!.name!),
      if (vehicle != null) l10n.shareVehicle(vehicle),
      if (driver?.plateNumber != null) l10n.sharePlate(driver!.plateNumber!),
      l10n.shareFrom(trip.pickupAddress),
      l10n.shareTo(trip.dropoffAddress),
      if (lat != null && lng != null) l10n.shareCurrentLocation('https://maps.google.com/?q=$lat,$lng'),
    ];
    await Share.share(lines.join('\n'), subject: l10n.shareTripSubject);
  }

  Future<void> _sendSos(Trip trip) async {
    final contacts = await ref.read(passengerServiceProvider).getEmergencyContacts();
    if (!mounted) return;
    if (contacts.isEmpty) {
      showRawanaToast(context, context.l10n.sosNoContacts, icon: LucideIcons.shieldAlert);
      context.push('/emergency-contacts');
      return;
    }
    final ok = await RawanaActionSheet.confirm(
      context,
      title: context.l10n.sos,
      message: context.l10n.sosConfirm,
      confirmLabel: context.l10n.sendSos,
      cancelLabel: context.l10n.cancel,
      destructive: true,
      icon: LucideIcons.siren,
    );
    if (!ok || !mounted) return;
    HapticFeedback.heavyImpact();
    final loc = ref.read(passengerLiveLocationProvider);
    try {
      final result = await ref.read(passengerServiceProvider).sendSos(tripId: trip.id, lat: loc?.lat, lng: loc?.lng);
      if (!mounted) return;
      final stub = result['stub'] == true;
      if (stub) {
        await _shareTrip(trip);
        if (!mounted) return;
      }
      showRawanaToast(context, stub ? context.l10n.sosFailed : context.l10n.sosSent, error: stub);
    } catch (_) {
      if (!mounted) return;
      showRawanaToast(context, context.l10n.sosFailed, error: true);
    }
  }

  Future<void> _openSafety(Trip trip) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RawanaGrabber(),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: RawanaColors.primary),
                    const SizedBox(width: 10),
                    Text(ctx.l10n.safetyToolkit, style: ctx.text.headline),
                  ],
                ),
              ),
              PlaceRow(
                icon: LucideIcons.share2,
                title: ctx.l10n.shareTrip,
                subtitle: ctx.l10n.safetyShareHint,
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
              const PlaceRowDivider(),
              PlaceRow(
                icon: LucideIcons.siren,
                title: ctx.l10n.sos,
                subtitle: ctx.l10n.safetySosHint,
                highlight: true,
                onTap: () => Navigator.pop(ctx, 'sos'),
              ),
              const PlaceRowDivider(),
              PlaceRow(
                icon: LucideIcons.users,
                title: ctx.l10n.emergencyContacts,
                subtitle: ctx.l10n.emergencyContactsHint,
                onTap: () => Navigator.pop(ctx, 'contacts'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'share':
        await _shareTrip(trip);
      case 'sos':
        await _sendSos(trip);
      case 'contacts':
        context.push('/emergency-contacts');
    }
  }

  ({String title, String subtitle}) _header(Trip trip, int? routeMinutes) {
    final l10n = context.l10n;
    switch (trip.status) {
      case TripStatus.tripStarted:
        final (place, _) = splitAddress(trip.dropoffAddress);
        final minutes = routeMinutes ?? trip.durationMinutes;
        return (
          title: l10n.headingTo(place),
          subtitle: minutes == null ? l10n.onYourWay : l10n.arriveAt(l10n.clockTime(DateTime.now().add(Duration(minutes: minutes)))),
        );
      case TripStatus.driverArriving:
        return (title: l10n.driverHereTitle, subtitle: l10n.meetDriverHint);
      default:
        final eta = routeMinutes ?? trip.pickupEtaMinutes;
        return (
          title: eta == null
              ? l10n.driverOnTheWay
              : eta <= 0
                  ? l10n.lessThanAMinute
                  : l10n.arrivingIn(eta),
          subtitle: [vehicleLabelOf(trip.driver), trip.driver?.plateNumber]
              .where((e) => e != null && e.isNotEmpty)
              .join(' · '),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Trip?>>(activeTripProvider, (prev, next) {
      final trip = next.valueOrNull;
      if (trip == null) return;
      if (_lastStatus != trip.status) {
        if (_lastStatus != null && trip.status == TripStatus.driverArriving) HapticFeedback.mediumImpact();
        _lastStatus = trip.status;
      }
      _syncMap(trip);
    });
    ref.listen<DriverLocation?>(driverLocationProvider, (_, loc) {
      if (loc?.lat == null || loc?.lng == null) return;
      _lastDriver = LatLng(loc!.lat!, loc.lng!);
      final trip = ref.read(activeTripProvider).valueOrNull;
      if (trip != null) _syncMap(trip);
    });

    final tripAsync = ref.watch(activeTripProvider);
    final trip = tripAsync.valueOrNull;
    if (trip == null) {
      if (!tripAsync.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/home');
        });
      }
      return const SizedBox.shrink();
    }
    if (trip.status == TripStatus.searching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/searching');
      });
      return const SizedBox.shrink();
    }

    _chatPoller.track(trip.driver != null ? trip.id : null);
    final map = ref.watch(bookingMapProvider);
    final started = trip.status == TripStatus.tripStarted;
    final canCancel = trip.status == TripStatus.accepted || trip.status == TripStatus.driverArriving;
    final header = _header(trip, map.route?.durationMinutes);
    final arrived = trip.status == TripStatus.driverArriving;
    final pin = trip.startPin;

    return Stack(
      children: [
        PositionedDirectional(
          top: 0,
          end: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RawanaCircleIconButton(
                icon: LucideIcons.shieldCheck,
                iconColor: RawanaColors.primary,
                tooltip: context.l10n.safetyToolkit,
                onPressed: () => _openSafety(trip),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: MapInsetReporter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16, bottom: 12),
                  child: RawanaCircleIconButton(
                    icon: LucideIcons.locateFixed,
                    tooltip: context.l10n.recenter,
                    onPressed: () => ref.read(bookingMapProvider.notifier).fit(),
                  ),
                ),
                RawanaSheetPanel(
                  child: AnimatedSize(
                    duration: RawanaMotion.medium,
                    curve: RawanaMotion.curve,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedSwitcher(
                                    duration: RawanaMotion.fast,
                                    child: Text(
                                      header.title,
                                      key: ValueKey(header.title),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.headline.copyWith(
                                        color: arrived ? RawanaColors.success : null,
                                      ),
                                    ),
                                  ),
                                  if (header.subtitle.isNotEmpty)
                                    Text(
                                      header.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.caption,
                                    ),
                                ],
                              ),
                            ),
                            if (arrived)
                              StatusPill(
                                label: context.l10n.driverIsAtPickup,
                                color: RawanaColors.success,
                                icon: LucideIcons.mapPin,
                                pulse: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TripDriverCard(
                          trip: trip,
                          onCall: trip.driver == null ? null : () => _callDriver(trip.id),
                          onChat: trip.driver == null ? null : () => _openChat(trip),
                          chatUnread: _chatUnread,
                        ),
                        if (pin != null && pin.isNotEmpty && !started) ...[
                          const SizedBox(height: 12),
                          TripPinBadge(pin: pin),
                        ],
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => setState(() => _detailsOpen = !_detailsOpen),
                          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.banknote, size: 18, color: RawanaColors.success),
                                const SizedBox(width: 10),
                                Expanded(child: Text(context.l10n.tripDetailsTitle, style: context.text.bodyStrong)),
                                Text(formatTripFare(trip.totalCash), style: context.text.price),
                                const SizedBox(width: 6),
                                AnimatedRotation(
                                  turns: _detailsOpen ? 0.5 : 0,
                                  duration: RawanaMotion.fast,
                                  child: const Icon(LucideIcons.chevronDown, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_detailsOpen) ...[
                          TripRouteAddresses(
                            pickupAddress: trip.pickupAddress,
                            dropoffAddress: trip.dropoffAddress,
                            dense: true,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _shareTrip(trip),
                            icon: const Icon(LucideIcons.share2, size: 18),
                            label: Text(context.l10n.shareTrip),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          ),
                        ],
                        if (canCancel) ...[
                          TextButton(
                            onPressed: _cancelling ? null : () => _cancelTrip(trip.id),
                            style: TextButton.styleFrom(
                              foregroundColor: RawanaColors.error,
                              minimumSize: const Size.fromHeight(44),
                            ),
                            child: _cancelling
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(context.l10n.cancelRide),
                          ),
                          FreeCancelCountdown(trip: trip, policy: _policy, fetchedAt: _policyFetchedAt),
                        ],
                      ],
                    ),
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
