import '../l10n/app_localizations.dart';
import '../models/trip.dart';
import '../theme/rawana_theme.dart';
import '../utils/navigation_guidance.dart';
import '../utils/vehicle_kind.dart';
import 'rawana_map_marker.dart';

/// Builds map markers for driver and passenger during an active booking.
List<RawanaMapMarker> buildTripLiveMarkers({
  double? passengerLat,
  double? passengerLng,
  double? driverLat,
  double? driverLng,
  double? pickupLat,
  double? pickupLng,
  double? dropoffLat,
  double? dropoffLng,
  String? passengerLabel,
  String? driverLabel,
  bool showDropoff = false,
  bool showPickup = false,
  bool passengerIsCurrentUser = false,
  double? driverHeading,
  VehicleKind vehicleKind = VehicleKind.car,
  AppLocalizations? l10n,
}) {
  final markers = <RawanaMapMarker>[];

  if (showPickup && pickupLat != null && pickupLng != null) {
    markers.add(RawanaMapMarker.pickup(lat: pickupLat, lng: pickupLng, l10n: l10n));
  }

  if (passengerLat != null && passengerLng != null) {
    markers.add(
      passengerIsCurrentUser
          ? RawanaMapMarker.you(
              lat: passengerLat,
              lng: passengerLng,
              label: passengerLabel,
              l10n: l10n,
            )
          : RawanaMapMarker.passenger(
              lat: passengerLat,
              lng: passengerLng,
              label: passengerLabel,
              l10n: l10n,
            ),
    );
  }

  if (driverLat != null && driverLng != null) {
    final overlapsPassenger =
        passengerLat != null &&
        passengerLng != null &&
        _nearby(passengerLat, passengerLng, driverLat, driverLng);
    markers.add(
      RawanaMapMarker.driver(
        lat: overlapsPassenger ? driverLat + 0.00008 : driverLat,
        lng: overlapsPassenger ? driverLng + 0.00008 : driverLng,
        label: driverLabel,
        heading: usableHeading(driverHeading),
        vehicleKind: vehicleKind,
        l10n: l10n,
      ),
    );
  }

  if (showDropoff && dropoffLat != null && dropoffLng != null) {
    markers.add(RawanaMapMarker.dropoff(lat: dropoffLat, lng: dropoffLng, l10n: l10n));
  }

  return markers;
}

/// Markers for pre-match booking screens (pickup + dropoff).
List<RawanaMapMarker> buildBookingDraftMarkers({
  required double pickupLat,
  required double pickupLng,
  required double dropoffLat,
  required double dropoffLng,
  AppLocalizations? l10n,
}) {
  return [
    RawanaMapMarker.pickup(lat: pickupLat, lng: pickupLng, l10n: l10n),
    RawanaMapMarker.dropoff(lat: dropoffLat, lng: dropoffLng, l10n: l10n),
  ];
}

/// Vehicle icons for online drivers near the pickup point.
List<RawanaMapMarker> buildNearbyDriverMarkers(
  List<NearbyDriver> drivers, {
  VehicleKind vehicleKind = VehicleKind.car,
}) {
  return drivers
      .map(
        (d) => RawanaMapMarker(
          id: 'nearby_${d.driverId}',
          lat: d.lat,
          lng: d.lng,
          icon: vehicleKind.mapIcon,
          color: RawanaColors.ink,
          size: 40,
          heading: usableHeading(d.heading),
          vehicleKind: vehicleKind,
        ),
      )
      .toList();
}

List<RawanaMapMarker> buildDummyNearbyDriverMarkers({
  required double pickupLat,
  required double pickupLng,
  double? dropoffLat,
  double? dropoffLng,
  VehicleKind vehicleKind = VehicleKind.car,
  AppLocalizations? l10n,
}) {
  final hasDropoff = dropoffLat != null && dropoffLng != null;
  final points = hasDropoff
      ? _dummyPointsAlongRoute(
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          dropoffLat: dropoffLat,
          dropoffLng: dropoffLng,
        )
      : _dummyPointsAroundPickup(pickupLat: pickupLat, pickupLng: pickupLng);
  return points
      .map(
        (point) => RawanaMapMarker.nearbyDriver(
          lat: point.lat,
          lng: point.lng,
          label: l10n?.nearbyDriver,
          vehicleKind: vehicleKind,
        ),
      )
      .toList();
}

/// Device-owner “you are here” pin for home, dashboard, and booking maps.
List<RawanaMapMarker> withCurrentLocationMarker(
  List<RawanaMapMarker> markers, {
  double? lat,
  double? lng,
  String? label,
  AppLocalizations? l10n,
}) {
  if (lat == null || lng == null) return markers;
  if (markers.any((m) => m.id == 'you')) return markers;
  return [
    RawanaMapMarker.you(lat: lat, lng: lng, label: label, l10n: l10n),
    ...markers,
  ];
}

/// Pickup, drop-off, and nearby driver markers for the booking flow.
List<RawanaMapMarker> buildBookingMapMarkers({
  required double pickupLat,
  required double pickupLng,
  required double dropoffLat,
  required double dropoffLng,
  List<NearbyDriver> nearbyDrivers = const [],
  VehicleKind vehicleKind = VehicleKind.car,
  AppLocalizations? l10n,
}) {
  final driverMarkers =
      buildNearbyDriverMarkers(nearbyDrivers, vehicleKind: vehicleKind);
  return [
    ...driverMarkers,
    ...buildBookingDraftMarkers(
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      l10n: l10n,
    ),
  ];
}

List<({double lat, double lng})> _dummyPointsAlongRoute({
  required double pickupLat,
  required double pickupLng,
  required double dropoffLat,
  required double dropoffLng,
}) {
  final latDelta = dropoffLat - pickupLat;
  final lngDelta = dropoffLng - pickupLng;
  final length = (latDelta.abs() + lngDelta.abs()).clamp(0.001, 0.02);
  final perpendicularLat = -lngDelta / length * 0.00035;
  final perpendicularLng = latDelta / length * 0.00035;
  const progress = [0.18, 0.34, 0.52, 0.70];

  return [
    for (var i = 0; i < progress.length; i++)
      (
        lat:
            pickupLat +
            latDelta * progress[i] +
            (i.isEven ? perpendicularLat : -perpendicularLat),
        lng:
            pickupLng +
            lngDelta * progress[i] +
            (i.isEven ? perpendicularLng : -perpendicularLng),
      ),
  ];
}

List<({double lat, double lng})> _dummyPointsAroundPickup({
  required double pickupLat,
  required double pickupLng,
}) {
  const offsets = [
    (lat: 0.00055, lng: -0.00110),
    (lat: -0.00070, lng: 0.00100),
    (lat: 0.00105, lng: 0.00065),
    (lat: -0.00100, lng: -0.00055),
  ];
  return [
    for (final offset in offsets)
      (lat: pickupLat + offset.lat, lng: pickupLng + offset.lng),
  ];
}

bool _nearby(double lat1, double lng1, double lat2, double lng2) {
  final dLat = (lat1 - lat2).abs();
  final dLng = (lng1 - lng2).abs();
  return dLat < 0.0002 && dLng < 0.0002;
}
