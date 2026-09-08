import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';
import 'auth_provider.dart';
import 'nearby_drivers_provider.dart';
import 'trip_providers.dart';

typedef GeoPoint = ({double lat, double lng});

/// Passenger's live GPS — kept running while logged in so the next booking
/// always has a fresh current location after a trip completes.
final passengerLiveLocationProvider =
    StateNotifierProvider<PassengerLiveLocationNotifier, GeoPoint?>((ref) {
  return PassengerLiveLocationNotifier(ref);
});

class PassengerLiveLocationNotifier extends StateNotifier<GeoPoint?> {
  PassengerLiveLocationNotifier(this._ref) : super(null) {
    _ref.listen<bool>(isAppLoggedInProvider, (_, loggedIn) {
      if (loggedIn) {
        _start();
      } else {
        _stop(clearState: true);
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  StreamSubscription? _sub;
  Timer? _timer;

  /// Forces a fresh GPS read (e.g. after trip completion).
  Future<void> refresh() async {
    await _refreshOnce();
  }

  void _start() {
    if (_sub != null) return;
    unawaited(_startTracking());
  }

  Future<void> _startTracking() async {
    final ok = await LocationService.ensurePermission();
    if (!ok || !mounted) return;
    await _refreshOnce();
    if (!mounted || _sub != null) return;
    _sub = LocationService.positionStream(navigation: true).listen(
      (pos) {
        if (mounted) state = (lat: pos.latitude, lng: pos.longitude);
      },
      onError: (Object e) {
        debugPrint('[PassengerLiveLocation] stream error: $e');
      },
    );
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refreshOnce());
  }

  Future<void> _refreshOnce() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      state = pos;
    }
  }

  void _stop({bool clearState = false}) {
    _sub?.cancel();
    _timer?.cancel();
    _sub = null;
    _timer = null;
    if (clearState && mounted) state = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

/// Polls the assigned driver's live location while a trip is active.
final driverLocationProvider =
    StateNotifierProvider<DriverLocationNotifier, DriverLocation?>((ref) {
  return DriverLocationNotifier(ref);
});

class DriverLocationNotifier extends StateNotifier<DriverLocation?> {
  DriverLocationNotifier(this._ref) : super(null) {
    _ref.listen<AsyncValue<Trip?>>(activeTripProvider, (_, next) {
      final trip = next.valueOrNull;
      if (_shouldTrack(trip)) {
        _startPolling();
      } else {
        _stopPolling();
        state = null;
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  Timer? _timer;
  String? _subscribedDriverId;

  bool _shouldTrack(Trip? trip) {
    if (trip == null) return false;
    return trip.driver != null &&
        trip.status != TripStatus.searching &&
        trip.status != TripStatus.cancelled &&
        trip.status != TripStatus.completed;
  }

  void _startPolling() {
    final trip = _ref.read(activeTripProvider).valueOrNull;
    final driverId = trip?.driverId;
    if (driverId != null && driverId != _subscribedDriverId) {
      _subscribedDriverId = driverId;
      _ref.read(tripRealtimeServiceProvider).subscribeToDriverLocation(
        driverId,
        () {
          if (mounted) refresh();
        },
      );
    }
    if (_timer != null) return;
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
    _subscribedDriverId = null;
    _ref.read(tripRealtimeServiceProvider).unsubscribeDriverLocation();
  }

  Future<void> refresh() async {
    try {
      final loc = await _ref.read(passengerServiceProvider).getDriverLocation();
      if (mounted && loc?.lat != null && loc?.lng != null) state = loc;
    } catch (_) {
      // Keep the last known driver position so the map does not go blank.
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

/// Call after a trip ends so home / booking screens pick up the new GPS fix.
void refreshPassengerLocationForNextBooking(Ref ref) {
  ref.read(homeMapPickupProvider.notifier).state = null;
  unawaited(ref.read(passengerLiveLocationProvider.notifier).refresh());
}
