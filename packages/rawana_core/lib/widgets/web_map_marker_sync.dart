import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Updates markers on Google Maps web via the platform channel only.
///
/// Passing marker changes through the [gm.GoogleMap] widget clears polylines on
/// web — keep [gm.GoogleMap.markers] empty and sync markers here instead.
class WebMapMarkerSync {
  WebMapMarkerSync(this.mapId);

  final int mapId;
  Set<gm.Marker> _applied = const {};

  Future<void> sync(Set<gm.Marker> target) async {
    if (!kIsWeb) return;

    final updates = MarkerUpdates.from(_applied, target);
    if (updates.markersToAdd.isEmpty &&
        updates.markersToChange.isEmpty &&
        updates.markerIdsToRemove.isEmpty) {
      return;
    }

    await GoogleMapsFlutterPlatform.instance.updateMarkers(
      updates,
      mapId: mapId,
    );
    _applied = target;
  }

  Future<void> clear() => sync(const {});
}
