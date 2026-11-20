import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rawana_core/rawana_core.dart';

import '../providers/trip_providers.dart';

/// What the shared booking map is showing; each booking step owns one.
enum BookingScene { home, rideOptions, confirmPickup, searching, trip }

const _distance = Distance();

@immutable
class BookingMapState {
  const BookingMapState({
    this.scene = BookingScene.home,
    this.pickup,
    this.dropoff,
    this.pinTarget,
    this.routes = const [],
    this.polylines = const [],
    this.selectedRoute = 0,
    this.routeLoading = false,
    this.tripStarted = false,
    this.bottomInset = 0,
    this.topInset = 0,
    this.fitRevision = 0,
    this.resetRevision = 0,
    this.recenterRevision = 0,
  });

  final BookingScene scene;
  final LatLng? pickup;
  final LatLng? dropoff;

  /// Camera target when the passenger drags the map to place the pickup.
  final LatLng? pinTarget;
  final List<RouteOption> routes;

  /// Decoded [routes], same order.
  final List<List<LatLng>> polylines;
  final int selectedRoute;
  final bool routeLoading;

  /// Trip scene only: the route runs to the drop-off instead of the pickup.
  final bool tripStarted;

  /// Height covered by the step's bottom sheet; fits happen above it.
  final double bottomInset;
  final double topInset;
  final int fitRevision;
  final int resetRevision;
  final int recenterRevision;

  RouteOption? get route =>
      routes.isEmpty ? null : routes[selectedRoute.clamp(0, routes.length - 1)];

  List<LatLng> get routePoints =>
      polylines.isEmpty ? const [] : polylines[selectedRoute.clamp(0, polylines.length - 1)];

  List<List<LatLng>> get alternativePoints => [
        for (var i = 0; i < polylines.length; i++)
          if (i != selectedRoute) polylines[i],
      ];

  BookingMapState copyWith({
    BookingScene? scene,
    LatLng? pickup,
    LatLng? dropoff,
    LatLng? pinTarget,
    bool clearPickup = false,
    bool clearDropoff = false,
    List<RouteOption>? routes,
    List<List<LatLng>>? polylines,
    int? selectedRoute,
    bool? routeLoading,
    bool? tripStarted,
    double? bottomInset,
    double? topInset,
    int? fitRevision,
    int? resetRevision,
    int? recenterRevision,
  }) {
    return BookingMapState(
      scene: scene ?? this.scene,
      pickup: clearPickup ? null : pickup ?? this.pickup,
      dropoff: clearDropoff ? null : dropoff ?? this.dropoff,
      pinTarget: pinTarget ?? this.pinTarget,
      routes: routes ?? this.routes,
      polylines: polylines ?? this.polylines,
      selectedRoute: selectedRoute ?? this.selectedRoute,
      routeLoading: routeLoading ?? this.routeLoading,
      tripStarted: tripStarted ?? this.tripStarted,
      bottomInset: bottomInset ?? this.bottomInset,
      topInset: topInset ?? this.topInset,
      fitRevision: fitRevision ?? this.fitRevision,
      resetRevision: resetRevision ?? this.resetRevision,
      recenterRevision: recenterRevision ?? this.recenterRevision,
    );
  }
}

final bookingMapProvider =
    StateNotifierProvider<BookingMapNotifier, BookingMapState>((ref) {
  return BookingMapNotifier(ref);
});

/// Live camera target while placing the pickup pin, and whether it is moving.
final bookingPinProvider = StateProvider<LatLng?>((ref) => null);
final bookingPinMovingProvider = StateProvider<bool>((ref) => false);

class BookingMapNotifier extends StateNotifier<BookingMapState> {
  BookingMapNotifier(this._ref) : super(const BookingMapState());

  final Ref _ref;
  final _cache = <String, RouteDirections>{};
  int _routeToken = 0;
  LatLng? _routeOrigin;
  LatLng? _routeDest;

  void setBottomInset(double value) {
    if ((value - state.bottomInset).abs() < 1) return;
    state = state.copyWith(bottomInset: value);
  }

  void setTopInset(double value) {
    if ((value - state.topInset).abs() < 1) return;
    state = state.copyWith(topInset: value);
  }

  void fit() => state = state.copyWith(
        fitRevision: state.fitRevision + 1,
        resetRevision: state.resetRevision + 1,
      );

  void recenter() => state = state.copyWith(
        recenterRevision: state.recenterRevision + 1,
        resetRevision: state.resetRevision + 1,
      );

  void showHome() {
    _clearRouteTracking();
    state = state.copyWith(
      scene: BookingScene.home,
      clearPickup: true,
      clearDropoff: true,
      routes: const [],
      polylines: const [],
      selectedRoute: 0,
      routeLoading: false,
      tripStarted: false,
      topInset: 0,
      recenterRevision: state.recenterRevision + 1,
      resetRevision: state.resetRevision + 1,
    );
  }

