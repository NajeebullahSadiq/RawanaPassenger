import 'dart:convert';

import 'package:dio/dio.dart';

/// Extracts the backend `message_key` from any thrown error, if present.
String? apiErrorKey(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  Map<String, dynamic>? map;
  if (data is Map) {
    map = Map<String, dynamic>.from(data);
  } else if (data is String && data.isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) map = Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  final key = map?['message_key'];
  return key is String && key.isNotEmpty ? key : null;
}

/// Riverpod throws this when a listener reads the provider that is notifying.
bool isProviderCycleError(Object error) {
  return error.runtimeType.toString() == 'CircularDependencyError';
}

/// Human-readable fallback text for well-known backend `message_key`s.
///
/// Screens should prefer localized strings when they have them; this keeps raw
/// `DioException` dumps out of snackbars everywhere else.
String apiErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (isProviderCycleError(error)) return fallback;
  final key = apiErrorKey(error);
  switch (key) {
    case 'unauthorized':
    case 'invalid_token':
      return 'Your session has expired. Please sign in again.';
    case 'forbidden':
      return 'You do not have permission to do that.';
    case 'rate_limited':
    case 'otp_rate_limited':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'otp_too_many_attempts':
      return 'Too many incorrect codes. Request a new code.';
    case 'invalid_otp':
      return 'That code is not correct.';
    case 'otp_expired':
      return 'The code has expired. Request a new one.';
    case 'validation_error':
      return 'Some details are missing or invalid.';
    case 'insufficient_balance':
      return 'Your available balance is too low for this payout.';
    case 'payout_details_required':
      return 'Add your payout method and account before requesting a payout.';
    case 'driver_not_approved':
      return 'Your account has not been approved yet.';
    case 'location_required':
      return 'Turn on location and try again.';
    case 'driver_busy':
      return 'Finish or settle your current trip first.';
    case 'driver_offline':
      return 'Go online to accept rides.';
    case 'commission_debt_limit':
      return 'You have reached the commission limit. Settle your balance with Rawana to continue driving.';
    case 'trip_not_available':
      return 'This ride is no longer available.';
    case 'too_many_cancellations':
      return 'You have cancelled too many rides today. Please try again tomorrow.';
    case 'account_blocked':
      return 'This account has been blocked. Contact support.';
    case 'max_contacts_reached':
      return 'You can save up to 3 emergency contacts.';
    case 'max_addresses_reached':
      return 'You can save up to 10 addresses.';
    case 'call_masking_unavailable':
      return 'Calling is temporarily unavailable.';
    case 'receipt_not_ready':
    case 'receipt_unavailable':
      return 'The receipt is not ready yet.';
    case 'promo_invalid':
      return 'That promo code is not valid.';
    case 'promo_expired':
      return 'That promo code has expired.';
    case 'promo_maxed':
      return 'That promo code has reached its usage limit.';
    case 'promo_inactive':
    case 'promo_not_started':
      return 'That promo code is not active right now.';
    case 'invalid_phone':
      return 'Please enter a valid phone number.';
    case 'phone_already_exists':
    case 'profile_update_failed':
      return 'This phone number is already registered. Sign in with that account, or use a different number.';
    case 'email_already_exists':
      return 'This email is already registered. Try signing in instead.';
    case 'file_too_large':
      return 'That file is too large (max 10 MB).';
    case 'empty_file':
      return 'The selected file is empty.';
    case 'upload_failed':
      return 'Upload failed. Please try again.';
    case 'active_trip_exists':
      return 'Finish or cancel your active ride before deleting your account.';
    case 'unsettled_trip_exists':
      return 'Confirm the cash for your last trip before deleting your account.';
    case 'confirm_failed':
      return 'Could not confirm cash collection. Please try again.';
  }
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Cannot reach the Rawana server. Check your connection and try again.';
      default:
        break;
    }
    final data = error.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (error.response?.statusCode != null && error.response!.statusCode! >= 500) {
      return 'The server hit a problem. Please try again shortly.';
    }
  }
  return fallback;
}
