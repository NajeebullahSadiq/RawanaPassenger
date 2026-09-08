import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/rawana_theme.dart';
import 'ltr_map_surface.dart';
import 'rawana_map.dart';

/// Mobile/desktop fallback — delegates to [RawanaMap].
class WebNativeRouteMap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final centerLat = (originLat + destLat) / 2;
    final centerLng = (originLng + destLng) / 2;
    return LtrMapSurface(
      child: RawanaMap(
      key: key,
      zoom: zoom,
      centerLat: centerLat,
      centerLng: centerLng,
      markers: markers,
      polylinePoints: polylinePoints,
      secondaryPolylinePoints: secondaryPolylinePoints,
      traveledPolylinePoints: traveledPolylinePoints,
      polylineColor: polylineColor,
      polylineWidth: polylineWidth,
      fitRouteBounds: fitRouteBounds && !navigationMode,
      fitRouteRevision: fitRouteRevision,
      recenterRevision: recenterRevision,
      navigationMode: navigationMode,
      followLat: followLat,
      followLng: followLng,
      followHeading: followHeading,
    ),
    );
  }
}
