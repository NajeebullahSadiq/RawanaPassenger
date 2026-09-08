import 'package:flutter/foundation.dart';
import 'rawana_env.dart';

/// Runtime configuration sourced (in priority order) from:
///
///   1. `--dart-define=KEY=VALUE` flags (compile-time, highest priority)
///   2. The app's bundled `.env` file (loaded via [RawanaEnv.load] in `main`)
///   3. The built-in default specified per field
///
/// All fields are `static` getters so [RawanaEnv.load] can be invoked once at
/// startup and every subsequent read picks up the freshest value.
class AppConfig {
  AppConfig._();

  // ─── Strings ────────────────────────────────────────────────────────────

  static String get apiBaseUrl => _normalizeApiUrl(
        _envString('API_URL', _apiUrlDefine, _hasApiUrlDefine, 'http://10.0.2.2:7000/api'),
      );

  static String get supabaseUrl =>
      _envString('SUPABASE_URL', _supabaseUrlDefine, _hasSupabaseUrlDefine, '');

  static String get supabaseAnonKey =>
      _envString('SUPABASE_ANON_KEY', _supabaseAnonKeyDefine, _hasSupabaseAnonKeyDefine, '');

  static String get defaultAuthRole =>
      _envString('AUTH_ROLE', _authRoleDefine, _hasAuthRoleDefine, 'passenger');

  static String get googleMapsApiKey => _envString(
        'GOOGLE_MAPS_API_KEY',
        _googleMapsApiKeyDefine,
        _hasGoogleMapsApiKeyDefine,
        '',
      );

  /// Browser key for Flutter web (`Maps JavaScript API`). Falls back to [googleMapsApiKey].
  /// Use a separate key restricted to HTTP referrers (localhost) — Android keys block web.
  static String get googleMapsWebApiKey {
    final webKey = _envString(
      'GOOGLE_MAPS_WEB_API_KEY',
      _googleMapsWebApiKeyDefine,
      _hasGoogleMapsWebApiKeyDefine,
      '',
    );
    if (webKey.isNotEmpty) return webKey;
    return googleMapsApiKey;
  }

  // ─── Bools ──────────────────────────────────────────────────────────────

  /// When true, show email/password auth first (testing before OTP providers are live).
  static bool get useEmailAuthForTesting => _envBool(
        'USE_EMAIL_AUTH',
        _useEmailAuthDefine,
        _hasUseEmailAuthDefine,
        true,
      );

  /// Enable phone OTP screens (SMS + WhatsApp).
  static bool get enablePhoneOtp =>
      _envBool('ENABLE_PHONE_OTP', _enablePhoneOtpDefine, _hasEnablePhoneOtpDefine, false);

  /// Show dev OTP hints in UI.
  static bool get devModeHint =>
      _envBool('DEV_MODE_HINT', _devModeHintDefine, _hasDevModeHintDefine, false);

  /// Show one-tap demo login on auth screens.
  static bool get enableDemoLogin =>
      _envBool('ENABLE_DEMO_LOGIN', _enableDemoLoginDefine, _hasEnableDemoLoginDefine, false);

  // ─── Derived ────────────────────────────────────────────────────────────

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ─── Internal helpers ──────────────────────────────────────────────────

  static String _envString(
    String key,
    String defineValue,
    bool hasDefine,
    String fallback,
  ) {
    if (hasDefine) return defineValue;
    final fromDotenv = RawanaEnv.maybeGet(key);
    if (fromDotenv != null) return fromDotenv;
    return fallback;
  }

  static bool _envBool(
    String key,
    bool defineValue,
    bool hasDefine,
    bool fallback,
  ) {
    if (hasDefine) return defineValue;
    final raw = RawanaEnv.maybeGet(key);
    if (raw == null) return fallback;
    final v = raw.toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
    return fallback;
  }

  /// Android emulators cannot reach the host machine via `localhost`.
  static String _normalizeApiUrl(String url) {
    if (kIsWeb) return url;
    if (defaultTargetPlatform != TargetPlatform.android) return url;
    return url
        .replaceFirst('://localhost', '://10.0.2.2')
        .replaceFirst('://127.0.0.1', '://10.0.2.2');
  }

  // ─── Compile-time defines (read once at build time) ────────────────────

  static const _hasApiUrlDefine = bool.hasEnvironment('API_URL');
  static const _apiUrlDefine = String.fromEnvironment('API_URL');

  static const _hasSupabaseUrlDefine = bool.hasEnvironment('SUPABASE_URL');
  static const _supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');

  static const _hasSupabaseAnonKeyDefine = bool.hasEnvironment('SUPABASE_ANON_KEY');
  static const _supabaseAnonKeyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const _hasAuthRoleDefine = bool.hasEnvironment('AUTH_ROLE');
  static const _authRoleDefine = String.fromEnvironment('AUTH_ROLE');

  static const _hasGoogleMapsApiKeyDefine = bool.hasEnvironment('GOOGLE_MAPS_API_KEY');
  static const _googleMapsApiKeyDefine = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const _hasGoogleMapsWebApiKeyDefine = bool.hasEnvironment('GOOGLE_MAPS_WEB_API_KEY');
  static const _googleMapsWebApiKeyDefine = String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY');

  static const _hasUseEmailAuthDefine = bool.hasEnvironment('USE_EMAIL_AUTH');
  static const _useEmailAuthDefine = bool.fromEnvironment('USE_EMAIL_AUTH');

  static const _hasEnablePhoneOtpDefine = bool.hasEnvironment('ENABLE_PHONE_OTP');
  static const _enablePhoneOtpDefine = bool.fromEnvironment('ENABLE_PHONE_OTP');

  static const _hasDevModeHintDefine = bool.hasEnvironment('DEV_MODE_HINT');
  static const _devModeHintDefine = bool.fromEnvironment('DEV_MODE_HINT');

  static const _hasEnableDemoLoginDefine = bool.hasEnvironment('ENABLE_DEMO_LOGIN');
  static const _enableDemoLoginDefine = bool.fromEnvironment('ENABLE_DEMO_LOGIN');
}
