/// Demo accounts for local/testing builds.
class DemoCredentials {
  static const passengerEmail = 'passenger@rawana.af';
  static const driverEmail = 'driver@rawana.af';
  static const adminEmail = 'admin@rawana.af';
  static const mobilePassword = 'Rawana@Demo2026!';
  static const adminPassword = 'Rawana@Admin2026!';

  static String emailForRole(String role) =>
      role == 'driver' ? driverEmail : passengerEmail;
}
