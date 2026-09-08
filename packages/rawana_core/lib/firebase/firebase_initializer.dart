import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase when options or platform config files are available.
///
/// Behaviour by platform:
/// - **Web**: requires explicit [options] (no auto-discovery on the web). If
///   none are provided we skip silently — push notifications simply won't be
///   available, which is expected during local web testing.
/// - **Android / iOS**: when [options] is null, Firebase auto-discovers
///   `google-services.json` / `GoogleService-Info.plist`.
Future<bool> initializeFirebaseApp({FirebaseOptions? options}) async {
  if (Firebase.apps.isNotEmpty) return true;
  if (options == null && kIsWeb) {
    if (kDebugMode) {
      debugPrint(
        '[FirebaseInitializer] Skipping Firebase on web — no FirebaseOptions '
        'provided. Push notifications will be unavailable.',
      );
    }
    return false;
  }
  try {
    if (options != null) {
      await Firebase.initializeApp(options: options);
    } else {
      await Firebase.initializeApp();
    }
    return true;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[FirebaseInitializer] failed ($e)');
    }
    return false;
  }
}

/// Background FCM handler helper — pass the same [options] as the main isolate.
Future<void> initializeFirebaseForBackground(FirebaseOptions? options) async {
  if (Firebase.apps.isNotEmpty) return;
  if (options == null && kIsWeb) return;
  if (options != null) {
    await Firebase.initializeApp(options: options);
    return;
  }
  await Firebase.initializeApp();
}
