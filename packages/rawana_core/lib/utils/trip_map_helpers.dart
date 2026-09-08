import '../models/trip.dart';

/// Route endpoints for the live trip map.
///
/// - [TripStatus.accepted]: driver → pickup
/// - [TripStatus.driverArriving] (arrived / waiting): pickup → dropoff preview
/// - [TripStatus.tripStarted]: driver → dropoff
/// - [TripStatus.searching]: pickup → dropoff
({double originLat, double originLng, double destLat, double destLng})? resolveTripRouteEndpoints({
  required TripStatus status,
  double? driverLat,
  double? driverLng,
  double? pickupLat,
  double? pickupLng,
  double? dropoffLat,
  double? dropoffLng,
}) {
  final hasPickup = pickupLat != null && pickupLng != null;
  final hasDropoff = dropoffLat != null && dropoffLng != null;
  final hasDriver = driverLat != null && driverLng != null;

  if (status == TripStatus.tripStarted && hasDropoff) {
    if (hasDriver) {
      return (
        originLat: driverLat,
        originLng: driverLng,
        destLat: dropoffLat,
        destLng: dropoffLng,
      );
    }
    if (hasPickup) {
      return (
        originLat: pickupLat,
        originLng: pickupLng,
        destLat: dropoffLat,
        destLng: dropoffLng,
      );
    }
  }

  if (status == TripStatus.accepted && hasDriver && hasPickup) {
    return (
      originLat: driverLat,
      originLng: driverLng,
      destLat: pickupLat,
      destLng: pickupLng,
    );
  }

  // Waiting at pickup: show the upcoming trip, never the inbound approach.
  if (status == TripStatus.driverArriving && hasPickup && hasDropoff) {
    return (
      originLat: pickupLat,
      originLng: pickupLng,
      destLat: dropoffLat,
      destLng: dropoffLng,
    );
  }

  if (status == TripStatus.searching && hasPickup && hasDropoff) {
    return (
      originLat: pickupLat,
      originLng: pickupLng,
      destLat: dropoffLat,
      destLng: dropoffLng,
    );
  }

  if (hasPickup &&
      hasDropoff &&
      status != TripStatus.accepted) {
    return (
      originLat: pickupLat,
      originLng: pickupLng,
      destLat: dropoffLat,
      destLng: dropoffLng,
    );
  }

  return null;
}

bool isTripHeadingToDropoff(TripStatus status) => status == TripStatus.tripStarted;

/// Passenger map follows the assigned driver. Never substitutes passenger GPS
/// as the driver origin.
({double originLat, double originLng, double destLat, double destLng})?
resolvePassengerNavigationEndpoints({
  required TripStatus status,
  double? passengerLat,
  double? passengerLng,
  double? driverLat,
  double? driverLng,
  double? pickupLat,
  double? pickupLng,
  double? dropoffLat,
  double? dropoffLng,
}) {
  return resolveTripRouteEndpoints(
    status: status,
    driverLat: driverLat,
    driverLng: driverLng,
    pickupLat: pickupLat,
    pickupLng: pickupLng,
    dropoffLat: dropoffLat,
    dropoffLng: dropoffLng,
  );
}
