import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';
import '../constants.dart';
import '../theme/rawana_theme.dart';
import '../utils/trip_polyline_helpers.dart';
import 'ltr_map_surface.dart';
import 'map_marker_icon_factory.dart';
import 'rawana_map_marker.dart';
import 'web_map_marker_sync.dart';
import 'web_route_polyline_sync.dart';

class RawanaGoogleMap extends StatefulWidget {
  const RawanaGoogleMap({
    super.key,
    this.zoom = 13,
    this.centerLat,
    this.centerLng,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.markers = const [],
    this.polylinePoints = const [],
    this.secondaryPolylinePoints = const [],
    this.traveledPolylinePoints = const [],
    this.polylineColor = RawanaColors.routeLine,
    this.polylineWidth = 8,
    this.fitRouteBounds = false,
    this.boundsPadding = 72,
    this.fitRouteRevision = 0,
    this.recenterRevision = 0,
    this.navigationMode = false,
    this.followLat,
    this.followLng,
    this.followHeading,
    this.onTap,
    this.onCameraMove,
  });

  final double zoom;
  final double? centerLat;
  final double? centerLng;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final List<RawanaMapMarker> markers;
  final List<LatLng> polylinePoints;
  final List<List<LatLng>> secondaryPolylinePoints;
  final List<LatLng> traveledPolylinePoints;
  final Color polylineColor;
  final int polylineWidth;
  final bool fitRouteBounds;
  final double boundsPadding;
  final int fitRouteRevision;
  final int recenterRevision;
  final bool navigationMode;
  final double? followLat;
  final double? followLng;
  final double? followHeading;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onCameraMove;

  @override
  State<RawanaGoogleMap> createState() => _RawanaGoogleMapState();
}

class _RawanaGoogleMapState extends State<RawanaGoogleMap> {
  gm.GoogleMapController? _controller;
  WebMapMarkerSync? _webMarkerSync;
  WebRoutePolylineSync? _webPolylineSync;
  final Map<String, gm.BitmapDescriptor> _iconCache = {};
  int _iconLoadToken = 0;
  int _lastFitRevision = -1;

  /// Same widget instance on marker-only rebuilds — Flutter skips map updates.
  Widget? _cachedWebMapLayer;
  int _cachedWebRevision = -1;
  Set<gm.Polyline>? _lockedPolylines;

  bool get _hasRoute => _validPoints(widget.polylinePoints).length >= 2;

