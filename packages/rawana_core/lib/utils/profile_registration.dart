// Helpers for passenger/driver registration profile completeness.

bool isSyntheticProfilePhone(String? phone) {
  if (phone == null) return true;
  final p = phone.trim();
  return p.isEmpty || p.startsWith('p-') || p.startsWith('d-');
}

bool isRegistrationPhoneValid(String? phone) {
  if (phone == null || isSyntheticProfilePhone(phone)) return false;
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('93')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return digits.length == 9;
}

bool isRegistrationNameValid(String? name) =>
    (name?.trim().length ?? 0) >= 2;

bool isRegistrationEmailValid(String? email) {
  if (email == null || email.trim().isEmpty) return true;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}

/// Normalizes Afghan local input to E.164 (+93…).
String normalizeAfPhoneInput(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('93') && digits.length >= 11) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '+93$digits';
}

bool isPassengerProfileComplete(Map<String, dynamic> profile) =>
    isRegistrationNameValid(profile['name'] as String?) &&
    isRegistrationPhoneValid(profile['phone'] as String?);

bool isDriverProfileBasicsComplete(Map<String, dynamic> profile) =>
    isPassengerProfileComplete(profile);
