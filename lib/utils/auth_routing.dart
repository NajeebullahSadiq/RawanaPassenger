import 'package:rawana_core/rawana_core.dart';

/// Routes new passengers without essential profile info to profile setup.
Future<String> passengerRouteAfterAuth(PassengerService service, ApiClient api) async {
  try {
    await syncBackendProfile(api);
    final profile = await service.getProfile();
    if (!isPassengerProfileComplete(profile)) {
      return '/profile-setup';
    }
    return '/home';
  } catch (_) {
    return '/profile-setup';
  }
}
