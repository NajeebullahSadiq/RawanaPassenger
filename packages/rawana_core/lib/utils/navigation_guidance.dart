import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import '../l10n/app_localizations.dart';
import '../services/maps_service.dart';

const _distance = Distance();

/// Backend and Geolocator use `0` when heading is unknown.
double? usableHeading(double? heading) {
  if (heading == null || heading <= 0 || heading > 360) return null;
  return heading;
}

class NavigationGuidance {
  const NavigationGuidance({
    required this.currentStep,
    required this.stepIndex,
    required this.distanceToManeuverM,
    required this.remainingDistanceKm,
    required this.remainingMinutes,
    required this.bearing,
    required this.offRoute,
    required this.remainingPolyline,
    required this.traveledPolyline,
    required this.snappedLat,
    required this.snappedLng,
  });

  final RouteStep? currentStep;
  final int stepIndex;
  final double distanceToManeuverM;
  final double remainingDistanceKm;
  final int remainingMinutes;
  final double bearing;
  final bool offRoute;
  final List<LatLng> remainingPolyline;
  final List<LatLng> traveledPolyline;
  final double snappedLat;
  final double snappedLng;

  String get instruction =>
      currentStep?.instruction.isNotEmpty == true
          ? currentStep!.instruction
          : 'Continue on the highlighted route';

  String localizedInstruction(AppLocalizations l10n) =>
      currentStep?.instruction.isNotEmpty == true
          ? currentStep!.instruction
          : l10n.continueOnHighlightedRoute;

  String get maneuver => currentStep?.maneuver ?? 'straight';
}

class _SnapResult {
  const _SnapResult({
    required this.point,
    required this.segmentIndex,
    required this.traveledMeters,
    required this.distanceToRouteM,
    required this.bearing,
  });

  final LatLng point;
  final int segmentIndex;
  final double traveledMeters;
  final double distanceToRouteM;
  final double bearing;
}

/// Live turn-by-turn state from a Google/OSRM route and the moving vehicle.
NavigationGuidance computeNavigationGuidance({
  required List<LatLng> route,
  required List<RouteStep> steps,
  required double lat,
  required double lng,
  double? heading,
  required double totalDistanceKm,
  required int totalDurationMinutes,
  double offRouteMeters = 80,
}) {
  final here = LatLng(lat, lng);
  if (route.length < 2) {
    return NavigationGuidance(
      currentStep: steps.isEmpty ? null : steps.first,
      stepIndex: 0,
      distanceToManeuverM: steps.isEmpty ? 0 : steps.first.distanceM,
      remainingDistanceKm: totalDistanceKm,
      remainingMinutes: totalDurationMinutes,
      bearing: usableHeading(heading) ?? 0,
      offRoute: false,
      remainingPolyline: route,
      traveledPolyline: const [],
      snappedLat: lat,
      snappedLng: lng,
    );
  }

  final snap = _snapToRoute(here, route);
  final remaining = <LatLng>[
    snap.point,
    ...route.sublist(math.min(snap.segmentIndex + 1, route.length)),
  ];
  final traveled = <LatLng>[
    ...route.sublist(0, math.min(snap.segmentIndex + 1, route.length)),
    snap.point,
  ];

  final totalM = math.max(1.0, totalDistanceKm * 1000);
  final remainingM = math.max(0.0, totalM - snap.traveledMeters);
  final remainingKm = remainingM / 1000;
  final remainingMin = totalDurationMinutes <= 0
      ? 1
      : math.max(1, (totalDurationMinutes * (remainingM / totalM)).round());

  final stepState = _stepForProgress(
    steps: steps,
    traveledMeters: snap.traveledMeters,
    remainingMeters: remainingM,
  );

  return NavigationGuidance(
    currentStep: stepState.step,
    stepIndex: stepState.index,
    distanceToManeuverM: stepState.distanceToManeuverM,
    remainingDistanceKm: remainingKm,
    remainingMinutes: remainingMin,
    bearing: usableHeading(heading) ?? snap.bearing,
    offRoute: snap.distanceToRouteM >= offRouteMeters,
    remainingPolyline: remaining.length >= 2 ? remaining : route,
    traveledPolyline: traveled,
    snappedLat: snap.point.latitude,
    snappedLng: snap.point.longitude,
  );
}

({RouteStep? step, int index, double distanceToManeuverM}) _stepForProgress({
  required List<RouteStep> steps,
  required double traveledMeters,
  required double remainingMeters,
}) {
  if (steps.isEmpty) {
    return (step: null, index: 0, distanceToManeuverM: remainingMeters);
  }

  var cumulative = 0.0;
  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    cumulative += math.max(0.0, step.distanceM);
    final remainingOnStep = cumulative - traveledMeters;
    if (remainingOnStep > 0 || i == steps.length - 1) {
      return (
        step: step,
        index: i,
        distanceToManeuverM: math.max(0, remainingOnStep),
      );
    }
  }

  return (
    step: steps.last,
    index: steps.length - 1,
    distanceToManeuverM: 0,
  );
}

_SnapResult _snapToRoute(LatLng here, List<LatLng> route) {
  var bestDistance = double.infinity;
  var bestPoint = route.first;
  var bestIndex = 0;
  var bestTraveled = 0.0;
  var bestBearing = _bearing(route.first, route[1]);
  var traveledBefore = 0.0;

  for (var i = 0; i < route.length - 1; i++) {
    final a = route[i];
    final b = route[i + 1];
    final projected = _projectOnSegment(here, a, b);
    final meters = _distance.as(LengthUnit.Meter, here, projected.point);
    if (meters < bestDistance) {
      bestDistance = meters;
      bestPoint = projected.point;
      bestIndex = i;
      bestTraveled = traveledBefore + projected.alongMeters;
      bestBearing = _bearing(a, b);
    }
    traveledBefore += _distance.as(LengthUnit.Meter, a, b);
  }

  return _SnapResult(
    point: bestPoint,
    segmentIndex: bestIndex,
    traveledMeters: bestTraveled,
    distanceToRouteM: bestDistance,
    bearing: bestBearing,
  );
}

({LatLng point, double alongMeters}) _projectOnSegment(
  LatLng p,
  LatLng a,
  LatLng b,
) {
  final scale = math.cos(a.latitude * math.pi / 180).clamp(0.2, 1.0);
  final ax = a.longitude * scale;
  final ay = a.latitude;
  final bx = b.longitude * scale;
  final by = b.latitude;
  final px = p.longitude * scale;
  final py = p.latitude;
  final dx = bx - ax;
  final dy = by - ay;
  final length2 = dx * dx + dy * dy;
  if (length2 < 1e-18) {
    return (point: a, alongMeters: 0);
  }
  var t = ((px - ax) * dx + (py - ay) * dy) / length2;
  t = t.clamp(0.0, 1.0);
  final point = LatLng(ay + t * dy, a.longitude + t * (b.longitude - a.longitude));
  return (
    point: point,
    alongMeters: _distance.as(LengthUnit.Meter, a, point),
  );
}

double _bearing(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLng = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}
