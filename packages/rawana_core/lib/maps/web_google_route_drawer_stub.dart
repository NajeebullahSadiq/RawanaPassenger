import 'package:latlong2/latlong.dart';

/// No-op on mobile/desktop.
class WebGoogleRouteDrawer {
  static Future<void> drawRoute({
    required int mapId,
    required List<LatLng> points,
    required int colorArgb,
    required int width,
    String layerId = 'rawana_main_route',
  }) async {}

  static Future<bool> drawDirectionsRoute({
    required int mapId,
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required int colorArgb,
    required int width,
    String layerId = 'rawana_directions',
  }) async =>
      false;

  static Future<void> clearRoute({
    required int mapId,
    String layerId = 'rawana_main_route',
  }) async {}
}
