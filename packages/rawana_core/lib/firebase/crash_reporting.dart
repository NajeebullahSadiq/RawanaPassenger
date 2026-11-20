import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_exception.dart';
import '../models/booking_errors.dart';

/// Crashlytics wrapper. Collects only in non-debug builds where Firebase is
/// configured; everywhere else errors are just printed.
class CrashReporting {
  CrashReporting._();

  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  /// Call once after Firebase initialisation, before `runApp`.
  static Future<void> install({required bool firebaseReady}) async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (_enabled) unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, fatal: true);
      return true;
    };
    if (!firebaseReady || kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      _enabled = !kDebugMode;
    } catch (e) {
      debugPrint('[CrashReporting] disabled: $e');
    }
  }

  static void record(Object error, StackTrace? stack, {bool fatal = false, String? reason}) {
    if (kDebugMode) debugPrint('[CrashReporting] ${reason ?? ''} $error\n$stack');
    if (!_enabled) return;
    unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal, reason: reason));
  }

  /// Reports errors the user can't explain away (bugs), skipping expected
  /// network, auth and booking-rule failures.
  static void recordIfUnexpected(Object error, [StackTrace? stack]) {
    if (error is DioException ||
        error is RawanaAuthException ||
        error is ProximityRequiredException ||
        error is ActiveTripExistsException ||
        error is FareChangedException ||
        error is StartPinException) {
      return;
    }
    record(error, stack ?? StackTrace.current, reason: 'handled');
  }

  static Future<void> setUser(String? userId) async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
  }
}
