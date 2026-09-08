import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../services/maps_service.dart';
import '../theme/rawana_theme.dart';
import '../utils/navigation_guidance.dart';
import '../utils/polyline_decoder.dart';
import 'ltr_map_surface.dart';
import 'map_recenter_button.dart';
import 'rawana_map.dart';
import 'web_native_route_map.dart';

const _distance = Distance();

/// Map with route polyline loaded from the directions API.
class TripRouteMap extends StatefulWidget {
  const TripRouteMap({
    super.key,
    required this.mapsService,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    this.zoom = 14,
    this.markers = const [],
    this.myLocationEnabled = false,
    this.fitRouteBounds = true,
    this.refreshOriginAfterMeters = 200,
    this.showRouteSelector = false,
    this.onRouteLoaded,
    this.onGuidanceChanged,
    this.refitToken = 0,
    this.navigationMode = false,
    this.navigationFollowIcon = Icons.local_taxi,
    this.routeSelectorBottomInset = 220,
    this.followHeading,
  });

  final MapsService mapsService;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final double zoom;
  final List<RawanaMapMarker> markers;
  final bool myLocationEnabled;
  final bool fitRouteBounds;
  final double refreshOriginAfterMeters;
  final bool showRouteSelector;
  final ValueChanged<RouteDirections>? onRouteLoaded;
  final ValueChanged<NavigationGuidance>? onGuidanceChanged;
  /// Increment from parent to re-center the map (web "navigate" button).
  final int refitToken;
  /// Google Maps-style in-app navigation: camera follows the live vehicle.
  final bool navigationMode;
  /// Marker icon to follow during [navigationMode] if no followTarget is set.
  final IconData navigationFollowIcon;
  /// Space above the bottom trip sheet for route alternative chips.
  final double routeSelectorBottomInset;
  final double? followHeading;

  @override
  State<TripRouteMap> createState() => TripRouteMapState();
}

class TripRouteMapState extends State<TripRouteMap> {
  /// Fits the camera to the current route (status changes, first load).
  void refitRoute() {
    if (!mounted) return;
    setState(() => _fitRouteRevision++);
  }

  /// Zooms in on the live Driver or Passenger instead of the whole route.
  void recenterOnCurrentLocation() {
    if (!mounted) return;
    setState(() => _recenterRevision++);
  }

  List<LatLng> _polyline = [];
  List<LatLng> _remainingPolyline = [];
  List<LatLng> _traveledPolyline = [];
  String _encodedPolyline = '';
  List<RouteOption> _routes = [];
  List<RouteStep> _steps = [];
  int _selectedRouteIndex = 0;
  bool _loading = true;
  bool _pendingRouteReload = false;
  double? _loadedOriginLat;
  double? _loadedOriginLng;
  double? _loadedDestLat;
  double? _loadedDestLng;
  int _fitRouteRevision = 0;
  int _recenterRevision = 0;
  int _lastMarkerHash = 0;
  int _webNavEpoch = 0;
  late final String _mapSessionId;
  NavigationGuidance? _guidance;
  bool _rerouting = false;
  int _routeLoadToken = 0;
  DateTime? _lastRerouteAt;

