import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/rawana_theme.dart';
import '../utils/vehicle_kind.dart';

class RawanaMapMarker {
  const RawanaMapMarker({
    required this.lat,
    required this.lng,
    this.id,
    this.icon = Icons.place,
    this.color = RawanaColors.primary,
    this.size = 28,
    this.label,
    this.heading,
    this.vehicleKind,
    this.followTarget = false,
  });

  factory RawanaMapMarker.driver({
    required double lat,
    required double lng,
    String? label,
    double? heading,
    VehicleKind vehicleKind = VehicleKind.car,
    AppLocalizations? l10n,
  }) => RawanaMapMarker(
    id: 'driver',
    lat: lat,
    lng: lng,
    icon: vehicleKind.mapIcon,
    color: RawanaColors.ink,
    size: 46,
    label: label ?? l10n?.driver,
    heading: heading,
    vehicleKind: vehicleKind,
    followTarget: true,
  );

  factory RawanaMapMarker.passenger({
    required double lat,
    required double lng,
    String? label,
    AppLocalizations? l10n,
  }) => RawanaMapMarker(
    id: 'passenger',
    lat: lat,
    lng: lng,
    icon: Icons.person_pin_circle,
    color: RawanaColors.primary,
    size: 30,
    label: label ?? l10n?.passenger,
  );

  /// Google Maps-style blue “you are here” dot for the device owner.
  factory RawanaMapMarker.you({
    required double lat,
    required double lng,
    String? label,
    AppLocalizations? l10n,
  }) => RawanaMapMarker(
    id: 'you',
    lat: lat,
    lng: lng,
    icon: Icons.my_location,
    color: const Color(0xFF1A73E8),
    size: 36,
    label: label ?? l10n?.you,
  );

  factory RawanaMapMarker.pickup({
    required double lat,
    required double lng,
    String? label,
    AppLocalizations? l10n,
  }) => RawanaMapMarker(
    id: 'pickup',
    lat: lat,
    lng: lng,
    icon: Icons.trip_origin,
    color: RawanaColors.pickupPin,
    size: 30,
    label: label ?? l10n?.pickup,
  );

  factory RawanaMapMarker.dropoff({
    required double lat,
    required double lng,
    String? label,
    AppLocalizations? l10n,
  }) => RawanaMapMarker(
    id: 'dropoff',
    lat: lat,
    lng: lng,
    icon: Icons.flag,
    color: RawanaColors.dropoffPin,
    size: 32,
    label: label ?? l10n?.dropoff,
  );

  /// Smaller vehicle pin for nearby online drivers before a trip is matched.
  factory RawanaMapMarker.nearbyDriver({
    required double lat,
    required double lng,
    String? label,
    double? heading,
    VehicleKind vehicleKind = VehicleKind.car,
  }) => RawanaMapMarker(
    lat: lat,
    lng: lng,
    icon: vehicleKind.mapIcon,
    color: RawanaColors.ink,
    size: 40,
    label: label,
    heading: heading,
    vehicleKind: vehicleKind,
  );

  final String? id;
  final double lat;
  final double lng;
  final IconData icon;
  final Color color;
  final double size;
  final String? label;
  final double? heading;
  final VehicleKind? vehicleKind;
  final bool followTarget;

  /// Geometry / identity only. Localized [label] is ignored so a language
  /// switch does not reload marker icons or remount the map.
  bool sameGeometry(RawanaMapMarker other) {
    return id == other.id &&
        lat == other.lat &&
        lng == other.lng &&
        icon == other.icon &&
        color == other.color &&
        size == other.size &&
        heading == other.heading &&
        vehicleKind == other.vehicleKind &&
        followTarget == other.followTarget;
  }

  static bool sameGeometryList(
    List<RawanaMapMarker> a,
    List<RawanaMapMarker> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!a[i].sameGeometry(b[i])) return false;
    }
    return true;
  }

  /// Live person to zoom to: device owner first, then driver, then passenger.
  static RawanaMapMarker? currentUserOrRole(List<RawanaMapMarker> markers) {
    RawanaMapMarker? you;
    RawanaMapMarker? driver;
    RawanaMapMarker? passenger;
    for (final m in markers) {
      if (m.id == 'you') {
        you = m;
      } else if (m.id == 'driver' || m.followTarget) {
        driver ??= m;
      } else if (m.id == 'passenger') {
        passenger ??= m;
      }
    }
    return you ?? driver ?? passenger;
  }
}
