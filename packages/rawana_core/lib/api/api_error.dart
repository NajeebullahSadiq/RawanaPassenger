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
    case 'profile_sync_failed':
      return 'We could not finish setting up your account. Please try again.';
    case 'not_found':
    case 'trip_not_found':
    case 'driver_not_found':
      return 'That item could not be found.';
    case 'no_active_trip':
      return 'There is no active ride right now.';
    case 'location_unavailable':
      return 'Location is not available right now. Try again in a moment.';
    case 'nearby_drivers_failed':
      return 'Nearby drivers could not be loaded. Please try again.';
    case 'invalid_trip':
    case 'invalid_trip_status':
      return 'This ride can no longer be updated.';
    case 'rating_failed':
      return 'The rating could not be saved. Please try again.';
    case 'trip_too_short':
      return 'This trip is too short to book.';
    case 'fare_changed':
      return 'The fare changed. Please review the price and try again.';
    case 'too_far_from_pickup':
      return 'Move closer to the pickup point, then try again.';
    case 'too_far_from_dropoff':
      return 'Move closer to the drop-off point, then try again.';
    case 'route_unavailable':
      return 'That is not available yet. Please try again shortly.';
    case 'trip_not_cancellable':
      return 'This ride can no longer be cancelled.';
    case 'whatsapp_send_failed':
    case 'session_failed':
      return 'Sign-in could not be completed. Please try again.';
    case 'driver_account_on_passenger_app':
      return 'This account is a driver account. Open the driver app to sign in.';
    case 'internal_error':
      return 'The server hit a problem. Please try again shortly.';
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
    final code = error.response?.statusCode;
    if (code == 400 || code == 422) {
      return 'Some of these details cannot be saved. Please check them and try again.';
    }
    if (code == 404) return 'That item could not be found.';
    if (code == 409) return 'This is already in use. Try a different value.';
    if (code != null && code >= 500) {
      return 'The server hit a problem. Please try again shortly.';
    }
  }
  final raw = error.toString();
  if (raw.contains('Could not save profile')) {
    return 'Could not save your details. Please try again.';
  }
  return fallback;
}