  @override
  void initState() {
    super.initState();
    _mapSessionId = '${hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    _lastMarkerHash = _markerHash(widget.markers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadRoute(force: true);
    });
  }

  @override
  void didUpdateWidget(TripRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refitToken != widget.refitToken) {
      refitRoute();
    }

    if (oldWidget.navigationMode != widget.navigationMode) {
      if (kIsWeb) _webNavEpoch++;
      refitRoute();
    }

    _maybeRemountForLiveMarkers(oldWidget.markers, widget.markers);

    final destChanged =
        oldWidget.destLat != widget.destLat ||
        oldWidget.destLng != widget.destLng;
    final originChanged =
        oldWidget.originLat != widget.originLat ||
        oldWidget.originLng != widget.originLng;

    if (destChanged) {
      _loadRoute(force: true);
      return;
    }

    final markersChanged =
        _markerHash(oldWidget.markers) != _markerHash(widget.markers);
    if (originChanged || markersChanged) {
      _updateLiveGuidance();
      if (_loading) {
        _pendingRouteReload = _pendingRouteReload ||
            _originMovedEnough(
              _loadedOriginLat,
              _loadedOriginLng,
              widget.originLat,
              widget.originLng,
            );
        return;
      }
      final offRouteLongEnough = _guidance?.offRoute == true &&
          !_rerouting &&
          (_lastRerouteAt == null ||
              DateTime.now().difference(_lastRerouteAt!) >
                  const Duration(seconds: 8));
      final shouldRefresh = _originMovedEnough(
            _loadedOriginLat,
            _loadedOriginLng,
            widget.originLat,
            widget.originLng,
          ) ||
          offRouteLongEnough;
      if (shouldRefresh) {
        _lastRerouteAt = DateTime.now();
        _loadRoute(force: true, silent: true);
      }
    }
  }

  /// google_maps_flutter_web drops polylines when markers rebuild — sync via platform.
  void _maybeRemountForLiveMarkers(
    List<RawanaMapMarker> oldMarkers,
    List<RawanaMapMarker> newMarkers,
  ) {
    if (_polyline.length < 2) return;
    if (widget.navigationMode) return;
    if (kIsWeb) return;

    final newHash = _markerHash(newMarkers);
    if (newHash == _lastMarkerHash) return;
    _lastMarkerHash = newHash;

    final followMovedFar = _followMarkerMovedFar(oldMarkers, newMarkers);
    if (!followMovedFar && !widget.navigationMode) return;

    setState(() => _fitRouteRevision++);
  }

  bool _followMarkerMovedFar(
    List<RawanaMapMarker> oldMarkers,
    List<RawanaMapMarker> newMarkers,
  ) {
    final oldFollow = _followMarker(oldMarkers);
    final newFollow = _followMarker(newMarkers);
    if (oldFollow == null || newFollow == null) return true;
    final meters = _distance.as(
      LengthUnit.Meter,
      LatLng(oldFollow.lat, oldFollow.lng),
      LatLng(newFollow.lat, newFollow.lng),
    );
    return meters >= (widget.navigationMode ? 20 : 120);
  }

  RawanaMapMarker? _followMarker(List<RawanaMapMarker> markers) {
    for (final m in markers) {
      if (m.followTarget || m.id == 'driver') return m;
    }
    return null;
  }

  int _markerHash(List<RawanaMapMarker> markers) {
    var hash = markers.length;
    for (final m in markers) {
      hash = Object.hash(
        hash,
        m.id,
        m.icon.codePoint,
        (m.lat * 10000).round(),
        (m.lng * 10000).round(),
        (m.heading ?? -1).round(),
        m.followTarget,
      );
    }
    return hash;
  }

  bool _originMovedEnough(
    double? fromLat,
    double? fromLng,
    double toLat,
    double toLng,
  ) {
    if (fromLat == null || fromLng == null) return true;
    final meters = _distance.as(
      LengthUnit.Meter,
      LatLng(fromLat, fromLng),
      LatLng(toLat, toLng),
    );
    return meters >= widget.refreshOriginAfterMeters;
  }

  void _updateLiveGuidance() {
    if (_polyline.length < 2) return;
    final follow = _followMarker(widget.markers);
    if (follow == null && !widget.navigationMode) {
      if (_remainingPolyline.isNotEmpty || _traveledPolyline.isNotEmpty) {
        setState(() {
          _remainingPolyline = const [];
          _traveledPolyline = const [];
        });
      }
      return;
    }
    final lat = follow?.lat ?? widget.originLat;
    final lng = follow?.lng ?? widget.originLng;
    final selected = _routes.isEmpty
        ? null
        : _routes[_selectedRouteIndex.clamp(0, _routes.length - 1)];
    final guidance = computeNavigationGuidance(
      route: _polyline,
      steps: selected?.steps ?? _steps,
      lat: lat,
      lng: lng,
      heading: usableHeading(widget.followHeading) ??
          usableHeading(follow?.heading),
      totalDistanceKm: selected?.distanceKm ?? 0,
      totalDurationMinutes: selected?.durationMinutes ?? 1,
    );
    if (!mounted) return;
    final changed = _guidance?.snappedLat != guidance.snappedLat ||
        _guidance?.snappedLng != guidance.snappedLng ||
        _guidance?.stepIndex != guidance.stepIndex ||
        _guidance?.offRoute != guidance.offRoute ||
        (_guidance?.remainingDistanceKm ?? 0).toStringAsFixed(2) !=
            guidance.remainingDistanceKm.toStringAsFixed(2);
    if (!changed) return;
    setState(() {
      _guidance = guidance;
      if (widget.navigationMode) {
        _remainingPolyline = guidance.remainingPolyline;
        _traveledPolyline = guidance.traveledPolyline;
      } else {
        _remainingPolyline = const [];
        _traveledPolyline = const [];
      }
    });
    widget.onGuidanceChanged?.call(guidance);
  }

  Future<void> _loadRoute({required bool force, bool silent = false}) async {
    if (!force &&
        _loadedDestLat == widget.destLat &&
        _loadedDestLng == widget.destLng &&
        !_originMovedEnough(
          _loadedOriginLat,
          _loadedOriginLng,
          widget.originLat,
          widget.originLng,
        )) {
      return;
    }

    if (!silent || _polyline.length < 2) {
      if (mounted) setState(() => _loading = true);
    }
    final token = ++_routeLoadToken;
    final requestOriginLat = widget.originLat;
    final requestOriginLng = widget.originLng;
    final requestDestLat = widget.destLat;
    final requestDestLng = widget.destLng;
    _rerouting = true;
    try {
      final route = await widget.mapsService.getDirections(
        originLat: requestOriginLat,
        originLng: requestOriginLng,
        destLat: requestDestLat,
        destLng: requestDestLng,
      );
      if (!mounted || token != _routeLoadToken) return;
      final routes = route.routes.isNotEmpty
          ? route.routes
          : [
              RouteOption(
                label: route.label,
                polyline: route.polyline,
                distanceKm: route.distanceKm,
                durationMinutes: route.durationMinutes,
                steps: route.steps,
              ),
            ];
      final destMoved = _loadedDestLat != requestDestLat ||
          _loadedDestLng != requestDestLng;
      final selectedIndex = destMoved
          ? 0
          : _selectedRouteIndex.clamp(0, routes.length - 1).toInt();
      final selectedRoute = routes[selectedIndex];
      setState(() {
        _routes = routes;
        _selectedRouteIndex = selectedIndex;
        _encodedPolyline = selectedRoute.polyline;
        _steps = selectedRoute.steps;
        _polyline = _decodeRoute(selectedRoute);
        if (_polyline.length < 2) {
          _polyline = [
            LatLng(requestOriginLat, requestOriginLng),
            LatLng(requestDestLat, requestDestLng),
          ];
        }
        _loadedOriginLat = requestOriginLat;
        _loadedOriginLng = requestOriginLng;
        _loadedDestLat = requestDestLat;
        _loadedDestLng = requestDestLng;
        _loading = false;
        if (!silent) _fitRouteRevision++;
      });
      widget.onRouteLoaded?.call(_directionsFor(selectedRoute, routes));
      _updateLiveGuidance();
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_polyline.length < 2) {
            _polyline = [
              LatLng(widget.originLat, widget.originLng),
              LatLng(widget.destLat, widget.destLng),
            ];
            _remainingPolyline = _polyline;
          }
          _loading = false;
          if (!silent) _fitRouteRevision++;
        });
      }
    } finally {
      _rerouting = false;
      if (mounted && _pendingRouteReload) {
        _pendingRouteReload = false;
        _loadRoute(force: true, silent: true);
      }
    }
  }

  List<LatLng> _decodeRoute(RouteOption route) {
    final points = decodePolyline(route.polyline);
    if (points.length >= 2) return points;
    return [
      LatLng(widget.originLat, widget.originLng),
      LatLng(widget.destLat, widget.destLng),
    ];
  }

  RouteDirections _directionsFor(
    RouteOption selectedRoute,
    List<RouteOption> routes,
  ) => RouteDirections(
    label: selectedRoute.label,
    polyline: selectedRoute.polyline,
    distanceKm: selectedRoute.distanceKm,
    durationMinutes: selectedRoute.durationMinutes,
    provider: selectedRoute.provider,
    isFallback: selectedRoute.isFallback,
    steps: selectedRoute.steps,
    routes: routes,
  );

  void _selectRoute(int index) {
    if (index == _selectedRouteIndex || index < 0 || index >= _routes.length) {
      return;
    }
    final selectedRoute = _routes[index];
    setState(() {
      _selectedRouteIndex = index;
      _encodedPolyline = selectedRoute.polyline;
      _steps = selectedRoute.steps;
      _polyline = _decodeRoute(selectedRoute);
      _fitRouteRevision++;
    });
    widget.onRouteLoaded?.call(_directionsFor(selectedRoute, _routes));
    _updateLiveGuidance();
  }

  @override
  Widget build(BuildContext context) {
    final centerLat = (widget.originLat + widget.destLat) / 2;
    final centerLng = (widget.originLng + widget.destLng) / 2;
    final routeReady = _polyline.length >= 2;
    final displayPolyline = widget.navigationMode &&
            _remainingPolyline.length >= 2
        ? _remainingPolyline
        : _polyline;
    final secondaryPolylines = routeReady && _routes.length > 1
        ? [
            for (var i = 0; i < _routes.length; i++)
              if (i != _selectedRouteIndex) _decodeRoute(_routes[i]),
          ]
        : const <List<LatLng>>[];
    final encodedSecondaryPolylines = routeReady && _routes.length > 1
        ? [
            for (var i = 0; i < _routes.length; i++)
              if (i != _selectedRouteIndex) _routes[i].polyline,
          ]
        : const <String>[];

    final mapKey = ValueKey(
      kIsWeb
          ? 'trip_web_${_mapSessionId}_e$_webNavEpoch'
          : 'trip_map_$_mapSessionId',
    );
    final follow = _followMarker(widget.markers);
    final followLat = follow?.lat ??
        (widget.navigationMode ? widget.originLat : null);
    final followLng = follow?.lng ??
        (widget.navigationMode ? widget.originLng : null);
    // Point the vehicle along the remaining route, not a stale 0° GPS heading.
    final followHeading = _guidance?.bearing ??
        usableHeading(widget.followHeading) ??
        usableHeading(follow?.heading);
    final navZoom = widget.navigationMode ? 17.0 : widget.zoom;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: LtrMapSurface(
            child: routeReady
              ? kIsWeb
                  ? WebNativeRouteMap(
                      key: mapKey,
                      originLat: widget.originLat,
                      originLng: widget.originLng,
                      destLat: widget.destLat,
                      destLng: widget.destLng,
                      zoom: navZoom,
                      markers: widget.markers,
                      encodedPolyline: _encodedPolyline,
                      polylinePoints: displayPolyline,
                      encodedSecondaryPolylines: encodedSecondaryPolylines,
                      secondaryPolylinePoints: secondaryPolylines,
                      traveledPolylinePoints: _traveledPolyline,
                      polylineColor: RawanaColors.routeLine,
                      polylineWidth: 8,
                      fitRouteBounds: widget.fitRouteBounds,
                      fitRouteRevision: _fitRouteRevision,
                      recenterRevision: _recenterRevision,
                      navigationMode: widget.navigationMode,
                      followLat: followLat,
                      followLng: followLng,
                      followHeading: followHeading,
                    )
                  : RawanaMap(
                      key: mapKey,
                      zoom: navZoom,
                      centerLat: followLat ?? centerLat,
                      centerLng: followLng ?? centerLng,
                      myLocationEnabled: widget.myLocationEnabled,
                      markers: widget.markers,
                      polylinePoints: displayPolyline,
                      secondaryPolylinePoints: secondaryPolylines,
                      traveledPolylinePoints: _traveledPolyline,
                      polylineColor: RawanaColors.routeLine,
                      polylineWidth: 8,
                      fitRouteBounds:
                          widget.fitRouteBounds && !widget.navigationMode,
                      fitRouteRevision: _fitRouteRevision,
                      recenterRevision: _recenterRevision,
                      navigationMode: widget.navigationMode,
                      followLat: followLat,
                      followLng: followLng,
                      followHeading: followHeading,
                    )
              : ColoredBox(
                  color: RawanaColors.surfaceAlt,
                  child: Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: RawanaColors.onSurfaceMuted.withValues(alpha: 0.35),
                    ),
                  ),
                ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: widget.showRouteSelector && _routes.length > 1
              ? widget.routeSelectorBottomInset + 56
              : widget.routeSelectorBottomInset,
          child: SafeArea(
            top: false,
            child: MapRecenterButton(onPressed: recenterOnCurrentLocation),
          ),
        ),
        if (widget.showRouteSelector && _routes.length > 1)
          Positioned(
            left: 12,
            right: 12,
            bottom: widget.routeSelectorBottomInset,
            child: _RouteSelector(
              routes: _routes,
              selectedIndex: _selectedRouteIndex,
              onSelected: _selectRoute,
            ),
          ),
        if (_loading)
          const Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RouteSelector extends StatelessWidget {
  const _RouteSelector({
    required this.routes,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RouteOption> routes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  int get _shortestIndex {
    var index = 0;
    for (var i = 1; i < routes.length; i++) {
      if (routes[i].distanceKm < routes[index].distanceKm) index = i;
    }
    return index;
  }

  int get _fastestIndex {
    var index = 0;
    for (var i = 1; i < routes.length; i++) {
      if (routes[i].durationMinutes < routes[index].durationMinutes) index = i;
    }
    return index;
  }

  String _labelFor(int index, AppLocalizations l10n) {
    if (index == _shortestIndex) return l10n.routeShortest;
    if (index == _fastestIndex) return l10n.routeFastest;
    return routes[index].label;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(routes.length, (index) {
          final route = routes[index];
          final selected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Material(
              color: selected ? RawanaColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
              elevation: selected ? 5 : 2,
              shadowColor: const Color(0x260A2540),
              child: InkWell(
                borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
                onTap: () => onSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_rounded
                            : Icons.alt_route_rounded,
                        size: 16,
                        color: selected ? Colors.white : RawanaColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _labelFor(index, l10n),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : RawanaColors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.routeChipDurationDistance(
                          '${route.durationMinutes}',
                          route.distanceKm.toStringAsFixed(1),
                        ),
                        style: TextStyle(
                          color: selected
                              ? Colors.white70
                              : RawanaColors.onSurfaceMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
