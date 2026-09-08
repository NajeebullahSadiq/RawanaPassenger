import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../models/booking_errors.dart';
import '../models/trip.dart';
import '../theme/rawana_theme.dart';

/// What the driver should read when a trip they were on is cancelled.
String driverCancellationMessage(AppLocalizations l10n, Trip trip) {
  switch (trip.cancelledBy) {
    case 'passenger':
      return l10n.rideCancelledByPassenger;
    case 'admin':
      return l10n.rideCancelledBySupport;
    default:
      return l10n.rideCancelled;
  }
}

/// What the passenger should read when their trip is cancelled by someone else.
String passengerCancellationMessage(AppLocalizations l10n, Trip trip) {
  if (trip.cancelledForNoDrivers) return l10n.rideCancelledNoDrivers;
  switch (trip.cancelledBy) {
    case 'driver':
      return l10n.rideCancelledByDriver;
    case 'admin':
      return l10n.rideCancelledBySupport;
    default:
      return l10n.rideCancelledGeneric;
  }
}

/// Seconds the passenger can still cancel free of charge, using the server's
/// policy (grace window + server clock) rather than a hard-coded 120s.
int freeCancelSecondsRemaining(Trip trip, CancellationPolicy? policy, DateTime policyFetchedAt) {
  if (policy == null) return 0;
  if (!policy.feeApplies && policy.graceSecondsRemaining <= 0 && policy.graceSeconds <= 0) return 0;
  final elapsedSinceFetch = DateTime.now().difference(policyFetchedAt).inSeconds;
  return (policy.graceSecondsRemaining - elapsedSinceFetch).clamp(0, policy.graceSeconds);
}

bool isDriverBusyForMatching(Trip? trip) {
  if (trip == null) return false;
  if (trip.status.isActive && trip.status != TripStatus.searching) return true;
  return trip.status == TripStatus.completed && trip.cashCollectedAt == null;
}

int offerSecondsRemaining(Trip trip) {
  final expires = trip.offerExpiresAt;
  if (expires == null) return 0;
  final server = trip.serverTime;
  if (server != null) {
    final skew = DateTime.now().difference(server);
    return expires.add(skew).difference(DateTime.now()).inSeconds.clamp(0, 180);
  }
  return expires.toLocal().difference(DateTime.now()).inSeconds.clamp(0, 180);
}

int? metersBetween(
  double? lat1,
  double? lng1,
  double? lat2,
  double? lng2,
) {
  if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) return null;
  const earthM = 6371000.0;
  double toRad(double d) => d * math.pi / 180;
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRad(lat1)) *
          math.cos(toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return (2 * earthM * math.asin(math.sqrt(a.clamp(0, 1)))).round();
}

/// Explains a proximity rejection to the driver. In production the server never
/// accepts an override, so this must always give feedback instead of silently
/// doing nothing when the driver taps "I've arrived" / "Complete trip".
String proximityErrorMessage(BuildContext context, ProximityRequiredException error) {
  final l10n = context.l10n;
  final distance = '${error.distanceMeters ?? 0}';
  final required = '${error.requiredMeters ?? (error.messageKey == 'too_far_from_dropoff' ? 300 : 200)}';
  return error.messageKey == 'too_far_from_dropoff'
      ? l10n.tooFarFromDropoff(distance, required)
      : l10n.tooFarFromPickup(distance, required);
}

/// Returns true only when the driver explicitly chose to override in a dev
/// build. In production it shows the distance message and returns false.
Future<bool> confirmProximityOverride(
  BuildContext context,
  ProximityRequiredException error,
) async {
  if (!AppConfig.devModeHint) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(proximityErrorMessage(context, error))),
    );
    return false;
  }
  final l10n = context.l10n;
  final distance = '${error.distanceMeters ?? 0}';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.continueAnyway),
      content: Text(l10n.tooFarContinueAnyway(distance)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.keepDriving),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            l10n.continueAnyway,
            style: const TextStyle(color: RawanaColors.primary),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}
