import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';

/// A saved address that has usable coordinates.
typedef SavedPlace = ({String label, String address, double lat, double lng});

List<SavedPlace> parseSavedPlaces(List<Map<String, dynamic>> rows) {
  final places = <SavedPlace>[];
  for (final item in rows) {
    final location = item['location'] as String?;
    final lat = parseWktLat(location) ?? (item['lat'] as num?)?.toDouble();
    final lng = parseWktLng(location) ?? (item['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    places.add((
      label: (item['label'] as String? ?? '').trim(),
      address: (item['address'] as String? ?? '').trim(),
      lat: lat,
      lng: lng,
    ));
  }
  return places;
}

SavedPlace? findSavedPlace(List<SavedPlace> places, String label) {
  for (final p in places) {
    if (p.label.toLowerCase() == label.toLowerCase()) return p;
  }
  return null;
}

IconData savedPlaceIcon(String label) => switch (label.toLowerCase()) {
      'home' => LucideIcons.house,
      'work' => LucideIcons.briefcase,
      _ => LucideIcons.star,
    };

String savedPlaceTitle(BuildContext context, String label) => switch (label.toLowerCase()) {
      'home' => context.l10n.quickHome,
      'work' => context.l10n.quickWork,
      _ => label,
    };

/// "Street 12, District 4, Kabul" → ("Street 12", "District 4, Kabul").
(String, String?) splitAddress(String address) {
  final i = address.indexOf(',');
  if (i <= 0) return (address, null);
  return (address.substring(0, i).trim(), address.substring(i + 1).trim());
}
