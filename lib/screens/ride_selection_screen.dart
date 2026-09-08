import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';
import '../providers/live_location_providers.dart';
import '../providers/nearby_drivers_provider.dart';

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
    final types = await ref.read(rideTypesProvider.future);
    if (draft == null || types.isEmpty) return;
    setState(() => _loadingFare = true);
    for (final type in types) {
      try {
        final estimate = await ref
            .read(tripServiceProvider)
            .estimateFare(draft.copyWith(
              rideTypeId: type.id,
              promoCode: _promoController.text.trim().isEmpty
                  ? null
                  : _promoController.text.trim(),
            ));
        _fares[type.id] = estimate;
        if (estimate.promoError != null) _promoError = estimate.promoError;
      } catch (_) {}
    }
    if (mounted) setState(() => _loadingFare = false);
  }

  Future<void> _confirm(List<RideType> types) async {
    if (_confirming || _loadingFare) return;
    final draft = ref.read(bookingDraftProvider);
    if (draft == null || types.isEmpty) return;
    final selectedFare = _fares[types[_selected.clamp(0, types.length - 1)].id];
    if (selectedFare == null || selectedFare.cashToCollect <= 0) return;
    final type = types[_selected];
    setState(() => _confirming = true);
    final updated = draft.copyWith(
      rideTypeId: type.id,
      promoCode: _promoController.text.trim().isEmpty
          ? null
          : _promoController.text.trim(),
    );
    ref.read(bookingDraftProvider.notifier).state = updated;
    try {
      final result = await ref.read(tripServiceProvider).requestRide(updated);
      ref.read(currentTripIdProvider.notifier).state = result.tripId;
      await ref.read(activeTripProvider.notifier).refresh();
      if (mounted) context.go('/searching');
    } on ActiveTripExistsException catch (e) {
      // The server refused to start a second ride — resume the live one.
      final trip = await ref.read(activeTripProvider.notifier).resumeTrip(e.tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.resumingActiveTrip)),
      );
      context.go(trip?.status == TripStatus.searching ? '/searching' : '/active-trip');
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
    final nearbyDrivers = ref.watch(nearbyDriversProvider);
    final typesAsync = ref.watch(rideTypesProvider);
    final liveLoc = ref.watch(passengerLiveLocationProvider);
    final pickupLat = draft?.pickupLat ?? liveLoc?.lat;
    final pickupLng = draft?.pickupLng ?? liveLoc?.lng;
    final hasRoutePreview =
        draft != null && pickupLat != null && pickupLng != null;
    final selectedType = typesAsync.valueOrNull != null &&
            typesAsync.valueOrNull!.isNotEmpty
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
      draft != null && pickupLat != null && pickupLng != null
          ? buildBookingMapMarkers(
              pickupLat: pickupLat,
              pickupLng: pickupLng,
              dropoffLat: draft.dropoffLat,
              dropoffLng: draft.dropoffLng,
              nearbyDrivers: nearbyDrivers,
              vehicleKind: vehicleKind,
              l10n: context.l10n,
            )
          : pickupLat != null && pickupLng != null
          ? buildNearbyDriverMarkers(nearbyDrivers, vehicleKind: vehicleKind)
          : const <RawanaMapMarker>[],
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
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasRoutePreview)
            Positioned.fill(
              child: TripRouteMap(
                mapsService: ref.read(mapsServiceProvider),
                originLat: pickupLat,
                originLng: pickupLng,
                destLat: draft.dropoffLat,
                destLng: draft.dropoffLng,
                zoom: 14,
                markers: markers,
                showRouteSelector: true,
                routeSelectorBottomInset: MediaQuery.sizeOf(context).height * 0.42,
              ),
            )
          else
            Positioned.fill(
              child: RawanaMap(
                zoom: 15,
                centerLat: pickupLat,
                centerLng: pickupLng,
                markers: markers,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
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
                  child: Text(context.l10n.failedToLoadRideTypes('$e')),
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: RawanaColors.successSoft,
                                  borderRadius: BorderRadius.circular(
                                    RawanaSpacing.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: RawanaColors.success
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.mapPinCheck,
                                      color: RawanaColors.success,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.pickupConfirmed,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            draft?.pickupAddress ?? context.l10n.pickup,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color:
                                                  RawanaColors.onSurfaceMuted,
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
                              const SizedBox(height: 12),
                              TripRouteAddresses(
                                pickupAddress: draft?.pickupAddress ?? context.l10n.pickup,
                                dropoffAddress:
                                    draft?.dropoffAddress ?? context.l10n.destination,
                                dense: true,
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
                                    onTap: () => setState(() => _selected = i),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
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
                                                      .withValues(alpha: 0.14),
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
                                                  : RawanaColors.onSurfaceMuted,
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
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (eta != null && eta > 0)
                                                  Text(
                                                    context.l10n.etaMinToDestination('$eta'),
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
                                                      : RawanaColors.onSurface,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              if (selected)
                                                Text(
                                                  context.l10n.selected,
                                                  style: const TextStyle(
                                                    color: RawanaColors.primary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
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
                                _FareBreakdownCard(estimate: _fares[selectedType.id]!),
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
                                ? context.l10n.requesting
                                : context.l10n.requestRideWithFare(
                                    selectedType.name,
                                    AfnFormatter.format(fare),
                                  ),
                            icon: LucideIcons.check,
                            loading: _confirming,
                            onPressed:
                                _confirming || _loadingFare || fare <= 0
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
        ],
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
                ? AfnFormatter.format((estimate.farePerKm * estimate.distanceKm).round())
                : '—',
          ),
          _row(
            context.l10n.timeFare('${estimate.durationMinutes}'),
            estimate.farePerMin > 0
                ? AfnFormatter.format((estimate.farePerMin * estimate.durationMinutes).round())
                : '—',
          ),
          if (estimate.taxAmount > 0)
            _row(context.l10n.taxLabel, AfnFormatter.format(estimate.taxAmount)),
          if (estimate.discountAmount > 0)
            _row(context.l10n.discount, '−${AfnFormatter.format(estimate.discountAmount)}'),
          if (estimate.creditApplied > 0)
            _row(context.l10n.creditFromRawana, '−${AfnFormatter.format(estimate.creditApplied)}'),
          if (estimate.outstandingFee > 0)
            _row(context.l10n.txFeeCollected, '+${AfnFormatter.format(estimate.outstandingFee)}'),
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
                context.l10n.outstandingFeeIncluded(AfnFormatter.format(estimate.outstandingFee)),
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
