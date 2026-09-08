import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads a `.env` file bundled with the app and exposes its key/value pairs to
/// [AppConfig] at runtime.
///
/// Flutter's `String.fromEnvironment` is **compile-time only** — it only sees
/// values passed via `--dart-define=KEY=VALUE` at build time. Mobile/web `.env`
/// files in `driver_app/` and `passenger_app/` were previously orphaned.
///
/// This loader bridges the gap: call [RawanaEnv.load] once from `main()` before
/// `runApp(...)`, and `AppConfig.*` getters will transparently use the `.env`
/// values when the corresponding `--dart-define` isn't supplied.
class RawanaEnv {
  RawanaEnv._();

  static bool _loaded = false;

  /// Whether [load] has completed successfully at least once.
  static bool get isLoaded => _loaded;

  /// Loads the `.env` asset bundled at [fileName]. Failures are non-fatal
  /// (e.g. when the asset hasn't been added to `pubspec.yaml`); the app simply
  /// falls back to compile-time defines and built-in defaults.
  static Future<void> load({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
      _loaded = true;
    } catch (e) {
      _loaded = false;
      if (kDebugMode) {
        debugPrint(
          '[RawanaEnv] Could not load $fileName: $e\n'
          'Falling back to --dart-define and defaults. '
          'Add the .env file to your pubspec assets to enable runtime config.',
        );
      }
    }
  }

  /// Returns the trimmed value for [key], or `null` when it is unset or empty.
  static String? maybeGet(String key) {
    if (!_loaded) return null;
    final v = dotenv.maybeGet(key)?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
