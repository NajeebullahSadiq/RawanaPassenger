import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/rawana_theme.dart';
import 'ltr_map_surface.dart';
import 'rawana_map_google.dart';
import 'rawana_map_marker.dart';

export 'rawana_map_marker.dart';

/// Interactive map powered by Google Maps on all platforms.
class RawanaMap extends StatelessWidget {
  const RawanaMap({
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
    this.polylineColor = RawanaColors.primary,
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
  Widget build(BuildContext context) {
    // Platform map views are mirrored when the app is RTL (Dari/Pashto).
    return LtrMapSurface(
      child: RawanaGoogleMap(
      zoom: zoom,
      centerLat: centerLat,
      centerLng: centerLng,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      markers: markers,
      polylinePoints: polylinePoints,
      secondaryPolylinePoints: secondaryPolylinePoints,
      traveledPolylinePoints: traveledPolylinePoints,
      polylineColor: polylineColor,
      polylineWidth: polylineWidth,
      fitRouteBounds: fitRouteBounds,
      boundsPadding: boundsPadding,
      fitRouteRevision: fitRouteRevision,
      recenterRevision: recenterRevision,
      navigationMode: navigationMode,
      followLat: followLat,
      followLng: followLng,
      followHeading: followHeading,
      onTap: onTap,
      onCameraMove: onCameraMove,
    ),
    );
  }
}
