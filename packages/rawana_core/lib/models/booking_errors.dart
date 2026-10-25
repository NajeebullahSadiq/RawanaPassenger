import 'dart:convert';

class ProximityRequiredException implements Exception {
  const ProximityRequiredException({
    required this.messageKey,
    this.distanceMeters,
    this.requiredMeters,
  });

  final String messageKey;
  final int? distanceMeters;
  final int? requiredMeters;
}

ProximityRequiredException? proximityFromResponse(int? status, Object? data) {
  var map = <String, dynamic>{};
  if (data is Map) {
    map = Map<String, dynamic>.from(data);
  } else if (data is String && data.isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) map = Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  final key = map['message_key'] as String?;
  if (status == 409 ||
      key == 'too_far_from_dropoff' ||
      key == 'too_far_from_pickup' ||
      key == 'too_far') {
    return ProximityRequiredException(
      messageKey: key ?? 'too_far',
      distanceMeters: (map['distance_meters'] as num?)?.round(),
      requiredMeters: (map['required_meters'] as num?)?.round(),
    );
  }
  return null;
}

/// Thrown by `TripService.requestRide` when the passenger already has a live
/// trip; the app should resume that trip instead of showing an error.
class ActiveTripExistsException implements Exception {
  const ActiveTripExistsException({required this.tripId, this.status});

  final String tripId;
  final String? status;
}

/// Thrown by `TripService.requestRide` when the price went up since the quote
/// (e.g. surge). Nothing was booked; ask the passenger to accept the new price.
class FareChangedException implements Exception {
  const FareChangedException({
    required this.cashToCollect,
    required this.expectedCash,
  });

  final int cashToCollect;
  final int expectedCash;
}

/// Result of completing a ride under the cash-first model.
class CompletedRide {
  const CompletedRide({
    required this.finalFare,
    required this.rideFare,
    required this.outstandingFee,
    required this.commission,
    required this.netEarning,
    this.walletBalance,
  });

  /// Total cash the passenger hands over (ride + any outstanding fee).
  final int finalFare;
  /// Ride price only — the base for commission.
  final int rideFare;
  /// Old cancellation fee collected on Rawana's behalf.
  final int outstandingFee;
  /// Commission now owed to Rawana for this ride.
  final int commission;
  /// Cash the driver keeps: rideFare − commission.
  final int netEarning;
  /// Driver balance with Rawana after this ride (negative = owed).
  final int? walletBalance;

  factory CompletedRide.fromJson(Map<String, dynamic> json) {
    final finalFare = (json['finalFare'] as num?)?.round() ?? 0;
    final outstanding = (json['outstandingFee'] as num?)?.round() ?? 0;
    final commission = (json['commission'] as num?)?.round() ?? 0;
    final rideFare = (json['rideFare'] as num?)?.round() ?? (finalFare - outstanding);
    return CompletedRide(
      finalFare: finalFare,
      rideFare: rideFare,
      outstandingFee: outstanding,
      commission: commission,
      netEarning: (json['netEarning'] as num?)?.round() ?? (rideFare - commission),
      walletBalance: (json['walletBalance'] as num?)?.round(),
    );
  }
}

class CancellationPolicy {
  const CancellationPolicy({
    required this.feeApplies,
    required this.cancellationFee,
    this.noShowEligible = false,
    this.graceSeconds = 120,
    this.graceSecondsRemaining = 0,
    this.riderWaitGraceSeconds = 120,
    this.riderNoShowSeconds = 420,
    this.noShowWaitSeconds = 540,
    this.noShowSecondsRemaining = 540,
    this.fetchedAt,
    this.freeCancelUntil,
  });

  final bool feeApplies;
  final int cancellationFee;
  /// Driver may cancel without a fee because the rider never showed up.
  final bool noShowEligible;
  /// Passenger free-cancel window after the driver accepted.
  final int graceSeconds;
  final int graceSecondsRemaining;
  /// Free wait at pickup before the no-show window starts (admin setting).
  final int riderWaitGraceSeconds;
  /// Extra wait after the grace period before a fee-free driver cancel.
  final int riderNoShowSeconds;
  /// `riderWaitGraceSeconds + riderNoShowSeconds`.
  final int noShowWaitSeconds;
  final int noShowSecondsRemaining;
  /// Local time the policy was fetched — for client-side countdowns.
  final DateTime? fetchedAt;
  /// Scheduled rides only: last moment the passenger can cancel for free.
  final DateTime? freeCancelUntil;

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    final grace = (json['rider_wait_grace_seconds'] as num?)?.round() ?? 120;
    final noShow = (json['rider_no_show_seconds'] as num?)?.round() ?? 420;
    final total = (json['no_show_wait_seconds'] as num?)?.round() ?? (grace + noShow);
    return CancellationPolicy(
      feeApplies: json['fee_applies'] == true,
      cancellationFee: (json['cancellation_fee'] as num?)?.round() ?? 0,
      noShowEligible: json['no_show_eligible'] == true,
      graceSeconds: (json['grace_seconds'] as num?)?.round() ?? 120,
      graceSecondsRemaining:
          (json['grace_seconds_remaining'] as num?)?.round() ??
              (json['grace_seconds'] as num?)?.round() ??
              0,
      riderWaitGraceSeconds: grace,
      riderNoShowSeconds: noShow,
      noShowWaitSeconds: total,
      noShowSecondsRemaining: (json['no_show_seconds_remaining'] as num?)?.round() ?? total,
      fetchedAt: DateTime.now(),
      freeCancelUntil: DateTime.tryParse(json['free_cancel_until'] as String? ?? ''),
    );
  }

  int _elapsedSinceFetch() =>
      fetchedAt == null ? 0 : DateTime.now().difference(fetchedAt!).inSeconds;

  /// Live no-show countdown (seconds) derived from the server snapshot.
  int get liveNoShowSecondsRemaining =>
      (noShowSecondsRemaining - _elapsedSinceFetch()).clamp(0, noShowWaitSeconds);

  /// Seconds the driver has waited so far at the pickup point.
  int get liveWaitedSeconds => noShowWaitSeconds - liveNoShowSecondsRemaining;

  bool get liveInGraceWait => liveWaitedSeconds < riderWaitGraceSeconds;

  bool get liveCanCancelWithoutFee => noShowEligible || liveNoShowSecondsRemaining <= 0;
}
