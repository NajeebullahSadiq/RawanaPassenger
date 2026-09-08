import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import '../theme/rawana_theme.dart';
import '../utils/map_coord_helpers.dart';
import '../utils/trip_polyline_helpers.dart';
import 'ltr_map_surface.dart';
import 'rawana_map_marker.dart';

/// Web route map using native Google Maps JS — polylines are drawn directly
/// on the map instance, bypassing google_maps_flutter_web polyline bugs.
class WebNativeRouteMap extends StatefulWidget {
  const WebNativeRouteMap({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.encodedPolyline,
    required this.polylinePoints,
    this.encodedSecondaryPolylines = const [],
    this.secondaryPolylinePoints = const [],
    this.traveledPolylinePoints = const [],
    this.markers = const [],
    this.zoom = 14,
    this.polylineColor = RawanaColors.routeLine,
    this.polylineWidth = 8,
    this.fitRouteBounds = true,
    this.fitRouteRevision = 0,
    this.recenterRevision = 0,
    this.navigationMode = false,
    this.followLat,
    this.followLng,
    this.followHeading,
  });

  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final String encodedPolyline;
  final List<LatLng> polylinePoints;
  final List<String> encodedSecondaryPolylines;
  final List<List<LatLng>> secondaryPolylinePoints;
  final List<LatLng> traveledPolylinePoints;
  final List<RawanaMapMarker> markers;
  final double zoom;
  final Color polylineColor;
  final int polylineWidth;
  final bool fitRouteBounds;
  final int fitRouteRevision;
  final int recenterRevision;
  final bool navigationMode;
  final double? followLat;
  final double? followLng;
  final double? followHeading;

  @override
  State<WebNativeRouteMap> createState() => _WebNativeRouteMapState();
}

class _WebNativeRouteMapState extends State<WebNativeRouteMap> {
  late final String _viewType;
  late final String _mapId;
  bool _registered = false;
  int _markerHash = 0;
  int _routeHash = 0;

