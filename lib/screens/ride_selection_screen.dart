import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';
import '../widgets/schedule_pickup_sheet.dart';

IconData rideTypeIcon(String iconName) => switch (iconName) {
  'bike' => LucideIcons.bike,
  'premium' => LucideIcons.carFront,
  'xl' => LucideIcons.truck,
  _ => LucideIcons.car,
};

class RideSelectionScreen extends ConsumerStatefulWidget {
  const RideSelectionScreen({super.key});

  @override
  ConsumerState<RideSelectionScreen> createState() =>
      _RideSelectionScreenState();
}

class _RideSelectionScreenState extends ConsumerState<RideSelectionScreen> {
  int _selected = 0;
  final Map<String, FareEstimate> _fares = {};
  bool _loadingFare = false;
  bool _confirming = false;
  final _promoController = TextEditingController();
  String? _promoError;
  double _sheetHeight = 380;
  int _fareToken = 0;
  bool _fareFailed = false;

  static const _minTripMeters = 100.0;

  /// Small nudges on the confirm-pickup map keep the quoted price.
  static const _repriceAfterMeters = 150.0;

  bool _isTooShort(TripBookingDraft draft) =>
      const Distance().as(
        LengthUnit.Meter,
        LatLng(draft.pickupLat, draft.pickupLng),
        LatLng(draft.dropoffLat, draft.dropoffLng),
      ) <
      _minTripMeters;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFares());
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
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
    setState(() {
      _fares.clear();
      _fareFailed = false;
      _promoError = null;
      _loadingFare = !_isTooShort(draft);
    });
    if (_isTooShort(draft)) return;
    final promo = _promoController.text.trim();
    final scheduledAt = ref.read(scheduledPickupProvider);
    final results = await Future.wait(
      types.map((type) async {
        try {
          return await ref
              .read(tripServiceProvider)
              .estimateFare(
                draft.copyWith(
                  rideTypeId: type.id,
                  promoCode: promo.isEmpty ? null : promo,
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

  /// Adjust pickup or destination without leaving the ride options, like Uber.
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
        ? draft.copyWith(
            pickupLat: result.lat,
            pickupLng: result.lng,
            pickupAddress: address,
            clearRoute: true,
          )
        : draft.copyWith(
            dropoffLat: result.lat,
            dropoffLng: result.lng,
            dropoffAddress: address,
            clearRoute: true,
          );
    await _loadFares();
  }

  Future<void> _choosePickupTime() async {
    if (_confirming) return;
    final choice = await showPickupTimeSheet(
      context,
      initial: ref.read(scheduledPickupProvider),
    );
    if (choice == null || !mounted) return;
    if (choice.at == ref.read(scheduledPickupProvider)) return;
    ref.read(scheduledPickupProvider.notifier).state = choice.at;
    await _loadFares();
  }

  Future<void> _schedule(TripBookingDraft draft) async {
    final trip = await ref.read(tripServiceProvider).scheduleRide(draft);
    ref.invalidate(scheduledRidesProvider);
    if (!mounted) return;
    final when = formatScheduledTime(context, trip.scheduledAt ?? draft.scheduledAt!);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(LucideIcons.calendarCheck, color: RawanaColors.success, size: 36),
        title: Text(ctx.l10n.rideScheduledTitle),
        content: Text(ctx.l10n.rideScheduledBody(when)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.done)),
        ],
      ),
    );
    if (!mounted) return;
    context.go('/scheduled-rides');
    ref.read(scheduledPickupProvider.notifier).state = null;
    ref.read(bookingDraftProvider.notifier).state = null;
  }

  /// Books only at a price the passenger has seen. If the server's price went
  /// up (e.g. surge), asks once more; returns null when they decline.
  Future<({String tripId, int estimatedFare})?> _requestAtSeenPrice(
    TripBookingDraft draft,
    int seenCash,
  ) async {
    var expected = seenCash;
    while (true) {
      try {
        return await ref
            .read(tripServiceProvider)
            .requestRide(draft, expectedCash: expected);
      } on FareChangedException catch (e) {
        if (!mounted) return null;
        final accept = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(
              LucideIcons.trendingUp,
              color: RawanaColors.warning,
              size: 32,
            ),
            title: Text(ctx.l10n.fareChangedTitle),
            content: Text(
              ctx.l10n.fareChangedBody(
                AfnFormatter.format(e.expectedCash),
                AfnFormatter.format(e.cashToCollect),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  ctx.l10n.requestAtPrice(AfnFormatter.format(e.cashToCollect)),
                ),
              ),
            ],
          ),
        );
        if (accept != true) {
          // Show the current prices so the sheet matches the server again.
          unawaited(_loadFares());
          return null;
        }
        expected = e.cashToCollect;
      }
    }
  }

  /// The passenger tapped a different route on the map: re-quote along it.
  void _onRouteChosen(RouteDirections route) {
    final draft = ref.read(bookingDraftProvider);
    if (draft == null || !mounted) return;
    final recommended = route.routes.isEmpty ||
        route.polyline == route.routes.first.polyline;
    final hint = recommended ? null : route.distanceKm;
    final current = draft.routeDistanceKm;
    if (hint == current ||
        (hint != null && current != null && (hint - current).abs() < 0.05)) {
      return;
    }
    ref.read(bookingDraftProvider.notifier).state = hint == null
        ? draft.copyWith(clearRoute: true)
        : draft.copyWith(routeDistanceKm: hint);
    _loadFares();
  }

  Future<void> _confirm(List<RideType> types) async {
    if (_confirming || _loadingFare) return;
    var draft = ref.read(bookingDraftProvider);
    if (draft == null || types.isEmpty || _isTooShort(draft)) return;
    final selectedFare = _fares[types[_selected.clamp(0, types.length - 1)].id];
    if (selectedFare == null || selectedFare.cashToCollect <= 0) return;

    final confirmed = await context.push<PlaceDetails>(
      Uri(
        path: '/map-picker',
        queryParameters: {
          'mode': 'confirm_pickup',
          'lat': draft.pickupLat.toString(),
          'lng': draft.pickupLng.toString(),
        },
      ).toString(),
    );
    if (confirmed == null || !mounted) return;
    final movedMeters = const Distance().as(
      LengthUnit.Meter,
      LatLng(draft.pickupLat, draft.pickupLng),
      LatLng(confirmed.lat, confirmed.lng),
    );
    draft = draft.copyWith(
      pickupLat: confirmed.lat,
      pickupLng: confirmed.lng,
      pickupAddress: confirmed.address.isNotEmpty
          ? confirmed.address
          : draft.pickupAddress,
      clearRoute: movedMeters > _repriceAfterMeters,
    );
    ref.read(bookingDraftProvider.notifier).state = draft;
    if (movedMeters > _repriceAfterMeters || _isTooShort(draft)) {
      // Never book at a price the passenger has not seen.
      if (!_isTooShort(draft)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pickupMovedCheckPrice)),
        );
      }
      await _loadFares();
      return;
    }
    if (!mounted || _confirming) return;
    final type = types[_selected];
    final scheduledAt = ref.read(scheduledPickupProvider);
    setState(() => _confirming = true);
    final updated = draft.copyWith(
      rideTypeId: type.id,
      promoCode: _promoController.text.trim().isEmpty
          ? null
          : _promoController.text.trim(),
      scheduledAt: scheduledAt,
      clearScheduledAt: scheduledAt == null,
    );
    ref.read(bookingDraftProvider.notifier).state = updated;
    try {
      if (scheduledAt != null) {
        await _schedule(updated);
        return;
      }
      final result = await _requestAtSeenPrice(
        updated,
        selectedFare.cashToCollect,
      );
      if (result == null) return;
      ref.read(currentTripIdProvider.notifier).state = result.tripId;
      await ref.read(activeTripProvider.notifier).refresh();
      if (mounted) context.go('/searching');
    } on ActiveTripExistsException catch (e) {
      // The server refused to start a second ride — resume the live one.
      final trip = await ref
          .read(activeTripProvider.notifier)
          .resumeTrip(e.tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.resumingActiveTrip)));
      context.go(
        trip?.status == TripStatus.searching ? '/searching' : '/active-trip',
      );
    } catch (e) {
      if (mounted) {
        final key = apiErrorKey(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              key == 'account_blocked'
                  ? context.l10n.accountBlocked
                  : key == 'too_many_cancellations'
                      ? context.l10n.tooManyCancellations
                      : key == 'trip_too_short'
                      ? context.l10n.tripTooShort
                      : key == 'scheduled_too_soon'
                      ? context.l10n.scheduledTooSoon
                      : key == 'scheduled_too_far'
                      ? context.l10n.scheduledTooFar
                      : key == 'scheduled_limit_reached'
                      ? context.l10n.scheduledLimitReached
                      : key == 'scheduled_overlap'
                      ? context.l10n.scheduledOverlap
                  : key != null && key.startsWith('promo_')
                  ? context.l10n.promoInvalid
                  : apiErrorMessage(e),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bookingDraftProvider);
    if (draft == null) {
      // Nothing to book (e.g. app restored on this route) — start over.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tooShort = _isTooShort(draft);
    final scheduledAt = ref.watch(scheduledPickupProvider);
    final nearbyDrivers = ref.watch(nearbyDriversProvider);
    final typesAsync = ref.watch(rideTypesProvider);
    final liveLoc = ref.watch(passengerLiveLocationProvider);
    final pickupLat = draft.pickupLat;
    final pickupLng = draft.pickupLng;
    final selectedType =
        typesAsync.valueOrNull != null && typesAsync.valueOrNull!.isNotEmpty
        ? typesAsync.valueOrNull![_selected.clamp(
            0,
            typesAsync.valueOrNull!.length - 1,
          )]
        : null;
    final vehicleKind = VehicleKind.fromIconName(selectedType?.iconName);
    final nearbyRatingLabel = nearbyDrivers.isEmpty
        ? null
        : context.l10n.typicalDriverRating(
            (nearbyDrivers
                        .map((d) => d.ratingAverage ?? 5.0)
                        .fold<double>(0, (sum, value) => sum + value) /
                    nearbyDrivers.length)
                .toStringAsFixed(1),
          );
    final markers = withCurrentLocationMarker(
      buildBookingMapMarkers(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffLat: draft.dropoffLat,
        dropoffLng: draft.dropoffLng,
        nearbyDrivers: nearbyDrivers,
        vehicleKind: vehicleKind,
        l10n: context.l10n,
      ),
      lat: liveLoc?.lat ?? pickupLat,
      lng: liveLoc?.lng ?? pickupLng,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RawanaCircleIconButton(
            icon: LucideIcons.arrowLeft,
            onPressed: _leave,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: TripRouteMap(
              key: ValueKey(
                'preview_${pickupLat}_${pickupLng}_${draft.dropoffLat}_${draft.dropoffLng}',
              ),
              mapsService: ref.read(mapsServiceProvider),
              originLat: pickupLat,
              originLng: pickupLng,
              destLat: draft.dropoffLat,
              destLng: draft.dropoffLng,
              zoom: 14,
              markers: markers,
              showRouteSelector: true,
              routeSelectorBottomInset: _sheetHeight + 12,
              onRouteLoaded: _onRouteChosen,
              mapPadding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 56,
                bottom: _sheetHeight,
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
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(RawanaSpacing.radiusXl),
                  ),
                  boxShadow: RawanaShadows.sheet,
                ),
                child: typesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.failedToLoadRideTypes(
                              apiErrorMessage(e),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.invalidate(rideTypesProvider);
                              _loadFares();
                            },
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: Text(context.l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (types) {
                    if (types.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(context.l10n.noRideTypesAvailable),
                      );
                    }
                    if (_selected >= types.length) _selected = 0;
                    final selectedType = types[_selected];
                    final fare = _fares[selectedType.id]?.cashToCollect ?? 0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const RawanaSheetHandle(),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _StopsCard(
                                  pickupAddress: draft.pickupAddress.isEmpty
                                      ? context.l10n.pickup
                                      : draft.pickupAddress,
                                  dropoffAddress: draft.dropoffAddress.isEmpty
                                      ? context.l10n.destination
                                      : draft.dropoffAddress,
                                  onChangePickup: () =>
                                      _changeStop(pickup: true),
                                  onChangeDropoff: () =>
                                      _changeStop(pickup: false),
                                ),
                                if (tooShort || _fareFailed) ...[
                                  const SizedBox(height: 12),
                                  _InlineNotice(
                                    message: tooShort
                                        ? context.l10n.tripTooShort
                                        : context.l10n.couldNotLoadFares,
                                    actionLabel: tooShort
                                        ? context.l10n.changeLabel
                                        : context.l10n.retry,
                                    onAction: tooShort
                                        ? () => _changeStop(pickup: false)
                                        : _loadFares,
                                  ),
                                ],
                                const SizedBox(height: 10),
                                _PickupTimePill(
                                  scheduledAt: scheduledAt,
                                  onTap: _choosePickupTime,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.l10n.chooseYourRide,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...List.generate(types.length, (i) {
                                  final type = types[i];
                                  final selected = i == _selected;
                                  final typeFare =
                                      _fares[type.id]?.cashToCollect ?? 0;
                                  final eta = _fares[type.id]?.durationMinutes;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => _selected = i),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? RawanaColors.surfaceAlt
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            RawanaSpacing.radiusLg,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? RawanaColors.primary
                                                : RawanaColors.outline
                                                      .withValues(alpha: 0.5),
                                            width: selected ? 2.5 : 1,
                                          ),
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: RawanaColors.primary
                                                        .withValues(
                                                          alpha: 0.14,
                                                        ),
                                                    blurRadius: 16,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ]
                                              : RawanaShadows.low,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? RawanaColors.primary
                                                    : RawanaColors.surfaceAlt,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                rideTypeIcon(type.iconName),
                                                color: selected
                                                    ? Colors.white
                                                    : RawanaColors
                                                          .onSurfaceMuted,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    type.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (eta != null && eta > 0)
                                                    Text(
                                                      context.l10n
                                                          .etaMinToDestination(
                                                            '$eta',
                                                          ),
                                                      style: const TextStyle(
                                                        color: RawanaColors
                                                            .onSurfaceMuted,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _loadingFare && typeFare == 0
                                                      ? '…'
                                                      : AfnFormatter.format(
                                                          typeFare,
                                                        ),
                                                  style: TextStyle(
                                                    color: selected
                                                        ? RawanaColors.primary
                                                        : RawanaColors
                                                              .onSurface,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 18,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                if (selected)
                                                  Text(
                                                    context.l10n.selected,
                                                    style: const TextStyle(
                                                      color:
                                                          RawanaColors.primary,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 4),
                                Text(
                                  context.l10n.payment,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: RawanaColors.successSoft,
                                    borderRadius: BorderRadius.circular(
                                      RawanaSpacing.radiusMd,
                                    ),
                                    border: Border.all(
                                      color: RawanaColors.success,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.banknote,
                                        size: 20,
                                        color: RawanaColors.success,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              context.l10n.cashAfn,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              context.l10n.cashSelectedInfo,
                                              style: const TextStyle(
                                                color: RawanaColors.success,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AfnFormatter.format(fare),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_fares[selectedType.id] != null) ...[
                                  const SizedBox(height: 12),
                                  _FareBreakdownCard(
                                    estimate: _fares[selectedType.id]!,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _PromoField(
                                  controller: _promoController,
                                  error: _promoError,
                                  onApply: () {
                                    setState(() => _promoError = null);
                                    _loadFares();
                                  },
                                ),
                                if (nearbyRatingLabel != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    nearbyRatingLabel,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: RawanaColors.onSurfaceMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: RawanaPrimaryButton(
                              label: _confirming
                                  ? (scheduledAt != null
                                      ? context.l10n.scheduling
                                      : context.l10n.requesting)
                                  : scheduledAt != null
                                  ? context.l10n.scheduleRideWithFare(
                                      selectedType.name,
                                      AfnFormatter.format(fare),
                                    )
                                  : context.l10n.requestRideWithFare(
                                      selectedType.name,
                                      AfnFormatter.format(fare),
                                    ),
                              icon: scheduledAt != null
                                  ? LucideIcons.calendarCheck
                                  : LucideIcons.check,
                              loading: _confirming,
                              onPressed:
                                  _confirming ||
                                      _loadingFare ||
                                      tooShort ||
                                      fare <= 0
                                  ? null
                                  : () => _confirm(types),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Pickup now ▾" / "Fri, Oct 30 · 8:15 AM ▾" — opens the pickup-time picker.
class _PickupTimePill extends StatelessWidget {
  const _PickupTimePill({required this.scheduledAt, required this.onTap});

  final DateTime? scheduledAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheduled = scheduledAt != null;
    final color = scheduled ? RawanaColors.primary : RawanaColors.onSurface;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Material(
        color: scheduled
            ? RawanaColors.primary.withValues(alpha: 0.08)
            : RawanaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  scheduled ? LucideIcons.calendarClock : LucideIcons.clock,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  scheduled
                      ? formatScheduledTime(context, scheduledAt!)
                      : '${context.l10n.pickupTime}: ${context.l10n.pickupNow}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronDown, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pickup and destination rows, each with a "Change" action.
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
    return Container(
      decoration: BoxDecoration(
        color: RawanaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      ),
      child: Column(
        children: [
          _StopRow(
            label: context.l10n.pickupLabel,
            address: pickupAddress,
            color: RawanaColors.pickupPin,
            icon: Icons.trip_origin,
            onChange: onChangePickup,
          ),
          const Divider(height: 1, indent: 44, color: RawanaColors.divider),
          _StopRow(
            label: context.l10n.destinationLabel,
            address: dropoffAddress,
            color: RawanaColors.dropoffPin,
            icon: Icons.place_rounded,
            onChange: onChangeDropoff,
          ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.label,
    required this.address,
    required this.color,
    required this.icon,
    required this.onChange,
  });

  final String label;
  final String address;
  final Color color;
  final IconData icon;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChange,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: RawanaColors.onSurfaceMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onChange,
              child: Text(context.l10n.changeLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _FareBreakdownCard extends StatelessWidget {
  const _FareBreakdownCard({required this.estimate});

  final FareEstimate estimate;

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: RawanaColors.onSurfaceMuted,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final km = estimate.distanceKm.toStringAsFixed(
      estimate.distanceKm >= 10 ? 0 : 1,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: RawanaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
        border: Border.all(color: RawanaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.fareBreakdown,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _row(context.l10n.baseFare, AfnFormatter.format(estimate.baseFare)),
          _row(
            context.l10n.distanceFare(km),
            estimate.farePerKm > 0
                ? AfnFormatter.format(
                    (estimate.farePerKm * estimate.distanceKm).round(),
                  )
                : '—',
          ),
          _row(
            context.l10n.timeFare('${estimate.durationMinutes}'),
            estimate.farePerMin > 0
                ? AfnFormatter.format(
                    (estimate.farePerMin * estimate.durationMinutes).round(),
                  )
                : '—',
          ),
          if (estimate.taxAmount > 0)
            _row(
              context.l10n.taxLabel,
              AfnFormatter.format(estimate.taxAmount),
            ),
          if (estimate.discountAmount > 0)
            _row(
              context.l10n.discount,
              '−${AfnFormatter.format(estimate.discountAmount)}',
            ),
          if (estimate.creditApplied > 0)
            _row(
              context.l10n.creditFromRawana,
              '−${AfnFormatter.format(estimate.creditApplied)}',
            ),
          if (estimate.outstandingFee > 0)
            _row(
              context.l10n.txFeeCollected,
              '+${AfnFormatter.format(estimate.outstandingFee)}',
            ),
          const Divider(height: 16),
          _row(
            context.l10n.totalCash,
            AfnFormatter.format(estimate.cashToCollect),
            bold: true,
          ),
          if (estimate.outstandingFee > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.l10n.outstandingFeeIncluded(
                  AfnFormatter.format(estimate.outstandingFee),
                ),
                style: const TextStyle(
                  color: RawanaColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromoField extends StatelessWidget {
  const _PromoField({
    required this.controller,
    required this.onApply,
    this.error,
  });

  final TextEditingController controller;
  final VoidCallback onApply;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: context.l10n.promoCode,
                  prefixIcon: const Icon(LucideIcons.ticket, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onApply,
              child: Text(context.l10n.applyPromo),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              context.l10n.promoInvalid,
              style: const TextStyle(color: RawanaColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: RawanaColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
        border: Border.all(color: RawanaColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 18,
            color: RawanaColors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