  gm.LatLng get _center {
    if (widget.centerLat != null && widget.centerLng != null) {
      return gm.LatLng(widget.centerLat!, widget.centerLng!);
    }
    return const gm.LatLng(RawanaConstants.kabulLat, RawanaConstants.kabulLng);
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _preloadMarkerIcons();
    }
  }

  @override
  void dispose() {
    _webMarkerSync = null;
    _webPolylineSync = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(RawanaGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!RawanaMapMarker.sameGeometryList(oldWidget.markers, widget.markers) ||
        oldWidget.myLocationEnabled != widget.myLocationEnabled) {
      _preloadMarkerIcons().then((_) => _syncWebMarkers());
      if (widget.navigationMode) {
        _followDriverIfNeeded();
      }
    }

    if (oldWidget.navigationMode != widget.navigationMode ||
        oldWidget.followLat != widget.followLat ||
        oldWidget.followLng != widget.followLng ||
        oldWidget.followHeading != widget.followHeading) {
      if (widget.navigationMode) {
        _followDriverIfNeeded();
      }
    }

    final routeChanged =
        !samePolylinePoints(oldWidget.polylinePoints, widget.polylinePoints) ||
        !sameSecondaryPolylines(
          oldWidget.secondaryPolylinePoints,
          widget.secondaryPolylinePoints,
        ) ||
        !samePolylinePoints(
          oldWidget.traveledPolylinePoints,
          widget.traveledPolylinePoints,
        ) ||
        oldWidget.fitRouteRevision != widget.fitRouteRevision ||
        oldWidget.polylineColor != widget.polylineColor ||
        oldWidget.polylineWidth != widget.polylineWidth;
    final boundsModeChanged = oldWidget.fitRouteBounds != widget.fitRouteBounds;

    if (oldWidget.recenterRevision != widget.recenterRevision) {
      _animateToCurrentUser();
    } else if (routeChanged || boundsModeChanged) {
      if (kIsWeb && _controller != null && _webPolylineSync != null) {
        _lockedPolylines = null;
        _syncWebPolylines();
      }
      _scheduleFitRoute();
    } else if (_controller != null &&
        !widget.fitRouteBounds &&
        // Avoid fighting the user when the screen drives selection via onCameraMove
        // (map picker): recentering on every centerLat/Lng update creates a feedback loop.
        widget.onCameraMove == null &&
        (oldWidget.centerLat != widget.centerLat ||
            oldWidget.centerLng != widget.centerLng ||
            oldWidget.zoom != widget.zoom)) {
      _controller!.animateCamera(
        gm.CameraUpdate.newCameraPosition(
          gm.CameraPosition(target: _center, zoom: widget.zoom),
        ),
      );
    }
  }

  static const _recenterZoom = 16.0;

  gm.LatLng _currentUserTarget() {
    final marker = RawanaMapMarker.currentUserOrRole(widget.markers);
    if (marker != null && _isValidCoord(marker.lat, marker.lng)) {
      return gm.LatLng(marker.lat, marker.lng);
    }
    if (widget.followLat != null &&
        widget.followLng != null &&
        _isValidCoord(widget.followLat!, widget.followLng!)) {
      return gm.LatLng(widget.followLat!, widget.followLng!);
    }
    return _center;
  }

  void _animateToCurrentUser() {
    final controller = _controller;
    if (controller == null) return;
    controller.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: _currentUserTarget(),
          zoom: widget.zoom < _recenterZoom ? _recenterZoom : widget.zoom,
        ),
      ),
    );
  }

  Future<void> _followDriverIfNeeded() async {
    if (!widget.navigationMode || _controller == null) return;
    final lat = widget.followLat;
    final lng = widget.followLng;
    if (lat == null || lng == null || !_isValidCoord(lat, lng)) return;
    await _controller!.animateCamera(
      gm.CameraUpdate.newCameraPosition(
        gm.CameraPosition(
          target: gm.LatLng(lat, lng),
          zoom: widget.zoom.clamp(16, 18),
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  Set<gm.Polyline> _polylinesForLayer() {
    if (_lockedPolylines == null ||
        _cachedWebRevision != widget.fitRouteRevision) {
      _lockedPolylines = _buildPolylines();
    }
    return _lockedPolylines!;
  }

  Future<void> _syncWebMarkers() async {
    if (!kIsWeb || !_hasRoute || _webMarkerSync == null) return;
    await _webMarkerSync!.sync(_buildMarkers());
    await _syncWebPolylines();
  }

  Future<void> _syncWebPolylines() async {
    if (!kIsWeb || !_hasRoute || _webPolylineSync == null) return;
    await _webPolylineSync!.forceApply(_polylinesForLayer());
  }

  void _scheduleFitRoute() {
    if (_controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _controller == null) return;
      if (kIsWeb) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (!mounted || _controller == null) return;
      await _fitRouteIfNeeded(force: true);
      if (kIsWeb && _hasRoute) {
        await _syncWebPolylines();
        await _syncWebMarkers();
        await _syncWebPolylines();
      } else {
        await _syncWebMarkers();
      }
    });
  }

  /// Draws the route line on web — retried because tiles/markers can wipe it.
  Future<void> _paintWebRoute({int attempts = 4}) async {
    if (!kIsWeb || !_hasRoute || _webPolylineSync == null) return;
    for (var i = 0; i < attempts; i++) {
      await _webPolylineSync!.forceApply(_polylinesForLayer());
      if (i < attempts - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  Future<void> _preloadMarkerIcons() async {
    final token = ++_iconLoadToken;
    final pending = <String, RawanaMapMarker>{};

    for (final marker in widget.markers) {
      final key = rawanaMapMarkerIconKey(
        marker.icon,
        marker.color,
        marker.size,
      );
      if (!_iconCache.containsKey(key)) {
        pending[key] = marker;
      }
    }

    if (pending.isEmpty) {
      await _syncWebMarkers();
      return;
    }

    final loaded = <String, gm.BitmapDescriptor>{};
    for (final entry in pending.entries) {
      final marker = entry.value;
      loaded[entry.key] = await createRawanaMapMarkerIcon(
        icon: marker.icon,
        color: marker.color,
        size: marker.size,
      );
    }

    if (!mounted || token != _iconLoadToken) return;
    setState(() => _iconCache.addAll(loaded));
    await _syncWebMarkers();
  }

  gm.BitmapDescriptor? _iconFor(RawanaMapMarker marker) {
    final key = rawanaMapMarkerIconKey(marker.icon, marker.color, marker.size);
    return _iconCache[key];
  }

  Set<gm.Marker> _buildMarkers() {
    final result = <gm.Marker>{};
    var id = 0;

    for (final m in widget.markers) {
      if (!_isValidCoord(m.lat, m.lng)) continue;
      final icon = _iconFor(m);
      if (icon == null) continue;
      final isVehicle = m.vehicleKind != null || m.followTarget;
      result.add(
        gm.Marker(
          markerId: gm.MarkerId(m.id ?? 'marker_$id'),
          position: gm.LatLng(m.lat, m.lng),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          rotation: isVehicle ? (m.heading ?? 0) : 0,
          flat: true,
          zIndex: m.id == 'you' ? 2 : (isVehicle ? 1 : 0),
          infoWindow: m.label != null
              ? gm.InfoWindow(title: m.label)
              : gm.InfoWindow.noText,
        ),
      );
      id++;
    }
    return result;
  }

  Set<gm.Circle> _buildAccuracyCircles() {
    return {
      for (final m in widget.markers)
        if (m.id == 'you' && _isValidCoord(m.lat, m.lng))
          gm.Circle(
            circleId: const gm.CircleId('you_accuracy'),
            center: gm.LatLng(m.lat, m.lng),
            radius: 42,
            fillColor: const Color(0x331A73E8),
            strokeColor: const Color(0x661A73E8),
            strokeWidth: 1,
            zIndex: 1,
          ),
    };
  }

  Set<gm.Polyline> _buildPolylines() {
    final polylines = <gm.Polyline>{};
    final traveled = _validGmPoints(
      simplifyPolylineForMap(_validPoints(widget.traveledPolylinePoints)),
    );
    if (traveled.length >= 2) {
      polylines.add(
        gm.Polyline(
          polylineId: gm.PolylineId('route_traveled_${widget.fitRouteRevision}'),
          points: traveled,
          color: RawanaColors.onSurfaceMuted.withValues(alpha: 0.35),
          width: 5,
          geodesic: true,
        ),
      );
    }
    for (var i = 0; i < widget.secondaryPolylinePoints.length; i++) {
      final points = _validGmPoints(
        simplifyPolylineForMap(_validPoints(widget.secondaryPolylinePoints[i])),
      );
      if (points.length < 2) continue;
      polylines.add(
        gm.Polyline(
          polylineId: gm.PolylineId('route_alt_${widget.fitRouteRevision}_$i'),
          points: points,
          color: RawanaColors.onSurfaceMuted.withValues(alpha: 0.5),
          width: 5,
          geodesic: true,
        ),
      );
    }
    final mainPoints = _validGmPoints(
      simplifyPolylineForMap(_validPoints(widget.polylinePoints)),
    );
    if (mainPoints.length >= 2) {
      polylines.add(
        gm.Polyline(
          polylineId: gm.PolylineId('route_${widget.fitRouteRevision}'),
          points: mainPoints,
          color: widget.polylineColor,
          width: widget.polylineWidth,
          geodesic: true,
          visible: true,
        ),
      );
    }
    return polylines;
  }

  List<LatLng> _validPoints(List<LatLng> points) =>
      points.where((p) => _isValidCoord(p.latitude, p.longitude)).toList();

  List<gm.LatLng> _validGmPoints(List<LatLng> points) {
    return _validPoints(points)
        .map((p) => gm.LatLng(p.latitude, p.longitude))
        .toList();
  }

  bool _isValidCoord(double lat, double lng) =>
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180 &&
      !(lat.abs() < 0.001 && lng.abs() < 0.001);

  List<LatLng> _boundsPoints() {
    final points = <LatLng>[
      ..._validPoints(widget.polylinePoints),
      for (final route in widget.secondaryPolylinePoints)
        ..._validPoints(route),
    ];
    for (final m in widget.markers) {
      if (_isValidCoord(m.lat, m.lng)) {
        points.add(LatLng(m.lat, m.lng));
      }
    }
    if (widget.centerLat != null &&
        widget.centerLng != null &&
        _isValidCoord(widget.centerLat!, widget.centerLng!)) {
      points.add(LatLng(widget.centerLat!, widget.centerLng!));
    }
    return points;
  }

  double _zoomForSpan(double latSpan, double lngSpan) {
    final span = math.max(latSpan, lngSpan).clamp(0.0005, 40.0);
    final zoom = 14.5 - math.log(span * 111) / math.ln2;
    return zoom.clamp(11.0, 17.5);
  }

  gm.CameraPosition _initialCameraPosition() {
    if (widget.fitRouteBounds) {
      final points = _boundsPoints();
      if (points.length >= 2) {
        var minLat = points.first.latitude;
        var maxLat = points.first.latitude;
        var minLng = points.first.longitude;
        var maxLng = points.first.longitude;
        for (final p in points) {
          minLat = math.min(minLat, p.latitude);
          maxLat = math.max(maxLat, p.latitude);
          minLng = math.min(minLng, p.longitude);
          maxLng = math.max(maxLng, p.longitude);
        }
        return gm.CameraPosition(
          target: gm.LatLng(
            (minLat + maxLat) / 2,
            (minLng + maxLng) / 2,
          ),
          zoom: _zoomForSpan(maxLat - minLat, maxLng - minLng),
        );
      }
    }
    return gm.CameraPosition(target: _center, zoom: widget.zoom);
  }

  Future<void> _fitRouteIfNeeded({bool force = false}) async {
    if (!widget.fitRouteBounds || _controller == null) return;
    if (!force && _lastFitRevision == widget.fitRouteRevision) return;
    _lastFitRevision = widget.fitRouteRevision;

    final points = _boundsPoints();
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    const minSpan = 0.003;
    if ((maxLat - minLat).abs() < minSpan) {
      minLat -= minSpan / 2;
      maxLat += minSpan / 2;
    }
    if ((maxLng - minLng).abs() < minSpan) {
      minLng -= minSpan / 2;
      maxLng += minSpan / 2;
    }

    await _controller!.moveCamera(
      gm.CameraUpdate.newLatLngBounds(
        gm.LatLngBounds(
          southwest: gm.LatLng(minLat, minLng),
          northeast: gm.LatLng(maxLat, maxLng),
        ),
        widget.boundsPadding,
      ),
    );
  }

  Future<void> _onMapReady(gm.GoogleMapController controller) async {
    _controller = controller;
    if (kIsWeb && _hasRoute) {
      _webMarkerSync = WebMapMarkerSync(controller.mapId);
      _webPolylineSync = WebRoutePolylineSync(controller.mapId);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _preloadMarkerIcons();
      await _paintWebRoute();
    }
    _scheduleFitRoute();
  }

  Widget _buildWebRouteLayer() {
    if (_cachedWebRevision != widget.fitRouteRevision ||
        _cachedWebMapLayer == null) {
      _cachedWebRevision = widget.fitRouteRevision;
      _lockedPolylines = null;
      _controller = null;
      _webMarkerSync = null;
      _webPolylineSync = null;
      final polylines = _polylinesForLayer();
      _cachedWebMapLayer = _FrozenWebGoogleMap(
        key: ValueKey('frozen_web_map_${widget.fitRouteRevision}'),
        polylines: polylines,
        initialCameraPosition: _initialCameraPosition(),
        onMapReady: _onMapReady,
        onTap: widget.onTap,
        onCameraMove: widget.onCameraMove,
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: widget.myLocationButtonEnabled,
        zoomControlsEnabled: widget.zoomControlsEnabled,
      );
    }
    return _cachedWebMapLayer!;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _hasRoute) {
      return _buildWebRouteLayer();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: w,
          height: h,
          child: LtrMapSurface(
            child: gm.GoogleMap(
            mapType: gm.MapType.normal,
            initialCameraPosition: _initialCameraPosition(),
            onMapCreated: _onMapReady,
            markers: _buildMarkers(),
            circles: _buildAccuracyCircles(),
            polylines: _buildPolylines(),
            onTap: widget.onTap == null
                ? null
                : (pos) => widget.onTap!(LatLng(pos.latitude, pos.longitude)),
            onCameraMove: widget.onCameraMove == null
                ? null
                : (position) => widget.onCameraMove!(
                      LatLng(
                        position.target.latitude,
                        position.target.longitude,
                      ),
                    ),
            myLocationEnabled: widget.myLocationEnabled,
            myLocationButtonEnabled: widget.myLocationButtonEnabled,
            zoomControlsEnabled: widget.zoomControlsEnabled,
            mapToolbarEnabled: false,
            compassEnabled: true,
            trafficEnabled: true,
          ),
          ),
        );
      },
    );
  }
}

/// Google Map created once with polylines baked in — never rebuilt on GPS polls.
class _FrozenWebGoogleMap extends StatefulWidget {
  const _FrozenWebGoogleMap({
    super.key,
    required this.polylines,
    required this.initialCameraPosition,
    required this.onMapReady,
    this.onTap,
    this.onCameraMove,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
  });

  final Set<gm.Polyline> polylines;
  final gm.CameraPosition initialCameraPosition;
  final Future<void> Function(gm.GoogleMapController controller) onMapReady;
  final ValueChanged<LatLng>? onTap;
  final ValueChanged<LatLng>? onCameraMove;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;

  @override
  State<_FrozenWebGoogleMap> createState() => _FrozenWebGoogleMapState();
}

class _FrozenWebGoogleMapState extends State<_FrozenWebGoogleMap> {
  late final Widget _map;

  @override
  void initState() {
    super.initState();
    // Route line is applied via WebRoutePolylineSync after the map is ready.
    // Widget polylines are empty so marker platform updates cannot wipe them.
    _map = SizedBox.expand(
      child: LtrMapSurface(
        child: gm.GoogleMap(
        mapType: gm.MapType.normal,
        initialCameraPosition: widget.initialCameraPosition,
        onMapCreated: widget.onMapReady,
        markers: const <gm.Marker>{},
        polylines: const <gm.Polyline>{},
        onTap: widget.onTap == null
            ? null
            : (pos) => widget.onTap!(LatLng(pos.latitude, pos.longitude)),
        onCameraMove: widget.onCameraMove == null
            ? null
            : (position) => widget.onCameraMove!(
                  LatLng(
                    position.target.latitude,
                    position.target.longitude,
                  ),
                ),
        myLocationEnabled: widget.myLocationEnabled,
        myLocationButtonEnabled: widget.myLocationButtonEnabled,
        zoomControlsEnabled: widget.zoomControlsEnabled,
        mapToolbarEnabled: false,
        compassEnabled: true,
        trafficEnabled: true,
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _map;
}
