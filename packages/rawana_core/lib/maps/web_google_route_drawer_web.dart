import 'dart:js' as js;

import 'package:latlong2/latlong.dart';

/// Draws routes on Google Maps web via the JS API (bypasses flutter plugin bugs).
class WebGoogleRouteDrawer {
  static String _strokeColor(int colorArgb) {
    final r = (colorArgb >> 16) & 0xFF;
    final g = (colorArgb >> 8) & 0xFF;
    final b = colorArgb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  static Future<void> drawRoute({
    required int mapId,
    required List<LatLng> points,
    required int colorArgb,
    required int width,
    String layerId = 'rawana_main_route',
  }) async {
    if (points.length < 2) return;

    final draw = js.context['__rawanaDrawRoute'];
    if (draw == null) return;

    final coords = points.map((p) => [p.latitude, p.longitude]).toList();
    (draw as js.JsFunction).apply([
      mapId,
      js.JsObject.jsify(coords),
      _strokeColor(colorArgb),
      width,
      layerId,
    ]);
  }

  /// Uses google.maps.DirectionsRenderer — most reliable route line on web.
  static Future<bool> drawDirectionsRoute({
    required int mapId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required int colorArgb,
    required int width,
    String layerId = 'rawana_directions',
  }) async {
    final draw = js.context['__rawanaDrawDirectionsRoute'];
    if (draw == null) return false;

    final result = (draw as js.JsFunction).apply([
      mapId,
      originLat,
      originLng,
      destLat,
      destLng,
      _strokeColor(colorArgb),
      width,
      layerId,
    ]);
    return result == true;
  }

  static Future<void> clearRoute({
    required int mapId,
    String layerId = 'rawana_main_route',
  }) async {
    final clear = js.context['__rawanaClearRoute'];
    if (clear == null) return;
    (clear as js.JsFunction).apply([mapId, layerId]);
  }
}
