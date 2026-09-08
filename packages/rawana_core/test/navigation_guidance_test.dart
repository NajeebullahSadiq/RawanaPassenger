import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rawana_core/rawana_core.dart';

void main() {
  final route = [
    const LatLng(34.5553, 69.2075),
    const LatLng(34.5600, 69.2100),
    const LatLng(34.5650, 69.2150),
  ];

  final steps = [
    const RouteStep(
      instruction: 'Head north',
      maneuver: 'straight',
      distanceM: 600,
      durationSeconds: 80,
      startLat: 34.5553,
      startLng: 69.2075,
      endLat: 34.5600,
      endLng: 69.2100,
    ),
    const RouteStep(
      instruction: 'Turn right onto Main Street',
      maneuver: 'turn-right',
      distanceM: 700,
      durationSeconds: 90,
      startLat: 34.5600,
      startLng: 69.2100,
      endLat: 34.5650,
      endLng: 69.2150,
    ),
  ];

  test('snaps the moving vehicle onto the route and keeps remaining path', () {
    final guidance = computeNavigationGuidance(
      route: route,
      steps: steps,
      lat: 34.5554,
      lng: 69.2076,
      totalDistanceKm: 1.3,
      totalDurationMinutes: 6,
    );

    expect(guidance.offRoute, isFalse);
    expect(guidance.remainingPolyline.length, greaterThanOrEqualTo(2));
    expect(guidance.instruction, isNotEmpty);
    expect(guidance.remainingDistanceKm, greaterThan(0));
  });

  test('marks the vehicle off-route when far from the polyline', () {
    final guidance = computeNavigationGuidance(
      route: route,
      steps: steps,
      lat: 34.6000,
      lng: 69.3000,
      totalDistanceKm: 1.3,
      totalDurationMinutes: 6,
      offRouteMeters: 80,
    );

    expect(guidance.offRoute, isTrue);
  });

  test('maps ride type icons to vehicle kinds', () {
    expect(VehicleKind.fromIconName('bike'), VehicleKind.bike);
    expect(VehicleKind.fromIconName('premium'), VehicleKind.premium);
    expect(VehicleKind.fromIconName('xl'), VehicleKind.xl);
    expect(VehicleKind.fromIconName('car'), VehicleKind.car);
  });

  test('passenger navigation uses the driver-to-target route', () {
    final route = resolvePassengerNavigationEndpoints(
      status: TripStatus.accepted,
      passengerLat: 34.55,
      passengerLng: 69.20,
      driverLat: 34.56,
      driverLng: 69.21,
      pickupLat: 34.55,
      pickupLng: 69.20,
      dropoffLat: 34.57,
      dropoffLng: 69.22,
    );

    expect(route, isNotNull);
    expect(route!.originLat, 34.56);
    expect(route.originLng, 69.21);
    expect(route.destLat, 34.55);
    expect(route.destLng, 69.20);
  });

  test('usableHeading treats 0 and negatives as unknown', () {
    expect(usableHeading(null), isNull);
    expect(usableHeading(0), isNull);
    expect(usableHeading(-1), isNull);
    expect(usableHeading(361), isNull);
    expect(usableHeading(90), 90);
  });

  test('accepted inbound route requires real driver coordinates', () {
    final route = resolveTripRouteEndpoints(
      status: TripStatus.accepted,
      pickupLat: 34.55,
      pickupLng: 69.20,
      dropoffLat: 34.57,
      dropoffLng: 69.22,
    );

    expect(route, isNull);
  });

  test('arrived waiting route previews pickup to drop-off, not inbound', () {
    final route = resolveTripRouteEndpoints(
      status: TripStatus.driverArriving,
      driverLat: 34.5501,
      driverLng: 69.2001,
      pickupLat: 34.55,
      pickupLng: 69.20,
      dropoffLat: 34.57,
      dropoffLng: 69.22,
    );

    expect(route, isNotNull);
    expect(route!.originLat, 34.55);
    expect(route.originLng, 69.20);
    expect(route.destLat, 34.57);
    expect(route.destLng, 69.22);
  });

  test('searching preview uses the booked pickup to drop-off', () {
    final route = resolveTripRouteEndpoints(
      status: TripStatus.searching,
      pickupLat: 34.55,
      pickupLng: 69.20,
      dropoffLat: 34.57,
      dropoffLng: 69.22,
    );

    expect(route, isNotNull);
    expect(route!.originLat, 34.55);
    expect(route.destLat, 34.57);
  });

  test('metersBetween measures dropoff distance', () {
    expect(metersBetween(34.5553, 69.2075, 34.5553, 69.2075), 0);
    expect(metersBetween(34.5553, 69.2075, 34.6750, 69.2075), greaterThan(10000));
  });

  test('offer countdown is zero when the server sent no expiry', () {
    const trip = Trip(
      id: 'trip-1',
      status: TripStatus.searching,
      pickupAddress: 'A',
      dropoffAddress: 'B',
    );
    expect(offerSecondsRemaining(trip), 0);
    expect(isDriverBusyForMatching(trip), isFalse);
  });

  test('driver stays busy until cash is collected', () {
    const unpaid = Trip(
      id: 'trip-1',
      status: TripStatus.completed,
      pickupAddress: 'A',
      dropoffAddress: 'B',
    );
    expect(isDriverBusyForMatching(unpaid), isTrue);
    expect(
      isDriverBusyForMatching(
        Trip(
          id: 'trip-2',
          status: TripStatus.completed,
          pickupAddress: 'A',
          dropoffAddress: 'B',
          cashCollectedAt: DateTime.utc(2026, 9, 6),
        ),
      ),
      isFalse,
    );
  });

  test('fare estimate cash amount includes tax', () {
    final fare = FareEstimate.fromJson({
      'estimated_fare': 100,
      'base_fare': 50,
      'distance_km': 2,
      'duration_minutes': 8,
      'tax_amount': 10,
    });
    expect(fare.cashToCollect, 110);
  });

  test('parses GeoJSON pickup points', () {
    final trip = Trip.fromJson({
      'id': 'trip-1',
      'status': 'accepted',
      'pickup_address': 'A',
      'dropoff_address': 'B',
      'pickup_location': {
        'type': 'Point',
        'coordinates': [69.2075, 34.5553],
      },
      'dropoff_location': {
        'type': 'Point',
        'coordinates': [69.22, 34.57],
      },
    });

    expect(trip.pickupLat, closeTo(34.5553, 0.0001));
    expect(trip.pickupLng, closeTo(69.2075, 0.0001));
    expect(trip.dropoffLat, closeTo(34.57, 0.0001));
    expect(trip.dropoffLng, closeTo(69.22, 0.0001));
  });
}
