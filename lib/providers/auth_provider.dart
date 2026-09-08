import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_providers.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(apiClient: ref.watch(apiClientProvider));
});

final authSessionProvider = StreamProvider<Session?>((ref) {
  final auth = ref.watch(authServiceProvider);
  if (!AppConfig.hasSupabase) {
    return Stream.value(null);
  }
  return auth.authStateChanges.map((event) => event.session);
});

final pendingOtpProvider = StateProvider<({String phone, RawanaOtpChannel channel})?>((ref) => null);

final pendingEmailProvider = StateProvider<String?>((ref) => null);

/// Local demo session when Supabase is unavailable or email is unverified.
final demoLoggedInProvider = StateProvider<bool>((ref) => false);

final isAppLoggedInProvider = Provider<bool>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.isAuthenticated;
});