  /// Pickup → drop-off with route alternatives (ride options).
  void showRideOptions(LatLng pickup, LatLng dropoff) {
    final sameTrip = state.pickup == pickup && state.dropoff == dropoff && state.routes.isNotEmpty;
    state = state.copyWith(
      scene: BookingScene.rideOptions,
      pickup: pickup,
      dropoff: dropoff,
      tripStarted: false,
      fitRevision: state.fitRevision + 1,
      resetRevision: state.resetRevision + 1,
    );
    if (!sameTrip) unawaited(_loadRoute(pickup, dropoff, keepSelection: false));
  }

  void showConfirmPickup(LatLng at) {
    _ref.read(bookingPinProvider.notifier).state = at;
    state = state.copyWith(
      scene: BookingScene.confirmPickup,
      pinTarget: at,
      recenterRevision: state.recenterRevision + 1,
      resetRevision: state.resetRevision + 1,
    );
  }

  void showSearching(LatLng pickup, {LatLng? dropoff}) {
    _clearRouteTracking();
    state = state.copyWith(
      scene: BookingScene.searching,
      pickup: pickup,
      dropoff: dropoff,
      clearDropoff: dropoff == null,
      routes: const [],
      polylines: const [],
      selectedRoute: 0,
      routeLoading: false,
      topInset: 0,
      fitRevision: state.fitRevision + 1,
      resetRevision: state.resetRevision + 1,
    );
  }

  /// Driver → pickup before the trip starts, driver → drop-off after.
  void showTrip({
    required LatLng pickup,
    required LatLng dropoff,
    required bool started,
    LatLng? driver,
  }) {
    final changed = state.scene != BookingScene.trip ||
        state.tripStarted != started ||
        state.pickup != pickup ||
        state.dropoff != dropoff;
    if (!changed) {
      if (driver != null) updateTripDriver(driver);
      return;
    }
    _clearRouteTracking();
    state = state.copyWith(
      scene: BookingScene.trip,
      pickup: pickup,
      dropoff: dropoff,
      tripStarted: started,
      routes: const [],
      polylines: const [],
      selectedRoute: 0,
      topInset: 0,
      fitRevision: state.fitRevision + 1,
      resetRevision: state.resetRevision + 1,
    );
    final origin = driver ?? (started ? pickup : null);
    if (origin != null) {
      unawaited(_loadRoute(origin, started ? dropoff : pickup, keepSelection: false));
    }
  }

  /// Refreshes the trip route once the driver has moved far enough from where it was drawn.
  void updateTripDriver(LatLng driver) {
    if (state.scene != BookingScene.trip) return;
    final dest = state.tripStarted ? state.dropoff : state.pickup;
    if (dest == null) return;
    final from = _routeOrigin;
    if (from != null && _routeDest == dest && _distance.as(LengthUnit.Meter, from, driver) < 250) {
      return;
    }
    unawaited(_loadRoute(driver, dest, keepSelection: false, silent: true));
  }

  void selectRoute(int index) {
    if (index < 0 || index >= state.routes.length || index == state.selectedRoute) return;
    state = state.copyWith(
      selectedRoute: index,
      fitRevision: state.fitRevision + 1,
      resetRevision: state.resetRevision + 1,
    );
  }

  void _clearRouteTracking() {
    _routeToken++;
    _routeOrigin = null;
    _routeDest = null;
  }

  String _key(LatLng a, LatLng b) =>
      '${a.latitude.toStringAsFixed(4)},${a.longitude.toStringAsFixed(4)}>'
      '${b.latitude.toStringAsFixed(4)},${b.longitude.toStringAsFixed(4)}';

  Future<void> _loadRoute(
    LatLng origin,
    LatLng dest, {
    required bool keepSelection,
    bool silent = false,
  }) async {
    final token = ++_routeToken;
    _routeOrigin = origin;
    _routeDest = dest;
    final key = _key(origin, dest);
    var directions = _cache[key];
    if (directions == null) {
      if (!silent) state = state.copyWith(routeLoading: true);
      try {
        directions = await _ref.read(mapsServiceProvider).getDirections(
              originLat: origin.latitude,
              originLng: origin.longitude,
              destLat: dest.latitude,
              destLng: dest.longitude,
            );
        _cache[key] = directions;
        if (_cache.length > 24) _cache.remove(_cache.keys.first);
      } catch (_) {
        directions = null;
      }
    }
    if (!mounted || token != _routeToken) return;
    final routes = directions == null
        ? <RouteOption>[]
        : directions.routes.isNotEmpty
            ? directions.routes
            : [directions];
    final polylines = <List<LatLng>>[
      for (final r in routes) _decode(r, origin, dest),
    ];
    if (polylines.isEmpty) polylines.add([origin, dest]);
    state = state.copyWith(
      routes: routes,
      polylines: polylines,
      selectedRoute: keepSelection ? state.selectedRoute.clamp(0, polylines.length - 1) : 0,
      routeLoading: false,
      fitRevision: silent ? null : state.fitRevision + 1,
    );
  }

  List<LatLng> _decode(RouteOption route, LatLng origin, LatLng dest) {
    final points = decodePolyline(route.polyline);
    return points.length >= 2 ? points : [origin, dest];
  }
}
