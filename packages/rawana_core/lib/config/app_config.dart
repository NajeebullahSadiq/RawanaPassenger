import 'package:flutter/foundation.dart';

/// Build-time configuration from `--dart-define` / `--dart-define-from-file`
/// (for example `flutter run --dart-define-from-file=.env` or
/// `flutter build appbundle --dart-define-from-file=env/prod.json`).
///
/// Nothing is bundled as an asset, so release binaries carry only the values
/// compiled into them.
class AppConfig {
  AppConfig._();

  /// `dev` or `prod`. Defaults to `prod` for release builds.
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: kReleaseMode ? 'prod' : 'dev');

  static bool get isProduction => appEnv == 'prod';

  /// Debug builds and explicit dev builds may expose testing shortcuts.
  static bool get allowsDevTools => kDebugMode || !isProduction;

  static String get apiBaseUrl => _normalizeApiUrl(
        const String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:7000/api'),
      );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Browser key for Flutter web (`Maps JavaScript API`). Falls back to [googleMapsApiKey].
  /// Use a separate key restricted to HTTP referrers (localhost) — Android keys block web.
  static String get googleMapsWebApiKey {
    const webKey = String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY');
    return webKey.isNotEmpty ? webKey : googleMapsApiKey;
  }

  /// When true, show email/password auth first (testing before OTP providers are live).
  static const bool useEmailAuthForTesting = bool.fromEnvironment('USE_EMAIL_AUTH', defaultValue: true);

  /// Enable phone OTP screens (SMS + WhatsApp).
  static const bool enablePhoneOtp = bool.fromEnvironment('ENABLE_PHONE_OTP');

  /// Show dev OTP hints in UI. Never in production release builds.
  static bool get devModeHint => allowsDevTools && const bool.fromEnvironment('DEV_MODE_HINT');

  /// Show one-tap demo login on auth screens. Never in production release builds.
  static bool get enableDemoLogin =>
      allowsDevTools &&
      const bool.fromEnvironment('ENABLE_DEMO_LOGIN') &&
      const String.fromEnvironment('DEMO_PASSWORD').isNotEmpty;

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Fails fast when a release build is pointed at an insecure or missing backend.
  static void assertReleaseConfig() {
    if (!kReleaseMode || kIsWeb) return;
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || uri.scheme != 'https') {
      throw StateError('Release builds require an https API_URL (got "$apiBaseUrl").');
    }
    if (!hasSupabase) {
      throw StateError('Release builds require SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
  }

  /// Android emulators cannot reach the host machine via `localhost`.
  static String _normalizeApiUrl(String url) {
    if (kIsWeb) return url;
    if (defaultTargetPlatform != TargetPlatform.android) return url;
    return url.replaceFirst('://localhost', '://10.0.2.2').replaceFirst('://127.0.0.1', '://10.0.2.2');
  }
}
