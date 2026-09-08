import 'package:latlong2/latlong.dart';

/// Reduces polyline point count for map rendering (web can fail on huge paths).
List<LatLng> simplifyPolylineForMap(
  List<LatLng> points, {
  int maxPoints = 200,
}) {
  if (points.length <= maxPoints) return List<LatLng>.from(points);

  final simplified = <LatLng>[];
  final step = (points.length - 1) / (maxPoints - 1);
  for (var i = 0; i < maxPoints - 1; i++) {
    simplified.add(points[(i * step).round()]);
  }
  simplified.add(points.last);
  return simplified;
}

/// Content equality so locale rebuilds (new [List] instances, same geometry)
/// do not refit the camera or remount the platform map.
bool samePolylinePoints(List<LatLng> a, List<LatLng> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude) {
      return false;
    }
  }
  return true;
}

bool sameSecondaryPolylines(List<List<LatLng>> a, List<List<LatLng>> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!samePolylinePoints(a[i], b[i])) return false;
  }
  return true;
}
