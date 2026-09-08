import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';

/// User-facing copy for [RawanaAuthException.messageKey] values.
String authErrorMessage(String key, {String? detail, AppLocalizations? l10n}) {
  if (l10n != null) return l10n.authError(key, detail: detail);
  switch (key) {
    case 'supabase_not_configured':
      return detail ?? 'Sign-in is not configured. Contact support.';
    case 'invalid_credentials':
      return 'Incorrect email or password. Please check and try again.';
    case 'email_not_verified':
      return 'Please verify your email before signing in.';
    case 'email_already_exists':
      return 'This email is already registered. Try signing in instead.';
    case 'rate_limit':
      return 'Too many attempts. Please wait a minute and try again.';
    case 'database_signup_failed':
      return 'We could not create your account because of a server error. Please try again in a moment.';
    case 'weak_password':
      return 'Password is too weak. Use at least 8 characters with letters and numbers.';
    case 'invalid_email':
      return 'Enter a valid email address.';
    case 'invalid_phone':
      return 'Enter a valid Afghan phone number (9 digits, e.g. 70 123 4567).';
    case 'invalid_otp':
      return 'That code is incorrect or expired. Request a new code and try again.';
    case 'whatsapp_api_not_configured':
      return 'WhatsApp sign-in is not available right now.';
    case 'auth_error':
      return detail ?? 'Something went wrong. Please try again.';
    default:
      return detail ?? 'Something went wrong. Please try again.';
  }
}
