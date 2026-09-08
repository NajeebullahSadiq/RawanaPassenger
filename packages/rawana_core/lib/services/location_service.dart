import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constants.dart';

class LocationService {
  static Future<bool> ensurePermission({bool openSettingsIfDeniedForever = false}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (openSettingsIfDeniedForever) {
        await Geolocator.openAppSettings();
      }
      return false;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Returns the device's current coordinates, or `null` if permission was
  /// denied, the location service is disabled, or the fix could not be
  /// acquired within a reasonable time. Never throws.
  static Future<({double lat, double lng})?> getCurrentPosition() async {
    try {
      final ok = await ensurePermission();
      if (!ok) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition: $e');
      return null;
    }
  }

  static Future<({double lat, double lng})?> getLastKnownPosition() async {
    try {
      final ok = await ensurePermission();
      if (!ok) return null;
      final pos = await Geolocator.getLastKnownPosition();
      if (pos == null) return null;
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (e) {
      debugPrint('[LocationService] getLastKnownPosition: $e');
      return null;
    }
  }

  /// Fast GPS for going online — last known first, then a short current fix.
  static Future<({double lat, double lng})?> resolvePositionForGoingOnline() async {
    final last = await getLastKnownPosition();
    if (last != null && (!kDebugMode || _isNearKabul(last.lat, last.lng))) {
      return last;
    }

    try {
      final ok = await ensurePermission();
      if (ok) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );
        final current = (lat: pos.latitude, lng: pos.longitude);
        if (!kDebugMode || _isNearKabul(current.lat, current.lng)) {
          return current;
        }
      }
    } catch (e) {
      debugPrint('[LocationService] resolvePositionForGoingOnline: $e');
    }

    if (last != null) return last;
    if (kDebugMode) {
      debugPrint(
        '[LocationService] Using Kabul debug coordinates for going online.',
      );
      return (lat: RawanaConstants.kabulLat, lng: RawanaConstants.kabulLng);
    }
    return null;
  }

  /// GPS for ride matching. In debug builds, falls back to Kabul when GPS is
  /// unavailable or far away (common on Android/iOS simulators).
  static Future<({double lat, double lng})?> resolvePositionForRideMatching() async {
    final last = await getLastKnownPosition();
    if (last != null && _isNearKabul(last.lat, last.lng)) return last;
    final pos = await getCurrentPosition();
    if (pos != null && _isNearKabul(pos.lat, pos.lng)) return pos;
    if (kDebugMode) {
      debugPrint(
        '[LocationService] Using Kabul debug coordinates for ride matching '
        '(emulator GPS is often outside Afghanistan).',
      );
      return (lat: RawanaConstants.kabulLat, lng: RawanaConstants.kabulLng);
    }
    return pos ?? last;
  }

  static bool _isNearKabul(double lat, double lng) {
    return (lat - RawanaConstants.kabulLat).abs() < 2 &&
        (lng - RawanaConstants.kabulLng).abs() < 2;
  }

  static Stream<Position> positionStream({bool navigation = false}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: navigation
              ? LocationAccuracy.bestForNavigation
              : LocationAccuracy.high,
          distanceFilter: navigation ? 2 : 5,
        ),
      );
}
