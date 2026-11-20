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

/// Email sign-up awaiting confirmation. The password stays in memory only so
/// the user can continue after tapping the link without retyping it.
final pendingEmailProvider = StateProvider<({String email, String? password})?>((ref) => null);

/// Local demo session when Supabase is unavailable or email is unverified.
final demoLoggedInProvider = StateProvider<bool>((ref) => false);

final isAppLoggedInProvider = Provider<bool>((ref) {
  ref.watch(authSessionProvider);
  final demo = ref.watch(demoLoggedInProvider);
  return demo || ref.watch(authServiceProvider).isAuthenticated;
});
