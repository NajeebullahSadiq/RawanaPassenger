import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Re-applies polylines on Google Maps web via the platform channel.
///
/// [WebMapMarkerSync] updates wipe rendered polylines — call this after every
/// marker sync to restore the route line.
class WebRoutePolylineSync {
  WebRoutePolylineSync(this.mapId);

  final int mapId;
  Set<gm.Polyline> _applied = const {};

  Future<void> sync(Set<gm.Polyline> target) async {
    if (!kIsWeb) return;

    final updates = PolylineUpdates.from(_applied, target);
    if (updates.polylinesToAdd.isEmpty &&
        updates.polylinesToChange.isEmpty &&
        updates.polylineIdsToRemove.isEmpty) {
      return;
    }

    await GoogleMapsFlutterPlatform.instance.updatePolylines(
      updates,
      mapId: mapId,
    );
    _applied = target;
  }

  Future<void> forceApply(Set<gm.Polyline> target) async {
    if (!kIsWeb) return;
    if (_applied.isNotEmpty) {
      await GoogleMapsFlutterPlatform.instance.updatePolylines(
        PolylineUpdates.from(_applied, const {}),
        mapId: mapId,
      );
      _applied = const {};
    }
    if (target.isEmpty) return;
    await GoogleMapsFlutterPlatform.instance.updatePolylines(
      PolylineUpdates.from(const {}, target),
      mapId: mapId,
    );
    _applied = target;
  }
}
