import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';
import 'live_location_providers.dart';
import 'trip_providers.dart';
import 'auth_provider.dart';

typedef MapPickupCenter = ({double lat, double lng, String? rideTypeId});

/// Home-screen pickup point (set when GPS resolves).
final homeMapPickupProvider = StateProvider<MapPickupCenter?>((ref) => null);

/// Pickup point from the active booking draft + live passenger GPS.
final bookingMapPickupProvider = Provider<MapPickupCenter?>((ref) {
  final draft = ref.watch(bookingDraftProvider);
  if (draft == null) return null;
  final loc = ref.watch(passengerLiveLocationProvider);
  return (
    lat: loc?.lat ?? draft.pickupLat,
    lng: loc?.lng ?? draft.pickupLng,
    rideTypeId: draft.rideTypeId,
  );
});

/// Pickup point used to load nearby driver markers on the map.
final mapPickupCenterProvider = Provider<MapPickupCenter?>((ref) {
  if (!ref.watch(isAppLoggedInProvider)) return null;

  final trip = ref.watch(activeTripProvider).valueOrNull;
  final matched =
      trip != null &&
      trip.status != TripStatus.searching &&
      trip.status != TripStatus.cancelled;
  if (matched) return null;

  final booking = ref.watch(bookingMapPickupProvider);
  if (booking != null) return booking;

  return ref.watch(homeMapPickupProvider);
});

/// Online drivers near the current pickup point (refreshed while booking).
final nearbyDriversProvider =
    StateNotifierProvider<NearbyDriversNotifier, List<NearbyDriver>>((ref) {
      return NearbyDriversNotifier(ref);
    });

class NearbyDriversNotifier extends StateNotifier<List<NearbyDriver>> {
  NearbyDriversNotifier(this._ref) : super([]) {
    _ref.listen<MapPickupCenter?>(mapPickupCenterProvider, (prev, next) {
      Future.microtask(() {
        if (!mounted) return;
        if (next == null) {
          _stop();
          if (mounted) state = [];
          return;
        }
        if (prev?.lat == next.lat &&
            prev?.lng == next.lng &&
            prev?.rideTypeId == next.rideTypeId) {
          return;
        }
        _start(next);
      });
    }, fireImmediately: true);
  }

  final Ref _ref;
  Timer? _timer;
  MapPickupCenter? _center;

  void _start(MapPickupCenter center) {
    _center = center;
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _center = null;
  }

  Future<void> refresh() async {
    final center = _center;
    if (center == null) return;
    try {
      final drivers = await _ref
          .read(passengerServiceProvider)
          .getNearbyDrivers(
            lat: center.lat,
            lng: center.lng,
            rideTypeId: center.rideTypeId,
          );
      if (mounted && _center == center) state = drivers;
    } catch (_) {
      // Keep the last known nearby drivers so a poll error does not
      // empty the map or invite dummy pins.
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
