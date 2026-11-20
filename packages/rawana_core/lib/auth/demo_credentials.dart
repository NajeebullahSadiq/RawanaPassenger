/// Shared demo accounts for local testing. The password is supplied at build
/// time (`DEMO_PASSWORD`) so it never ships in source or production binaries.
class DemoCredentials {
  static const passengerEmail = 'passenger@rawana.af';
  static const driverEmail = 'driver@rawana.af';
  static const mobilePassword = String.fromEnvironment('DEMO_PASSWORD');

  static bool get isConfigured => mobilePassword.isNotEmpty;

  static String emailForRole(String role) =>
      role == 'driver' ? driverEmail : passengerEmail;
}
