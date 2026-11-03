import 'package:flutter/widgets.dart';
import '../api/api_error.dart';
import 'app_localizations.dart';

extension RawanaL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension RawanaL10nHelpers on AppLocalizations {
  String tripStatusLabel(String apiValue) {
    switch (apiValue) {
      case 'scheduled':
        return statusScheduled;
      case 'searching':
        return statusSearching;
      case 'accepted':
        return statusAccepted;
      case 'driver_arriving':
        return statusDriverArriving;
      case 'trip_started':
        return statusTripStarted;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      default:
        return apiValue.replaceAll('_', ' ');
    }
  }

  String authError(String key) {
    switch (key) {
      case 'supabase_not_configured':
        return authSupabaseNotConfigured;
      case 'invalid_credentials':
        return authInvalidCredentials;
      case 'email_not_verified':
        return authEmailNotVerified;
      case 'email_already_exists':
        return authEmailAlreadyExists;
      case 'rate_limit':
        return authRateLimit;
      case 'database_signup_failed':
        return authDatabaseSignupFailed;
      case 'weak_password':
        return authWeakPassword;
      case 'invalid_email':
        return authInvalidEmail;
      case 'invalid_phone':
        return authInvalidPhone;
      case 'phone_already_exists':
      case 'profile_update_failed':
        return authPhoneAlreadyRegistered;
      case 'invalid_otp':
        return authInvalidOtp;
      case 'whatsapp_api_not_configured':
        return authWhatsAppUnavailable;
      default:
        return authGenericError;
    }
  }

  /// Signup and profile saves should never show a raw HTTP exception.
  String friendlyApiError(Object error) {
    final key = apiErrorKey(error);
    switch (key) {
      case 'supabase_not_configured':
      case 'invalid_credentials':
      case 'email_not_verified':
      case 'email_already_exists':
      case 'rate_limit':
      case 'database_signup_failed':
      case 'weak_password':
      case 'invalid_email':
      case 'invalid_phone':
      case 'phone_already_exists':
      case 'profile_update_failed':
      case 'invalid_otp':
      case 'whatsapp_api_not_configured':
        return authError(key!);
      default:
        return apiErrorMessage(error, fallback: authGenericError);
    }
  }

  String get dialogOk {
    switch (localeName) {
      case 'fa':
        return 'باشه';
      case 'ps':
        return 'سمه ده';
      default:
        return 'OK';
    }
  }

  String get authPhoneAlreadyRegistered {
    switch (localeName) {
      case 'fa':
        return 'این شماره تلفن قبلاً در حساب دیگری ثبت شده است. با همان حساب وارد شوید، یا شماره دیگری بنویسید.';
      case 'ps':
        return 'دا د تلیفون شمېره دمخه په بل حساب کې ثبت ده. په هماغه حساب ننوځئ، یا بله شمېره ولیکئ.';
      default:
        return 'This phone number is already registered. Sign in with that account, or use a different number.';
    }
  }

  String languageName(String code) {
    switch (code) {
      case 'fa':
        return languageDari;
      case 'ps':
        return languagePashto;
      default:
        return languageEnglish;
    }
  }
}
