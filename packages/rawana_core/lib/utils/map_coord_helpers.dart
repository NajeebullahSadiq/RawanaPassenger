import 'package:latlong2/latlong.dart';

/// True when [lat]/[lng] are usable on a map (excludes null island noise).
bool isValidMapCoord(double lat, double lng) =>
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180 &&
    !(lat.abs() < 0.01 && lng.abs() < 0.01);

List<LatLng> filterValidMapCoords(List<LatLng> points) =>
    points.where((p) => isValidMapCoord(p.latitude, p.longitude)).toList();
