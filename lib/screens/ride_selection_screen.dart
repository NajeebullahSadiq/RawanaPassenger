import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

import '../booking/booking_map.dart';
import '../booking/booking_shell.dart';
import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';
import '../providers/trip_providers.dart';
import '../widgets/schedule_pickup_sheet.dart';

const _distance = Distance();

class RideSelectionScreen extends ConsumerStatefulWidget {
  const RideSelectionScreen({super.key});

  @override
  ConsumerState<RideSelectionScreen> createState() => _RideSelectionScreenState();
}

class _RideSelectionScreenState extends ConsumerState<RideSelectionScreen> {
  static const _minTripMeters = 100.0;

  /// Small nudges of the pickup pin keep the quoted price.
  static const _repriceAfterMeters = 150.0;

  /// Height of the stops card at the top, below the status bar.
  static const _topBarHeight = 112.0;

  int _selected = 0;
  final Map<String, FareEstimate> _fares = {};
  bool _loadingFare = false;
  bool _fareFailed = false;
  bool _confirming = false;
  String _promo = '';
  String? _promoError;
  int _fareToken = 0;

  bool _pinMode = false;
  String? _pinAddress;
  LatLng? _pinAddressFor;
  bool _pinGeocoding = false;
  int _geocodeToken = 0;

