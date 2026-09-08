import 'api_client.dart';

/// Ensures the backend has a `public.users` or `public.drivers` row for the
/// signed-in Supabase user so the admin portal can list them.
Future<void> syncBackendProfile(ApiClient api) async {
  try {
    await api.post('/auth/sync-profile');
  } catch (_) {
    // Non-fatal — profile GET endpoints also call ensure_* on the backend.
  }
}
