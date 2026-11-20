import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../config/app_config.dart';
import '../api/api_client.dart';
import 'auth_exception.dart';
import 'demo_credentials.dart';
import 'otp_channel.dart';

/// Supabase Auth wrapper — email/password (testing) + phone OTP (SMS & WhatsApp).
class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient;

  final ApiClient? _api;

  sb.SupabaseClient? get _client =>
      AppConfig.hasSupabase ? sb.Supabase.instance.client : null;

  sb.Session? get session => _client?.auth.currentSession;
  sb.User? get currentUser => _client?.auth.currentUser;
  bool get isAuthenticated {
    final s = session;
    if (s == null) return false;
    // Keep the user logged in across app restarts even if the access token
    // expired — splash/bootstrap will refresh it via [ensureValidSession].
    if (!s.isExpired) return true;
    final refresh = s.refreshToken;
    return refresh != null && refresh.isNotEmpty;
  }
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  /// Restores a persisted session and refreshes an expired access token.
  Future<bool> ensureValidSession() async {
    if (_client == null) return false;
    var s = session;
    if (s == null) return false;
    if (!s.isExpired) return true;
    try {
      final res = await _client!.auth.refreshSession();
      return res.session != null;
    } catch (_) {
      return false;
    }
  }

  Stream<sb.AuthState> get authStateChanges {
    if (_client == null) return const Stream.empty();
    return _client!.auth.onAuthStateChange;
  }

  Future<sb.AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _requireSupabase();
    try {
      return await _client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on sb.AuthException catch (e) {
      throw RawanaAuthException(_mapAuthError(e.message), e.message);
    }
  }

  Future<sb.AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String role,
    String? name,
    String? phone,
  }) async {
    _requireSupabase();
    try {
      return await _client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'role': role,
          if (name != null) 'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
    } on sb.AuthException catch (e) {
      throw RawanaAuthException(_mapAuthError(e.message), e.message);
    }
  }

  /// Finishes an email sign-up after the user tapped the confirmation link.
  /// Throws [RawanaAuthException] `email_not_verified` while it is still pending.
  Future<void> completeEmailVerification({String? email, String? password}) async {
    _requireSupabase();
    if (session != null) {
      try {
        await _client!.auth.refreshSession();
      } on sb.AuthException catch (e) {
        throw RawanaAuthException(_mapAuthError(e.message), e.message);
      }
      if (!isEmailVerified) throw RawanaAuthException('email_not_verified');
      return;
    }
    if (email == null || password == null) throw RawanaAuthException('email_not_verified');
    await signInWithEmail(email: email, password: password);
  }

  Future<void> resendEmailVerification(String email) async {
    _requireSupabase();
    await _client!.auth.resend(type: sb.OtpType.signup, email: email.trim());
  }

  Future<void> sendPhoneOtp({
    required String phoneE164,
    required RawanaOtpChannel channel,
  }) async {
    final phone = _normalizeAfPhone(phoneE164);

    if (channel == RawanaOtpChannel.sms) {
      _requireSupabase();
      try {
        await _client!.auth.signInWithOtp(phone: phone);
      } on sb.AuthException catch (e) {
        throw RawanaAuthException(_mapAuthError(e.message), e.message);
      }
      return;
    }

    final api = _api;
    if (api == null) {
      throw RawanaAuthException('whatsapp_api_not_configured');
    }
    await api.post('/auth/otp/send', data: {
      'phone': phone,
      'channel': channel.value,
    });
  }

  Future<sb.AuthResponse> verifyPhoneOtp({
    required String phoneE164,
    required String code,
    required RawanaOtpChannel channel,
  }) async {
    final phone = _normalizeAfPhone(phoneE164);

    if (channel == RawanaOtpChannel.sms) {
      _requireSupabase();
      try {
        return await _client!.auth.verifyOTP(
          type: sb.OtpType.sms,
          phone: phone,
          token: code,
        );
      } on sb.AuthException catch (e) {
        throw RawanaAuthException(_mapAuthError(e.message), e.message);
      }
    }

    final api = _api;
    if (api == null) {
      throw RawanaAuthException('whatsapp_api_not_configured');
    }
    _requireSupabase();
    final result = await api.post('/auth/otp/verify', data: {
      'phone': phone,
      'channel': channel.value,
      'code': code,
      'role': AppConfig.defaultAuthRole,
    });
    final tokenHash = result['token_hash'] as String?;
    if (tokenHash == null) {
      throw RawanaAuthException('invalid_otp');
    }
    return await _client!.auth.verifyOTP(
      type: sb.OtpType.magiclink,
      tokenHash: tokenHash,
    );
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  /// SMS reset for an existing phone account. Does not create a user.
  Future<void> sendPhonePasswordReset(String phoneE164) async {
    _requireSupabase();
    final phone = _normalizeAfPhone(phoneE164);
    try {
      await _client!.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );
    } on sb.AuthException catch (e) {
      throw RawanaAuthException(_mapAuthError(e.message), e.message);
    }
  }

  /// Sends an email reset. Returns true when the user should enter a code
  /// in the app, and false when Supabase only emailed a link.
  Future<bool> sendEmailPasswordReset(String email) async {
    _requireSupabase();
    final trimmed = email.trim();
    try {
      await _client!.auth.signInWithOtp(
        email: trimmed,
        shouldCreateUser: false,
      );
      return true;
    } on sb.AuthException {
      try {
        await _client!.auth.resetPasswordForEmail(trimmed);
        return false;
      } on sb.AuthException catch (e) {
        throw RawanaAuthException(_mapAuthError(e.message), e.message);
      }
    }
  }

  Future<void> verifyEmailRecoveryCode({
    required String email,
    required String code,
  }) async {
    _requireSupabase();
    final trimmed = email.trim();
    try {
      await _client!.auth.verifyOTP(
        type: sb.OtpType.email,
        email: trimmed,
        token: code,
      );
      return;
    } on sb.AuthException {
      try {
        await _client!.auth.verifyOTP(
          type: sb.OtpType.recovery,
          email: trimmed,
          token: code,
        );
      } on sb.AuthException catch (e) {
        throw RawanaAuthException(_mapAuthError(e.message), e.message);
      }
    }
  }

  Future<void> updatePassword(String newPassword) async {
    _requireSupabase();
    try {
      await _client!.auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (e) {
      throw RawanaAuthException(_mapAuthError(e.message), e.message);
    }
  }

  String? get accessToken => session?.accessToken;

  void _requireSupabase() {
    if (_client == null) {
      throw RawanaAuthException(
        'supabase_not_configured',
        'Add SUPABASE_URL and SUPABASE_ANON_KEY to run auth.',
      );
    }
  }

  /// Mirrors the backend's `normalizeAfPhone` so both sides derive the same
  /// account identity from `0700…`, `700…`, `+93 700…` or `0093 700…`.
  String _normalizeAfPhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (!digits.startsWith('93')) digits = '93$digits';
    return '+$digits';
  }

  String _mapAuthError(String? message) {
    if (message == null) return 'auth_error';
    final m = message.toLowerCase();
    if (m.contains('invalid login') ||
        m.contains('user not found') ||
        m.contains('signups not allowed')) {
      return 'invalid_credentials';
    }
    if (m.contains('email not confirmed')) return 'email_not_verified';
    if (m.contains('already registered') || m.contains('already been registered') || m.contains('user already exists')) {
      return 'email_already_exists';
    }
    if (m.contains('phone') && (m.contains('already') || m.contains('duplicate') || m.contains('unique'))) {
      return 'phone_already_exists';
    }
    if (m.contains('rate limit')) return 'rate_limit';
    if (m.contains('database error saving new user')) return 'database_signup_failed';
    if (m.contains('password should be at least') || m.contains('weak password')) {
      return 'weak_password';
    }
    if (m.contains('unable to validate email') || m.contains('invalid email')) {
      return 'invalid_email';
    }
    return 'auth_error';
  }

  /// One-tap demo login: sign in, or sign up then sign in. Returns false if Supabase is not configured.
  Future<bool> demoLogin({required String role}) async {
    if (_client == null) return false;

    final email = DemoCredentials.emailForRole(role);
    const password = DemoCredentials.mobilePassword;

    try {
      await signInWithEmail(email: email, password: password);
      return true;
    } on RawanaAuthException catch (e) {
      if (e.messageKey != 'invalid_credentials' && e.messageKey != 'email_not_verified') {
        rethrow;
      }
    }

    try {
      await signUpWithEmail(
        email: email,
        password: password,
        role: role,
        name: role == 'driver' ? 'Demo Driver' : 'Demo Passenger',
      );
    } on RawanaAuthException catch (e) {
      if (e.messageKey != 'email_already_exists') rethrow;
    }

    await signInWithEmail(email: email, password: password);
    return true;
  }
}