  bool _isTooShort(TripBookingDraft d) =>
      _distance.as(LengthUnit.Meter, LatLng(d.pickupLat, d.pickupLng), LatLng(d.dropoffLat, d.dropoffLng)) <
      _minTripMeters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showOptionsOnMap();
      _loadFares();
    });
  }

  void _showOptionsOnMap() {
    final draft = ref.read(bookingDraftProvider);
    if (draft == null) return;
    final map = ref.read(bookingMapProvider.notifier);
    map.showRideOptions(LatLng(draft.pickupLat, draft.pickupLng), LatLng(draft.dropoffLat, draft.dropoffLng));
    map.setTopInset(MediaQuery.paddingOf(context).top + _topBarHeight);
  }

  void _back() {
    if (_pinMode) {
      setState(() => _pinMode = false);
      _showOptionsOnMap();
      return;
    }
    context.go('/home');
  }

  Future<void> _loadFares() async {
    final draft = ref.read(bookingDraftProvider);
    final List<RideType> types;
    try {
      types = await ref.read(rideTypesProvider.future);
    } catch (_) {
      return;
    }
    if (!mounted || draft == null || types.isEmpty) return;
    final token = ++_fareToken;
    final tooShort = _isTooShort(draft);
    setState(() {
      _fares.clear();
      _fareFailed = false;
      _promoError = null;
      _loadingFare = !tooShort;
    });
    if (tooShort) return;
    final scheduledAt = ref.read(scheduledPickupProvider);
    final results = await Future.wait(
      types.map((type) async {
        try {
          return await ref.read(tripServiceProvider).estimateFare(
                draft.copyWith(
                  rideTypeId: type.id,
                  promoCode: _promo.isEmpty ? null : _promo,
                  scheduledAt: scheduledAt,
                  clearScheduledAt: scheduledAt == null,
                ),
              );
        } catch (_) {
          return null;
        }
      }),
    );
    // A newer pickup/destination change already started another quote.
    if (!mounted || token != _fareToken) return;
    setState(() {
      for (var i = 0; i < types.length; i++) {
        final estimate = results[i];
        if (estimate == null) continue;
        _fares[types[i].id] = estimate;
        if (estimate.promoError != null) _promoError = estimate.promoError;
      }
      _fareFailed = _fares.isEmpty;
      _loadingFare = false;
    });
  }

  /// Adjust pickup or destination without leaving the ride options.
  Future<void> _changeStop({required bool pickup}) async {
    final draft = ref.read(bookingDraftProvider);
    if (draft == null || _confirming) return;
    final result = await context.push<PlaceDetails>(
      Uri(
        path: '/map-picker',
        queryParameters: {
          'mode': pickup ? 'pickup' : 'dropoff',
          'lat': (pickup ? draft.pickupLat : draft.dropoffLat).toString(),
          'lng': (pickup ? draft.pickupLng : draft.dropoffLng).toString(),
        },
      ).toString(),
    );
    if (result == null || !mounted) return;
    final address = result.address.isNotEmpty
        ? result.address
        : pickup
            ? context.l10n.selectedPickup
            : context.l10n.selectedDestination;
    ref.read(bookingDraftProvider.notifier).state = pickup
        ? draft.copyWith(pickupLat: result.lat, pickupLng: result.lng, pickupAddress: address, clearRoute: true)
        : draft.copyWith(dropoffLat: result.lat, dropoffLng: result.lng, dropoffAddress: address, clearRoute: true);
    _showOptionsOnMap();
    await _loadFares();
  }

  Future<void> _choosePickupTime() async {
    if (_confirming) return;
    final choice = await showPickupTimeSheet(context, initial: ref.read(scheduledPickupProvider));
    if (choice == null || !mounted) return;
    if (choice.at == ref.read(scheduledPickupProvider)) return;
    ref.read(scheduledPickupProvider.notifier).state = choice.at;
    await _loadFares();
  }

  /// The passenger picked another route alternative: re-quote along it.
  void _onRouteChosen(int index) {
    final draft = ref.read(bookingDraftProvider);
    final routes = ref.read(bookingMapProvider).routes;
    if (draft == null || !mounted) return;
    final hint = index <= 0 || index >= routes.length ? null : routes[index].distanceKm;
    final current = draft.routeDistanceKm;
    if (hint == current || (hint != null && current != null && (hint - current).abs() < 0.05)) return;
    ref.read(bookingDraftProvider.notifier).state =
        hint == null ? draft.copyWith(clearRoute: true) : draft.copyWith(routeDistanceKm: hint);
    _loadFares();
  }

  Future<void> _openPromoSheet() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PromoSheet(initial: _promo),
    );
    if (code == null || !mounted || code == _promo) return;
    setState(() => _promo = code);
    await _loadFares();
  }

  void _openFareDetails(FareEstimate estimate, String rideName) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => _FareDetailsSheet(estimate: estimate, rideName: rideName),
    );
  }

  void _showCashInfo() {
    RawanaActionSheet.info(
      context,
      title: context.l10n.cashAfn,
      message: context.l10n.cashSelectedInfo,
      actionLabel: context.l10n.dialogOk,
      icon: LucideIcons.banknote,
      tone: RawanaColors.success,
    );
  }

  // ---- Confirm pickup (inline, same map) ----

  void _enterPinMode(List<RideType> types) {
    if (_confirming || _loadingFare) return;
    final draft = ref.read(bookingDraftProvider);
    if (draft == null || types.isEmpty || _isTooShort(draft)) return;
    final fare = _fares[types[_selected.clamp(0, types.length - 1)].id];
    if (fare == null || fare.cashToCollect <= 0) return;
    HapticFeedback.selectionClick();
    final pickup = LatLng(draft.pickupLat, draft.pickupLng);
    setState(() {
      _pinMode = true;
      _pinAddress = draft.pickupAddress;
      _pinAddressFor = pickup;
    });
    final map = ref.read(bookingMapProvider.notifier);
    map.showConfirmPickup(pickup);
    map.setTopInset(MediaQuery.paddingOf(context).top + 64);
  }

  void _pinToMyLocation() {
    final live = ref.read(passengerLiveLocationProvider);
    if (live == null) return;
    ref.read(bookingMapProvider.notifier).showConfirmPickup(LatLng(live.lat, live.lng));
  }

  Future<void> _geocodePin(LatLng point) async {
    final draft = ref.read(bookingDraftProvider);
    if (draft == null) return;
    // Keep the name the passenger chose when the pin is still on it.
    if (_distance.as(LengthUnit.Meter, point, LatLng(draft.pickupLat, draft.pickupLng)) < 15) {
      setState(() {
        _pinAddress = draft.pickupAddress;
        _pinAddressFor = point;
        _pinGeocoding = false;
      });
      return;
    }
    final token = ++_geocodeToken;
    setState(() => _pinGeocoding = true);
    var address = '';
    try {
      address = (await ref.read(mapsServiceProvider).reverseGeocode(point.latitude, point.longitude)).address;
    } catch (_) {}
    if (!mounted || token != _geocodeToken) return;
    setState(() {
      _pinAddress = address.isNotEmpty ? address : context.l10n.selectedPickup;
      _pinAddressFor = point;
      _pinGeocoding = false;
    });
  }

  Future<void> _confirmPickup(List<RideType> types) async {
    var draft = ref.read(bookingDraftProvider);
    if (draft == null || _confirming || ref.read(bookingPinMovingProvider)) return;
    final type = types[_selected.clamp(0, types.length - 1)];
    final fare = _fares[type.id];
    if (fare == null) return;
    final point = ref.read(bookingPinProvider) ?? LatLng(draft.pickupLat, draft.pickupLng);
    setState(() => _confirming = true);
    if (_pinAddressFor != point) await _geocodePin(point);
    if (!mounted) return;
    final moved = _distance.as(LengthUnit.Meter, LatLng(draft.pickupLat, draft.pickupLng), point);
    draft = draft.copyWith(
      pickupLat: point.latitude,
      pickupLng: point.longitude,
      pickupAddress: (_pinAddress ?? '').isNotEmpty ? _pinAddress : draft.pickupAddress,
      clearRoute: moved > _repriceAfterMeters,
    );
    ref.read(bookingDraftProvider.notifier).state = draft;
    if (moved > _repriceAfterMeters || _isTooShort(draft)) {
      // Never book at a price the passenger has not seen.
      setState(() {
        _confirming = false;
        _pinMode = false;
      });
      _showOptionsOnMap();
      if (!_isTooShort(draft)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.pickupMovedCheckPrice)));
      }
      await _loadFares();
      return;
    }
    await _submit(draft, type, fare);
  }

  Future<void> _submit(TripBookingDraft draft, RideType type, FareEstimate fare) async {
    final scheduledAt = ref.read(scheduledPickupProvider);
    final updated = draft.copyWith(
      rideTypeId: type.id,
      promoCode: _promo.isEmpty ? null : _promo,
      scheduledAt: scheduledAt,
      clearScheduledAt: scheduledAt == null,
    );
    ref.read(bookingDraftProvider.notifier).state = updated;
    try {
      if (scheduledAt != null) {
        await _schedule(updated);
        return;
      }
      final result = await _requestAtSeenPrice(updated, fare.cashToCollect);
      if (result == null) {
        if (mounted) _back();
        return;
      }
      ref.read(currentTripIdProvider.notifier).state = result.tripId;
      await ref.read(activeTripProvider.notifier).refresh();
      if (mounted) context.go('/searching');
    } on ActiveTripExistsException catch (e) {
      // The server refused a second ride — resume the live one.
      final trip = await ref.read(activeTripProvider.notifier).resumeTrip(e.tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.resumingActiveTrip)));
      context.go(trip?.status == TripStatus.searching ? '/searching' : '/active-trip');
    } catch (e) {
      if (!mounted) return;
      _back();
      showRawanaMessage(context, _bookingError(e));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  String _bookingError(Object e) {
    final l10n = context.l10n;
    final key = apiErrorKey(e);
    return switch (key) {
      'account_blocked' => l10n.accountBlocked,
      'too_many_cancellations' => l10n.tooManyCancellations,
      'trip_too_short' => l10n.tripTooShort,
      'scheduled_too_soon' => l10n.scheduledTooSoon,
      'scheduled_too_far' => l10n.scheduledTooFar,
      'scheduled_limit_reached' => l10n.scheduledLimitReached,
      'scheduled_overlap' => l10n.scheduledOverlap,
      final k? when k.startsWith('promo_') => l10n.promoInvalid,
      _ => l10n.friendlyApiError(e),
    };
  }

  Future<void> _schedule(TripBookingDraft draft) async {
    final trip = await ref.read(tripServiceProvider).scheduleRide(draft);
    ref.invalidate(scheduledRidesProvider);
    if (!mounted) return;
    final when = formatScheduledTime(context, trip.scheduledAt ?? draft.scheduledAt!);
    await RawanaActionSheet.info(
      context,
      title: context.l10n.rideScheduledTitle,
      message: context.l10n.rideScheduledBody(when),
      actionLabel: context.l10n.done,
      icon: LucideIcons.calendarCheck,
      tone: RawanaColors.success,
    );
    if (!mounted) return;
    ref.read(scheduledPickupProvider.notifier).state = null;
    ref.read(bookingDraftProvider.notifier).state = null;
    context.go('/scheduled-rides');
  }

  /// Books only at a price the passenger has seen. If the server's price went
  /// up (e.g. surge), asks once more; returns null when they decline.
  Future<({String tripId, int estimatedFare})?> _requestAtSeenPrice(TripBookingDraft draft, int seenCash) async {
    var expected = seenCash;
    while (true) {
      try {
        return await ref.read(tripServiceProvider).requestRide(draft, expectedCash: expected);
      } on FareChangedException catch (e) {
        if (!mounted) return null;
        final accept = await RawanaActionSheet.confirm(
          context,
          title: context.l10n.fareChangedTitle,
          message: context.l10n.fareChangedBody(
            AfnFormatter.format(e.expectedCash),
            AfnFormatter.format(e.cashToCollect),
          ),
          confirmLabel: context.l10n.requestAtPrice(AfnFormatter.format(e.cashToCollect)),
          cancelLabel: context.l10n.cancel,
          icon: LucideIcons.trendingUp,
        );
        if (!accept) {
          unawaited(_loadFares());
          return null;
        }
        expected = e.cashToCollect;
      }
    }
  }

  String? _etaLabel(FareEstimate? f, DateTime? scheduledAt) {
    if (f == null) return null;
    final l10n = context.l10n;
    if (scheduledAt != null) {
      return l10n.arriveAt(l10n.clockTime(scheduledAt.add(Duration(minutes: f.durationMinutes))));
    }
    if (!f.driversAvailable) return l10n.noDriversAvailable;
    final pickupEta = f.pickupEtaMinutes;
    final arrive = l10n.arriveAt(
      l10n.clockTime(DateTime.now().add(Duration(minutes: (pickupEta ?? 0) + f.durationMinutes))),
    );
    return pickupEta == null ? arrive : '${l10n.minAway(math.max(1, pickupEta))} · $arrive';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    if (draft == null) {
      // Nothing to book (e.g. app restored on this route) — start over.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }
    ref.listen<int>(bookingMapProvider.select((m) => m.selectedRoute), (prev, next) {
      if (prev != next) _onRouteChosen(next);
    });
    ref.listen<bool>(bookingPinMovingProvider, (prev, moving) {
      final point = ref.read(bookingPinProvider);
      if (_pinMode && !moving && point != null) _geocodePin(point);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_confirming) _back();
      },
      child: AnimatedSwitcher(
        duration: RawanaMotion.medium,
        child: _pinMode ? _buildPinMode(draft) : _buildOptions(draft),
      ),
    );
  }

  Widget _buildOptions(TripBookingDraft draft) {
    final tooShort = _isTooShort(draft);
    final scheduledAt = ref.watch(scheduledPickupProvider);
    final typesAsync = ref.watch(rideTypesProvider);
    final nearby = ref.watch(nearbyDriversProvider);
    final map = ref.watch(bookingMapProvider);
    final types = typesAsync.valueOrNull ?? const <RideType>[];
    if (_selected >= types.length) _selected = 0;
    final selectedType = types.isEmpty ? null : types[_selected];
    final selectedFare = selectedType == null ? null : _fares[selectedType.id];
    final fare = selectedFare?.cashToCollect ?? 0;
    final media = MediaQuery.of(context);
    final topBarBottom = media.padding.top + _topBarHeight;
    final maxSize = ((media.size.height - topBarBottom) / media.size.height).clamp(0.5, 0.92);

    int? fastestIndex;
    var etaCount = 0;
    for (var i = 0; i < types.length; i++) {
      final eta = _fares[types[i].id]?.pickupEtaMinutes;
      if (eta == null) continue;
      etaCount++;
      final best = fastestIndex == null ? null : _fares[types[fastestIndex].id]?.pickupEtaMinutes;
      if (best == null || eta < best) fastestIndex = i;
    }
    if (etaCount < 2 || scheduledAt != null) fastestIndex = null;

    final nearbyRating = nearby.isEmpty
        ? null
        : context.l10n.typicalDriverRating(
            (nearby.map((d) => d.ratingAverage ?? 5.0).fold<double>(0, (s, v) => s + v) / nearby.length)
                .toStringAsFixed(1),
          );

    return Stack(
      key: const ValueKey('options'),
      children: [
        Positioned.fill(
          child: RawanaMapSheet(
            snapSizes: [0.46, maxSize],
            onSettledHeight: (h) => ref.read(bookingMapProvider.notifier).setBottomInset(h),
            footer: _OptionsFooter(
              promo: _promo,
              promoError: _promoError,
              onCash: _showCashInfo,
              onPromo: _openPromoSheet,
              onFareInfo: selectedFare == null || selectedType == null
                  ? null
                  : () => _openFareDetails(selectedFare, selectedType.name),
              button: RawanaPrimaryButton(
                label: selectedType == null
                    ? context.l10n.chooseARide
                    : scheduledAt != null
                        ? context.l10n.scheduleRideWithFare(selectedType.name, AfnFormatter.format(fare))
                        : context.l10n.chooseRideType(selectedType.name),
                icon: scheduledAt != null ? LucideIcons.calendarCheck : null,
                loading: _confirming,
                onPressed: _confirming || _loadingFare || tooShort || fare <= 0 || selectedType == null
                    ? null
                    : () => _enterPinMode(types),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(context.l10n.chooseARide, style: context.text.headline)),
                    _PickupTimePill(scheduledAt: scheduledAt, onTap: _choosePickupTime),
                  ],
                ),
                if (map.routes.length > 1) ...[
                  const SizedBox(height: 12),
                  _RouteChips(
                    routes: map.routes,
                    selected: map.selectedRoute,
                    onSelect: (i) => ref.read(bookingMapProvider.notifier).selectRoute(i),
                  ),
                ],
                if (tooShort || _fareFailed) ...[
                  const SizedBox(height: 12),
                  _InlineNotice(
                    message: tooShort ? context.l10n.tripTooShort : context.l10n.couldNotLoadFares,
                    actionLabel: tooShort ? context.l10n.changeLabel : context.l10n.retry,
                    onAction: tooShort ? () => _changeStop(pickup: false) : _loadFares,
                  ),
                ],
                const SizedBox(height: 8),
                ...typesAsync.when(
                  loading: () => const [RideOptionTileSkeleton(), RideOptionTileSkeleton(), RideOptionTileSkeleton()],
                  error: (e, _) => [
                    RawanaErrorState(
                      title: context.l10n.friendlyApiError(e),
                      retryLabel: context.l10n.retry,
                      onRetry: () {
                        ref.invalidate(rideTypesProvider);
                        _loadFares();
                      },
                      compact: true,
                    ),
                  ],
                  data: (types) => types.isEmpty
                      ? [
                          RawanaErrorState(
                            title: context.l10n.noRideTypesAvailable,
                            icon: LucideIcons.carTaxiFront,
                            compact: true,
                          ),
                        ]
                      : [
                          for (var i = 0; i < types.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _tile(types[i], i, scheduledAt, i == fastestIndex),
                            ),
                        ],
                ),
                if (nearbyRating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.star, size: 14, color: RawanaColors.warning),
                      const SizedBox(width: 6),
                      Text(nearbyRating, style: context.text.caption),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(context.l10n.fareEstimateNote, textAlign: TextAlign.center, style: context.text.caption),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RawanaCircleIconButton(
                    icon: LucideIcons.arrowLeft,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: _back,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StopsCard(
                      pickupAddress: draft.pickupAddress.isEmpty ? context.l10n.pickup : draft.pickupAddress,
                      dropoffAddress: draft.dropoffAddress.isEmpty ? context.l10n.destination : draft.dropoffAddress,
                      onChangePickup: () => _changeStop(pickup: true),
                      onChangeDropoff: () => _changeStop(pickup: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(RideType type, int index, DateTime? scheduledAt, bool fastest) {
    final f = _fares[type.id];
    final discounted = f != null && f.discountAmount > 0;
    return RideOptionTile(
      imageKey: type.artKey,
      name: type.name,
      seats: type.seats,
      etaLabel: _etaLabel(f, scheduledAt),
      description: type.description,
      price: f == null ? (_loadingFare ? null : '—') : AfnFormatter.format(f.cashToCollect),
      originalPrice: discounted ? AfnFormatter.format(f.cashToCollect + f.discountAmount) : null,
      badge: fastest ? context.l10n.fastestBadge : null,
      priceLoading: _loadingFare && f == null,
      selected: index == _selected,
      onTap: () {
        if (index == _selected) return;
        HapticFeedback.selectionClick();
        setState(() => _selected = index);
      },
    );
  }

  Widget _buildPinMode(TripBookingDraft draft) {
    final map = ref.watch(bookingMapProvider);
    final moving = ref.watch(bookingPinMovingProvider);
    final live = ref.watch(passengerLiveLocationProvider);
    final types = ref.watch(rideTypesProvider).valueOrNull ?? const <RideType>[];
    final busy = moving || _pinGeocoding;
    return Stack(
      key: const ValueKey('pin'),
      children: [
        Positioned(
          top: map.topInset,
          bottom: map.bottomInset,
          left: 0,
          right: 0,
          child: IgnorePointer(child: Center(child: RawanaCenterPin(lifted: moving))),
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RawanaCircleIconButton(
                icon: LucideIcons.arrowLeft,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _confirming ? null : _back,
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
                if (live != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16, bottom: 12),
                    child: RawanaCircleIconButton(
                      icon: LucideIcons.locateFixed,
                      tooltip: context.l10n.useCurrentLocation,
                      onPressed: _pinToMyLocation,
                    ),
                  ),
                RawanaSheetPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(context.l10n.confirmPickupSpot, style: context.text.headline),
                      const SizedBox(height: 4),
                      Text(context.l10n.confirmPickupDragHint, style: context.text.caption),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: RawanaColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 18, color: RawanaColors.pickupPin),
                            const SizedBox(width: 12),
                            Expanded(
                              child: busy
                                  ? const Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: RawanaSkeleton(width: 180, height: 14),
                                    )
                                  : Text(
                                      _pinAddress ?? draft.pickupAddress,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodyStrong,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      RawanaPrimaryButton(
                        label: context.l10n.confirmPickup,
                        loading: _confirming,
                        onPressed: busy || _confirming || types.isEmpty ? null : () => _confirmPickup(types),
                      ),
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

/// Pickup and destination on one card at the top; each line opens the map picker.
class _StopsCard extends StatelessWidget {
  const _StopsCard({
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.onChangePickup,
    required this.onChangeDropoff,
  });

  final String pickupAddress;
  final String dropoffAddress;
  final VoidCallback onChangePickup;
  final VoidCallback onChangeDropoff;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
          boxShadow: RawanaShadows.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StopLine(address: pickupAddress, dropoff: false, onTap: onChangePickup),
            const Divider(height: 1, indent: 40, color: RawanaColors.divider),
            _StopLine(address: dropoffAddress, dropoff: true, onTap: onChangeDropoff),
          ],
        ),
      ),
    );
  }
}

class _StopLine extends StatelessWidget {
  const _StopLine({required this.address, required this.dropoff, required this.onTap});

  final String address;
  final bool dropoff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = dropoff ? RawanaColors.dropoffPin : RawanaColors.pickupPin;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dropoff ? color : null,
                shape: dropoff ? BoxShape.rectangle : BoxShape.circle,
                border: dropoff ? null : Border.all(color: color, width: 3),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyStrong),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 12, start: 8),
              child: Icon(LucideIcons.pencil, size: 14, color: RawanaColors.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Now ▾" / "Fri 8:15 AM ▾" — opens the pickup-time picker.
class _PickupTimePill extends StatelessWidget {
  const _PickupTimePill({required this.scheduledAt, required this.onTap});

  final DateTime? scheduledAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheduled = scheduledAt != null;
    final color = scheduled ? RawanaColors.primary : RawanaColors.onSurface;
    return Material(
      color: scheduled ? RawanaColors.primary.withValues(alpha: 0.08) : RawanaColors.surfaceAlt,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(scheduled ? LucideIcons.calendarClock : LucideIcons.clock, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                scheduled ? formatScheduledTime(context, scheduledAt!) : context.l10n.pickupNow,
                style: context.text.label.copyWith(color: color),
              ),
              const SizedBox(width: 2),
              Icon(LucideIcons.chevronDown, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteChips extends StatelessWidget {
  const _RouteChips({required this.routes, required this.selected, required this.onSelect});

  final List<RouteOption> routes;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: routes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final r = routes[i];
          final km = r.distanceKm.toStringAsFixed(r.distanceKm >= 10 ? 0 : 1);
          return ChoiceChip(
            selected: i == selected,
            onSelected: (_) => onSelect(i),
            avatar: Icon(LucideIcons.route, size: 14, color: i == selected ? Colors.white : RawanaColors.onSurfaceMuted),
            label: Text('${r.durationMinutes} min · $km km'),
            labelStyle: context.text.label.copyWith(color: i == selected ? Colors.white : RawanaColors.onSurface),
            selectedColor: RawanaColors.primary,
            backgroundColor: RawanaColors.surfaceAlt,
            showCheckmark: false,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill)),
          );
        },
      ),
    );
  }
}

class _OptionsFooter extends StatelessWidget {
  const _OptionsFooter({
    required this.promo,
    required this.promoError,
    required this.onCash,
    required this.onPromo,
    required this.onFareInfo,
    required this.button,
  });

  final String promo;
  final String? promoError;
  final VoidCallback onCash;
  final VoidCallback onPromo;
  final VoidCallback? onFareInfo;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final hasPromo = promo.isNotEmpty && promoError == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            _FooterChip(
              icon: LucideIcons.banknote,
              label: context.l10n.cashLabel,
              color: RawanaColors.success,
              onTap: onCash,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _FooterChip(
                icon: hasPromo ? LucideIcons.circleCheck : LucideIcons.ticket,
                label: hasPromo ? context.l10n.promoAppliedChip(promo) : context.l10n.addPromoCode,
                color: hasPromo ? RawanaColors.primary : RawanaColors.onSurface,
                onTap: onPromo,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onFareInfo,
              tooltip: context.l10n.fareDetails,
              icon: const Icon(LucideIcons.info, size: 20),
              color: RawanaColors.onSurfaceMuted,
            ),
          ],
        ),
        if (promoError != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
            child: Text(context.l10n.promoInvalid, style: context.text.caption.copyWith(color: RawanaColors.error)),
          ),
        const SizedBox(height: 8),
        button,
      ],
    );
  }
}

