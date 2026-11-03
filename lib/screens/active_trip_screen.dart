import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/trip_providers.dart';
import '../providers/app_providers.dart';
import '../providers/live_location_providers.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  Timer? _pollTimer;
  Timer? _clockTimer;
  bool _cancelling = false;
  int? _etaMinutes;
  double? _distanceKm;
  int _routeRefitToken = 0;
  TripStatus? _lastTripStatus;
  String? _driverPhone;
  String? _loadedPhoneTripId;
  double? _lastDriverLat;
  double? _lastDriverLng;
  CancellationPolicy? _policy;
  DateTime _policyFetchedAt = DateTime.now();
  String? _policyTripKey;
  late final TripChatUnreadPoller _chatPoller;
  int _chatUnread = 0;
  double _sheetHeight = 320;

  @override
  void initState() {
    super.initState();
    _chatPoller = TripChatUnreadPoller(ref.read(tripChatServiceProvider))
      ..unread.addListener(_onUnreadChanged);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _refresh();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _chatPoller.unread.removeListener(_onUnreadChanged);
    _chatPoller.dispose();
    super.dispose();
  }

  void _onUnreadChanged() {
    final next = _chatPoller.unread.value;
    if (!mounted || next == _chatUnread) return;
    final increased = next > _chatUnread;
    setState(() => _chatUnread = next);
    final trip = ref.read(activeTripProvider).valueOrNull;
    if (!increased || trip == null) return;
    final name = trip.driver?.name ?? context.l10n.yourDriver;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.newMessageFrom(name)),
          action: SnackBarAction(
            label: context.l10n.openChat,
            onPressed: () => _openChat(trip),
          ),
        ),
      );
  }

  Future<void> _openChat(Trip trip) async {
    final driver = trip.driver;
    _chatPoller.pause();
    setState(() => _chatUnread = 0);
    _chatPoller.clear();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripChatScreen(
          tripId: trip.id,
          service: ref.read(tripChatServiceProvider),
          myRole: 'passenger',
          partyName: driver?.name ?? context.l10n.yourDriver,
          partySubtitle: [
            _driverSubtitle(driver),
            driver?.plateNumber,
          ].where((e) => e != null && e.isNotEmpty).join(' · '),
          onCall: () => _contactDriver(trip.id, call: true),
          onWhatsApp: () => _contactDriver(trip.id, call: false),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passengerCancellationMessage(context.l10n, trip!))),
      );
      ref.read(activeTripProvider.notifier).tryClearLocalTripState();
      context.go('/home');
    } else if (trip?.driver != null && trip!.status != TripStatus.searching) {
      await _loadDriverPhone(trip.id);
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

  Future<void> _loadDriverPhone(String tripId) async {
    if (_loadedPhoneTripId == tripId && _driverPhone != null) return;
    final phone = await fetchTripDialNumber(
      ref.read(apiClientProvider),
      tripId,
    );
    if (!mounted) return;
    setState(() {
      _driverPhone = phone;
      _loadedPhoneTripId = tripId;
    });
  }

  Future<void> _contactDriver(String tripId, {required bool call}) async {
    final api = ref.read(apiClientProvider);
    final ok = call
        ? await callTripParty(api, tripId)
        : await messageTripParty(api, tripId);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            call
                ? context.l10n.couldNotOpenWhatsAppCall
                : context.l10n.couldNotOpenWhatsAppMessages,
          ),
        ),
      );
    }
  }

  void _onDriverLocationUpdate(DriverLocation? loc) {
    if (loc?.lat == null || loc?.lng == null) return;
    _lastDriverLat = loc!.lat;
    _lastDriverLng = loc.lng;
  }

  Future<void> _cancelTrip(String tripId) async {
    var feeLine = context.l10n.cancelRideWarning;
    try {
      final policy = await ref
          .read(tripServiceProvider)
          .getCancellationPolicy(tripId);
      if (!mounted) return;
      feeLine = policy.feeApplies
          ? context.l10n.cancellationFeeAmount(
              AfnFormatter.format(policy.cancellationFee),
            )
          : context.l10n.noCancellationFee;
      if (policy.graceSeconds > 0) {
        feeLine =
            '$feeLine\n\n${context.l10n.cancelGraceSeconds('${policy.graceSeconds}')}';
      }
    } catch (_) {}
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.cancelThisRide),
        content: Text(feeLine),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.keepRide),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ctx.l10n.cancelRide,
              style: const TextStyle(color: RawanaColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _cancelling = true);
    try {
      final result = await ref
          .read(tripServiceProvider)
          .cancelRide(tripId, reason: 'Passenger cancelled');
      if (!mounted) return;
      if (result.cancellationFee > 0) {
        // Cash-first: the fee is collected on the next ride, so say so now.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.cancellationFeeChargedNextRide(
                AfnFormatter.format(result.cancellationFee),
              ),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Most likely the trip already moved on (e.g. driver started the ride);
      // resync so the screen reflects reality instead of a stale cancel button.
      await ref.read(activeTripProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
    ref.read(activeTripProvider.notifier).tryClearLocalTripState();
    if (mounted) context.go('/home');
  }

  Future<void> _shareTrip(Trip trip, double? driverLat, double? driverLng) async {
    final driver = trip.driver;
    final vehicle = [
      driver?.vehicleMake,
      driver?.vehicleModel,
      driver?.vehicleColour,
    ].where((e) => e != null && e.isNotEmpty).join(' ');
    final liveLocationUrl = driverLat != null && driverLng != null
        ? 'https://maps.google.com/?q=$driverLat,$driverLng'
        : null;
    final l10n = context.l10n;
    final lines = [
      l10n.shareTripIntro,
      if (driver?.name != null) l10n.shareDriver(driver!.name!),
      if (vehicle.isNotEmpty) l10n.shareVehicle(vehicle),
      if (driver?.plateNumber != null) l10n.sharePlate(driver!.plateNumber!),
      l10n.shareFrom(trip.pickupAddress),
      l10n.shareTo(trip.dropoffAddress),
      if (liveLocationUrl != null) l10n.shareCurrentLocation(liveLocationUrl),
    ];
    await Share.share(lines.join('\n'), subject: l10n.shareTripSubject);
  }

  Future<void> _sendSos(Trip trip) async {
    final contacts = await ref.read(passengerServiceProvider).getEmergencyContacts();
    if (!mounted) return;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sosNoContacts)),
      );
      context.push('/emergency-contacts');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.sos),
        content: Text(ctx.l10n.sosConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.sendSos)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final loc = ref.read(passengerLiveLocationProvider);
    try {
      final result = await ref.read(passengerServiceProvider).sendSos(
            tripId: trip.id,
            lat: loc?.lat,
            lng: loc?.lng,
          );
      if (!mounted) return;
      final stub = result['stub'] == true;
      if (stub) {
        await _shareTrip(trip, loc?.lat, loc?.lng);
        if (!mounted) return;
      }
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stub ? l10n.sosFailed : l10n.sosSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.sosFailed)),
      );
    }
  }

  ({String label, Color color, IconData icon}) _statusInfo(
    TripStatus status,
    AppLocalizations l10n,
  ) =>
      switch (status) {
        TripStatus.accepted => (
          label: l10n.driverOnTheWay,
          color: RawanaColors.primary,
          icon: LucideIcons.navigation,
        ),
        TripStatus.driverArriving => (
          label: l10n.driverIsAtPickup,
          color: RawanaColors.warning,
          icon: LucideIcons.mapPinCheck,
        ),
        TripStatus.tripStarted => (
          label: l10n.onTripToDestination,
          color: RawanaColors.success,
          icon: LucideIcons.car,
        ),
        _ => (
          label: l10n.connecting,
          color: RawanaColors.onSurfaceMuted,
          icon: LucideIcons.loader,
        ),
      };

  String? _driverSubtitle(TripParty? driver) {
    if (driver == null) return null;
    return [
      driver.vehicleMake,
      driver.vehicleModel,
    ].where((e) => e != null && e.isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(activeTripProvider);
    final driverLoc = ref.watch(driverLocationProvider);
    ref.listen<DriverLocation?>(driverLocationProvider, (_, next) {
      _onDriverLocationUpdate(next);
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.friendlyApiError(e))),
        data: (trip) {
          if (trip == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                child: Text(context.l10n.backToHome),
              ),
            );
          }
          if (trip.status == TripStatus.searching) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/searching');
            });
            return const Center(child: CircularProgressIndicator());
          }

          _chatPoller.track(trip.driver != null ? trip.id : null);
          final passengerLoc = ref.watch(passengerLiveLocationProvider);
          final passengerLat = passengerLoc?.lat ?? trip.pickupLat;
          final passengerLng = passengerLoc?.lng ?? trip.pickupLng;
          final driverLat = driverLoc?.lat ?? _lastDriverLat;
          final driverLng = driverLoc?.lng ?? _lastDriverLng;
          final driverHeading = driverLoc?.heading;
          final vehicleKind = VehicleKind.fromIconName(trip.rideTypeIconName);
          final driverArrived = trip.status == TripStatus.driverArriving ||
              trip.driverArrivedAt != null;

          final tripStarted = trip.status == TripStatus.tripStarted;
          final driverConfirmed = trip.status == TripStatus.accepted ||
              trip.status == TripStatus.driverArriving;

          final markers = buildTripLiveMarkers(
            passengerLat: passengerLat,
            passengerLng: passengerLng,
            driverLat: driverLat,
            driverLng: driverLng,
            pickupLat: trip.pickupLat,
            pickupLng: trip.pickupLng,
            dropoffLat: trip.dropoffLat,
            dropoffLng: trip.dropoffLng,
            passengerLabel: context.l10n.you,
            driverLabel: context.l10n.yourDriver,
            showPickup: trip.pickupLat != null && trip.pickupLng != null,
            showDropoff: true,
            passengerIsCurrentUser: true,
            driverHeading: driverHeading,
            vehicleKind: vehicleKind,
            l10n: context.l10n,
          );

          final route = resolveTripRouteEndpoints(
            status: trip.status,
            driverLat: driverLat,
            driverLng: driverLng,
            pickupLat: trip.pickupLat,
            pickupLng: trip.pickupLng,
            dropoffLat: trip.dropoffLat,
            dropoffLng: trip.dropoffLng,
          );
          final mapRoute = route;
          final navFollowIcon = vehicleKind.mapIcon;

          final centerLat = driverLat ?? passengerLat ?? trip.pickupLat;
          final centerLng = driverLng ?? passengerLng ?? trip.pickupLng;
          final driver = trip.driver;
          final canCancel =
              trip.status == TripStatus.accepted ||
              trip.status == TripStatus.driverArriving ||
              trip.status == TripStatus.searching;
          final status = _statusInfo(trip.status, context.l10n);
          final displayEta = _etaMinutes ?? trip.durationMinutes;

          if (_lastTripStatus != trip.status) {
            _lastTripStatus = trip.status;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _routeRefitToken++);
            });
          }

          final topInset = MediaQuery.paddingOf(context).top;
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          final mapPadding = EdgeInsets.only(
            top: topInset + (driverConfirmed ? 150 : 70),
            bottom: _sheetHeight + bottomInset + 16,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              if (mapRoute != null)
                Positioned.fill(
                  child: TripRouteMap(
                    key: ValueKey('route_${trip.id}'),
                    refitToken: _routeRefitToken,
                    navigationMode: false,
                    navigationFollowIcon: navFollowIcon,
                    followHeading: driverHeading,
                    mapsService: ref.read(mapsServiceProvider),
                    originLat: mapRoute.originLat,
                    originLng: mapRoute.originLng,
                    destLat: mapRoute.destLat,
                    destLng: mapRoute.destLng,
                    zoom: 15,
                    markers: markers,
                    showRouteSelector: true,
                    fitRouteBounds: true,
                    routeSelectorBottomInset: _sheetHeight + bottomInset + 28,
                    mapPadding: mapPadding,
                    myLocationEnabled: true,
                    refreshOriginAfterMeters: tripStarted ? 80 : 50,
                    onGuidanceChanged: (g) {
                      if (!mounted) return;
                      setState(() {
                        _etaMinutes = g.remainingMinutes;
                        _distanceKm = g.remainingDistanceKm;
                      });
                    },
                    onRouteLoaded: (r) {
                      if (!mounted) return;
                      setState(() {
                        _etaMinutes = r.durationMinutes;
                        _distanceKm = r.distanceKm;
                      });
                    },
                  ),
                )
              else
                Positioned.fill(
                  child: RawanaMap(
                    zoom: 15,
                    centerLat: centerLat,
                    centerLng: centerLng,
                    markers: markers,
                    myLocationEnabled: true,
                    mapPadding: mapPadding,
                  ),
                ),
              SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    RawanaSpacing.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: RawanaColors.outline
                                        .withValues(alpha: 0.35),
                                  ),
                                  boxShadow: RawanaShadows.floating,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: status.color
                                            .withValues(alpha: 0.14),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        status.icon,
                                        size: 15,
                                        color: status.color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        status.label,
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
                              ),
                            ),
                            const SizedBox(width: 12),
                            RawanaCircleIconButton(
                              icon: LucideIcons.shieldAlert,
                              iconColor: RawanaColors.error,
                              onPressed: () => _sendSos(trip),
                              tooltip: context.l10n.sos,
                            ),
                          ],
                        ),
                        if (driverConfirmed) ...[
                          const SizedBox(height: 10),
                          _PickupSpotBanner(address: trip.pickupAddress),
                        ],
                      ],
                    ),
                  ),
                ),
              if (!tripStarted && driverArrived)
                const Positioned(
                  left: 16,
                  right: 16,
                  top: 130,
                  child: SafeArea(child: _DriverArrivedNotice()),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: MeasureSize(
                    onChange: (size) {
                      if (!mounted || (size.height - _sheetHeight).abs() < 1) return;
                      setState(() => _sheetHeight = size.height);
                    },
                    child: TripInfoSheet(
                    statusLabel: status.label,
                    statusColor: status.color,
                    statusIcon: status.icon,
                    etaMinutes: displayEta,
                    distanceKm: _distanceKm,
                    partyName: driver?.name ?? context.l10n.yourDriver,
                    partySubtitle: _driverSubtitle(driver),
                    plateNumber: driver?.plateNumber,
                    vehicleColour: driver?.vehicleColour,
                    profilePhotoUrl: driver?.profilePhotoUrl,
                    partyPhone: _driverPhone,
                    rating: driver?.ratingAverage,
                    pickupAddress: trip.pickupAddress,
                    dropoffAddress: trip.dropoffAddress,
                    currentLabel: tripStarted
                        ? context.l10n.driverLiveLocation
                        : context.l10n.yourPickupSpot,
                    fareFormatted: formatTripFare(trip.cashToCollect),
                    fareLabel: context.l10n.cashFare,
                    hintText: [
                      if (freeCancelSecondsRemaining(trip, _policy, _policyFetchedAt) > 0)
                        context.l10n.cancelWithoutFeeIn(
                          '${freeCancelSecondsRemaining(trip, _policy, _policyFetchedAt)}s',
                        ),
                      if (tripStarted)
                        context.l10n.hintFollowLiveRoute
                      else if (driverArrived)
                        context.l10n.driverArrivedNotice
                      else
                        context.l10n.hintWatchDriverApproach,
                    ].join('\n'),
                    onCall: driver != null
                        ? () => _contactDriver(trip.id, call: true)
                        : null,
                    callLabel: context.l10n.call,
                    onChat: driver != null ? () => _openChat(trip) : null,
                    chatUnread: _chatUnread,
                    onWhatsApp: driver != null
                        ? () => _contactDriver(trip.id, call: false)
                        : null,
                    onShare: () => _shareTrip(trip, driverLat, driverLng),
                    shareLabel: context.l10n.shareTrip,
                    onCancel: canCancel && !_cancelling
                        ? () => _cancelTrip(trip.id)
                        : null,
                    cancelLoading: _cancelling,
                    onExpandedChanged: (_) {
                      // Re-fit once the new sheet height reaches the map padding.
                      Future<void>.delayed(const Duration(milliseconds: 260), () {
                        if (mounted) setState(() => _routeRefitToken++);
                      });
                    },
                  ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PickupSpotBanner extends StatelessWidget {
  const _PickupSpotBanner({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return RawanaSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      gradient: const LinearGradient(
        colors: [RawanaColors.primary, Color(0xFF1E40AF)],
      ),
      shadows: RawanaShadows.floating,
      child: Row(
        children: [
          const Icon(LucideIcons.mapPin, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.yourPickupSpot,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverArrivedNotice extends StatelessWidget {
  const _DriverArrivedNotice();

  @override
  Widget build(BuildContext context) {
    return RawanaSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      gradient: const LinearGradient(
        colors: [RawanaColors.success, Color(0xFF22C55E)],
      ),
      shadows: RawanaShadows.floating,
      child: Row(
        children: [
          const Icon(LucideIcons.mapPinCheck, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.driverArrivedNotice,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
