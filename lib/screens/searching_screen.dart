import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

import '../booking/booking_map.dart';
import '../booking/booking_shell.dart';
import '../booking/trip_parts.dart';
import '../providers/trip_providers.dart';

class SearchingScreen extends ConsumerStatefulWidget {
  const SearchingScreen({super.key});

  @override
  ConsumerState<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends ConsumerState<SearchingScreen> {
  /// How long the "driver found" card stays before the live-trip sheet takes over.
  static const _matchedHold = Duration(milliseconds: 1600);

  String? _error;
  bool _userCancelled = false;
  bool _cancelling = false;
  Trip? _matched;
  Timer? _handoff;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncMap();
      _startSearch();
    });
  }

  @override
  void dispose() {
    _handoff?.cancel();
    super.dispose();
  }

  void _syncMap() {
    final draft = ref.read(bookingDraftProvider);
    final trip = ref.read(activeTripProvider).valueOrNull;
    final lat = draft?.pickupLat ?? trip?.pickupLat;
    final lng = draft?.pickupLng ?? trip?.pickupLng;
    if (lat == null || lng == null) return;
    final dLat = draft?.dropoffLat ?? trip?.dropoffLat;
    final dLng = draft?.dropoffLng ?? trip?.dropoffLng;
    ref.read(bookingMapProvider.notifier).showSearching(
          LatLng(lat, lng),
          dropoff: dLat == null || dLng == null ? null : LatLng(dLat, dLng),
        );
  }

  Future<void> _startSearch() async {
    await ref.read(activeTripProvider.notifier).refresh();
    if (!mounted) return;
    final activeTrip = ref.read(activeTripProvider).valueOrNull;
    final tripId = activeTrip?.id ?? ref.read(currentTripIdProvider);
    if (activeTrip != null) {
      ref.read(currentTripIdProvider.notifier).state = activeTrip.id;
      _syncMap();
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
    if (_matched != null) return;
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
    if (trip.driver == null) {
      context.go('/active-trip');
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _matched = trip);
    _handoff = Timer(_matchedHold, () {
      if (mounted) context.go('/active-trip');
    });
  }

  Future<void> _waitForMatch(String tripId) async {
    // The search window is an admin setting and may outlast one polling round,
    // so keep polling until the server moves the trip out of `searching`.
    while (true) {
      await ref.read(activeTripProvider.notifier).pollUntilAccepted(tripId);
      if (!mounted || _userCancelled || _matched != null) return;
      await ref.read(activeTripProvider.notifier).refresh();
      if (!mounted || _userCancelled || _matched != null) return;
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
        await ref.read(tripServiceProvider).cancelRide(current.id, reason: 'Passenger cancelled');
      }
    } catch (e) {
      if (mounted) {
        showRawanaError(context, e);
        setState(() => _cancelling = false);
      }
      return;
    }
    ref.read(activeTripProvider.notifier).tryClearLocalTripState(keepDraft: true);
    if (mounted) {
      setState(() => _cancelling = false);
      context.go('/ride-selection');
    }
  }

  Future<void> _cancel() async {
    if (_cancelling || _matched != null) return;
    final confirmed = await RawanaActionSheet.confirm(
      context,
      title: context.l10n.cancelSearchTitle,
      message: context.l10n.cancelSearchBody,
      confirmLabel: context.l10n.cancelRequest,
      cancelLabel: context.l10n.keepRide,
      destructive: true,
      icon: LucideIcons.circleX,
    );
    if (!confirmed || !mounted) return;
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
        await ref.read(tripServiceProvider).cancelRide(tripId, reason: 'Passenger cancelled');
      }
    } catch (e) {
      if (mounted) showRawanaError(context, e);
      return;
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
    _userCancelled = true;
    ref.read(activeTripProvider.notifier).tryClearLocalTripState();
    if (mounted) context.go('/home');
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
    final rideTypes = ref.watch(rideTypesProvider).valueOrNull ?? const <RideType>[];
    final rideTypeId = draft?.rideTypeId ?? trip?.rideTypeId;
    RideType? type;
    for (final t in rideTypes) {
      if (t.id == rideTypeId) type = t;
    }

    final Widget body;
    if (_matched != null) {
      body = _MatchedBody(key: const ValueKey('matched'), trip: _matched!);
    } else if (_error != null) {
      body = _ErrorBody(
        key: const ValueKey('error'),
        message: _error!,
        busy: _cancelling,
        onRetry: _tryAgain,
        onCancel: _cancel,
      );
    } else {
      body = _SearchingBody(
        key: const ValueKey('searching'),
        rematch: (trip?.rematchCount ?? 0) > 0,
        artKey: type?.artKey ?? trip?.rideArtKey,
        rideName: type?.name ?? trip?.rideTypeName,
        pickupAddress: draft?.pickupAddress ?? trip?.pickupAddress ?? '',
        dropoffAddress: draft?.dropoffAddress ?? trip?.dropoffAddress ?? '',
        fare: trip?.cashToCollect,
        busy: _cancelling,
        onCancel: _cancel,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: MapInsetReporter(
          child: RawanaSheetPanel(
            child: AnimatedSize(
              duration: RawanaMotion.medium,
              curve: RawanaMotion.curve,
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: RawanaMotion.medium,
                switchInCurve: RawanaMotion.curve,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchingBody extends StatelessWidget {
  const _SearchingBody({
    super.key,
    required this.rematch,
    required this.artKey,
    required this.rideName,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.fare,
    required this.busy,
    required this.onCancel,
  });

  final bool rematch;
  final String? artKey;
  final String? rideName;
  final String pickupAddress;
  final String dropoffAddress;
  final int? fare;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rematch ? l10n.findingAnotherDriver : l10n.connectingToDriver, style: context.text.headline),
                  const SizedBox(height: 4),
                  Text(l10n.searchingNearbyHint, style: context.text.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            RideVehicleArt(imageKey: artKey, width: 72),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
          child: const LinearProgressIndicator(
            minHeight: 4,
            color: RawanaColors.primary,
            backgroundColor: RawanaColors.surfaceAlt,
          ),
        ),
        const SizedBox(height: 16),
        if (pickupAddress.isNotEmpty || dropoffAddress.isNotEmpty)
          TripRouteAddresses(pickupAddress: pickupAddress, dropoffAddress: dropoffAddress, dense: true),
        if (fare != null && fare! > 0) ...[
          const Divider(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.banknote, size: 18, color: RawanaColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rideName == null ? l10n.cashLabel : '$rideName · ${l10n.cashLabel}',
                  style: context.text.body,
                ),
              ),
              Text(formatTripFare(fare), style: context.text.price),
            ],
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          onPressed: busy ? null : onCancel,
          style: TextButton.styleFrom(
            foregroundColor: RawanaColors.error,
            minimumSize: const Size.fromHeight(48),
          ),
          child: busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.cancelRequest, style: context.text.button.copyWith(color: RawanaColors.error)),
        ),
        Text(l10n.noCancellationFee, textAlign: TextAlign.center, style: context.text.caption),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    super.key,
    required this.message,
    required this.busy,
    required this.onRetry,
    required this.onCancel,
  });

  final String message;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(LucideIcons.carTaxiFront, size: 36, color: RawanaColors.onSurfaceMuted),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: context.text.headline),
        const SizedBox(height: 4),
        Text(context.l10n.retryOrCancelBelow, textAlign: TextAlign.center, style: context.text.caption),
        const SizedBox(height: 20),
        RawanaPrimaryButton(
          label: context.l10n.tryAgain,
          icon: LucideIcons.refreshCw,
          loading: busy,
          onPressed: busy ? null : onRetry,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onCancel,
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(context.l10n.cancelRequest),
        ),
      ],
    );
  }
}

class _MatchedBody extends StatelessWidget {
  const _MatchedBody({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final eta = trip.pickupEtaMinutes;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(
            label: context.l10n.driverFound,
            color: RawanaColors.success,
            icon: LucideIcons.circleCheck,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          eta != null && eta > 0 ? context.l10n.arrivingIn(eta) : context.l10n.driverOnTheWay,
          style: context.text.headline,
        ),
        const SizedBox(height: 14),
        TripDriverCard(trip: trip),
      ],
    );
  }
}