class _FooterChip extends StatelessWidget {
  const _FooterChip({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyStrong.copyWith(color: color == RawanaColors.success ? null : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoSheet extends StatefulWidget {
  const _PromoSheet({required this.initial});

  final String initial;

  @override
  State<_PromoSheet> createState() => _PromoSheetState();
}

class _PromoSheetState extends State<_PromoSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() => Navigator.pop(context, _controller.text.trim().toUpperCase());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RawanaGrabber(),
              Text(context.l10n.promoCode, style: context.text.headline),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _apply(),
                decoration: InputDecoration(
                  hintText: context.l10n.promoCode,
                  prefixIcon: const Icon(LucideIcons.ticket, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              RawanaPrimaryButton(label: context.l10n.applyPromo, onPressed: _apply),
              if (widget.initial.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: Text(context.l10n.removePromo),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FareDetailsSheet extends StatelessWidget {
  const _FareDetailsSheet({required this.estimate, required this.rideName});

  final FareEstimate estimate;
  final String rideName;

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    final style = bold ? context.text.title : context.text.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? style : style.copyWith(color: RawanaColors.onSurfaceMuted))),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final e = estimate;
    final km = e.distanceKm.toStringAsFixed(e.distanceKm >= 10 ? 0 : 1);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const RawanaGrabber(),
            Text(rideName, style: context.text.headline),
            const SizedBox(height: 4),
            Text(l10n.fareEstimateNote, style: context.text.caption),
            const SizedBox(height: 12),
            _row(context, l10n.baseFare, AfnFormatter.format(e.baseFare)),
            _row(
              context,
              l10n.distanceFare(km),
              e.farePerKm > 0 ? AfnFormatter.format((e.farePerKm * e.distanceKm).round()) : '—',
            ),
            _row(
              context,
              l10n.timeFare('${e.durationMinutes}'),
              e.farePerMin > 0 ? AfnFormatter.format((e.farePerMin * e.durationMinutes).round()) : '—',
            ),
            if (e.taxAmount > 0) _row(context, l10n.taxLabel, AfnFormatter.format(e.taxAmount)),
            if (e.discountAmount > 0) _row(context, l10n.discount, '−${AfnFormatter.format(e.discountAmount)}'),
            if (e.creditApplied > 0) _row(context, l10n.creditFromRawana, '−${AfnFormatter.format(e.creditApplied)}'),
            if (e.outstandingFee > 0) _row(context, l10n.txFeeCollected, '+${AfnFormatter.format(e.outstandingFee)}'),
            const Divider(height: 20),
            _row(context, l10n.totalCash, AfnFormatter.format(e.cashToCollect), bold: true),
            if (e.outstandingFee > 0)
              Text(
                l10n.outstandingFeeIncluded(AfnFormatter.format(e.outstandingFee)),
                style: context.text.caption.copyWith(color: RawanaColors.warning),
              ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l10n.closeLabel)),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, required this.actionLabel, required this.onAction});

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: RawanaColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.triangleAlert, size: 18, color: RawanaColors.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: context.text.bodyStrong)),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