  @override
  void initState() {
    super.initState();
    _mapId = 'rawana_${identityHashCode(this)}';
    _viewType = 'rawana-route-map-$_mapId';
    _markerHash = _hashMarkers(widget.markers);
    _routeHash = _hashRoute();
    _registerViewFactory();
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerResize());
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _triggerResize();
    });
  }

  @override
  void dispose() {
    if (js.context.hasProperty('__rawanaRouteMapDestroy')) {
      js.context.callMethod('__rawanaRouteMapDestroy', [_mapId]);
    }
    super.dispose();
  }

  void _registerViewFactory() {
    if (_registered) return;
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final div = html.DivElement()
        ..dir = 'ltr'
        ..style.direction = 'ltr'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.minHeight = '100%'
        ..style.minWidth = '100%'
        ..style.display = 'block'
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.border = '0'
        ..style.backgroundColor = '#E8EDF2';
      _initMap(div);
      return div;
    });
  }

  void _initMap(html.DivElement div) {
    js.context.callMethod('__rawanaRouteMapInit', [
      div,
      _buildConfig(fitBounds: widget.fitRouteBounds || widget.navigationMode),
    ]);
  }

  js.JsObject _buildConfig({required bool fitBounds}) {
    final primaryPath = _pathToJs(
      simplifyPolylineForMap(filterValidMapCoords(widget.polylinePoints)),
    );

    return js.JsObject.jsify({
      'id': _mapId,
      'originLat': widget.originLat,
      'originLng': widget.originLng,
      'destLat': widget.destLat,
      'destLng': widget.destLng,
      'centerLat': (widget.originLat + widget.destLat) / 2,
      'centerLng': (widget.originLng + widget.destLng) / 2,
      'zoom': widget.zoom,
      'encodedPolyline': widget.encodedPolyline,
      'encodedSecondaryPolylines': widget.encodedSecondaryPolylines
          .where((p) => p.isNotEmpty)
          .toList(growable: false),
      'path': primaryPath,
      'secondaryPaths': widget.secondaryPolylinePoints
          .map(
            (route) => _pathToJs(
              simplifyPolylineForMap(filterValidMapCoords(route)),
            ),
          )
          .where((route) => route.length >= 2)
          .toList(growable: false),
      'lineColor': _colorHex(widget.polylineColor),
      'lineWidth': widget.polylineWidth,
      'fitBounds': fitBounds && !widget.navigationMode,
      'navigationMode': widget.navigationMode,
      'followLat': widget.followLat,
      'followLng': widget.followLng,
      'followHeading': widget.followHeading,
      'traveledPath': _pathToJs(
        simplifyPolylineForMap(filterValidMapCoords(widget.traveledPolylinePoints)),
      ),
      'markers': _markersToJs(widget.markers),
    });
  }

  List<List<double>> _pathToJs(List<LatLng> path) {
    return [
      for (final p in path)
        if (isValidMapCoord(p.latitude, p.longitude))
          [p.latitude, p.longitude],
    ];
  }

  List<Map<String, dynamic>> _markersToJs(List<RawanaMapMarker> markers) {
    return [
      for (final m in markers)
        if (isValidMapCoord(m.lat, m.lng))
          {
            'lat': m.lat,
            'lng': m.lng,
            'label': m.label ?? '',
            'color': _colorHex(m.color),
            'kind': m.vehicleKind?.apiName ??
                (m.id == 'you'
                    ? 'you'
                    : m.id == 'passenger'
                        ? 'passenger'
                        : m.id == 'pickup'
                            ? 'pickup'
                            : m.id == 'dropoff'
                                ? 'dropoff'
                                : 'pin'),
            'heading': m.heading,
            'follow': m.followTarget,
          },
    ];
  }

  String _colorHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  int _hashMarkers(List<RawanaMapMarker> markers) {
    var hash = markers.length;
    for (final m in markers) {
      if (!isValidMapCoord(m.lat, m.lng)) continue;
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

  int _hashRoute() => Object.hash(
    widget.encodedPolyline,
    widget.fitRouteRevision,
    widget.navigationMode,
    widget.encodedSecondaryPolylines.join('|'),
    widget.polylinePoints.length,
    widget.secondaryPolylinePoints.length,
    widget.traveledPolylinePoints.length,
  );

  void _syncMap({bool fitBounds = false}) {
    if (!js.context.hasProperty('__rawanaRouteMapUpdate')) return;
    js.context.callMethod('__rawanaRouteMapUpdate', [
      _mapId,
      _buildConfig(fitBounds: fitBounds),
    ]);
  }

  void _recenterOnUser() {
    if (!js.context.hasProperty('__rawanaRouteMapRecenter')) return;
    js.context.callMethod('__rawanaRouteMapRecenter', [
      _mapId,
      _buildConfig(fitBounds: false),
    ]);
  }

  void _syncFollow() {
    if (!js.context.hasProperty('__rawanaRouteMapFollow')) return;
    js.context.callMethod('__rawanaRouteMapFollow', [
      _mapId,
      _buildConfig(fitBounds: true),
    ]);
  }

  void _triggerResize() {
    if (!js.context.hasProperty('__rawanaRouteMapResize')) return;
    js.context.callMethod('__rawanaRouteMapResize', [
      _mapId,
      _buildConfig(fitBounds: widget.navigationMode || widget.fitRouteBounds),
    ]);
  }

  void _syncMarkers() {
    if (!js.context.hasProperty('__rawanaRouteMapUpdateMarkers')) return;
    js.context.callMethod('__rawanaRouteMapUpdateMarkers', [
      _mapId,
      js.JsObject.jsify(_markersToJs(widget.markers)),
      _buildConfig(fitBounds: widget.navigationMode),
    ]);
  }

  @override
  void didUpdateWidget(covariant WebNativeRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newRouteHash = _hashRoute();
    if (newRouteHash != _routeHash) {
      _routeHash = newRouteHash;
      _syncMap(
        fitBounds: widget.fitRouteBounds || widget.navigationMode,
      );
    }

    final newMarkerHash = _hashMarkers(widget.markers);
    if (newMarkerHash != _markerHash) {
      _markerHash = newMarkerHash;
      if (widget.navigationMode) {
        _syncFollow();
      } else {
        _syncMarkers();
      }
    } else if (oldWidget.followLat != widget.followLat ||
        oldWidget.followLng != widget.followLng ||
        oldWidget.followHeading != widget.followHeading) {
      if (widget.navigationMode) {
        _syncFollow();
      } else {
        _syncMarkers();
      }
    } else if (oldWidget.navigationMode != widget.navigationMode ||
        oldWidget.fitRouteBounds != widget.fitRouteBounds) {
      _syncMap(fitBounds: widget.navigationMode || widget.fitRouteBounds);
    }

    if (oldWidget.recenterRevision != widget.recenterRevision) {
      _recenterOnUser();
    }

    if (oldWidget.navigationMode != widget.navigationMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _triggerResize();
      });
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _triggerResize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : screen.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screen.height;
        return SizedBox(
          width: width,
          height: height,
          child: LtrMapSurface(
            child: HtmlElementView(viewType: _viewType),
          ),
        );
      },
    );
  }
}
