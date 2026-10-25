import 'dart:convert';
import 'dart:typed_data';

import '../api/api_client.dart';
import '../models/ride_type.dart';
import '../models/trip.dart';

class DriverService {
  final ApiClient _api;

  DriverService(this._api);

  Future<Trip?> getPendingRequest() async {
    final data = await _api.get('/drivers/pending-request');
    if (data.isEmpty || data['id'] == null) return null;
    return Trip.fromJson(data);
  }

  Future<Trip?> getActiveTrip() async {
    final data = await _api.get('/drivers/active-trip');
    if (data.isEmpty || data['id'] == null) return null;
    return Trip.fromJson(data);
  }

  Future<void> setOnline(bool isOnline) async {
    await _api.post(
      '/drivers/toggle-availability',
      data: {'is_online': isOnline},
    );
  }

  Future<bool> getOnlineStatus() async {
    final data = await _api.get('/drivers/availability');
    return data['is_online'] == true;
  }

  Future<void> updateLocation({
    required double lat,
    required double lng,
    double? heading,
  }) async {
    await _api.patch(
      '/drivers/location',
      data: {'lat': lat, 'lng': lng, if (heading != null) 'heading': heading},
    );
  }

  Future<Map<String, dynamic>> getEarnings({String period = 'today'}) async {
    return _api.get('/drivers/earnings', query: {'period': period});
  }

  Future<Map<String, dynamic>> getWallet() async {
    return _api.get('/drivers/wallet');
  }

  Future<({List<Trip> trips, int total})> getTripHistory({int page = 1}) async {
    final data = await _api.get(
      '/drivers/trips',
      query: {'page': page.toString()},
    );
    final list = data['trips'] as List<dynamic>? ?? [];
    return (
      trips: list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList(),
      total: (data['total'] as num?)?.round() ?? list.length,
    );
  }

  Future<Trip> getTrip(String id) async {
    final data = await _api.get('/drivers/trips/$id');
    return Trip.fromJson(data);
  }

  /// Scheduled rides nearby that no driver has reserved yet.
  Future<List<Trip>> getAvailableScheduledRides() async {
    final data = await _api.get('/drivers/scheduled-rides');
    final list = data['trips'] as List<dynamic>? ?? [];
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Scheduled rides this driver has reserved, soonest first.
  Future<List<Trip>> getMyReservations() async {
    final data = await _api.get('/drivers/scheduled-rides/mine');
    final list = data['trips'] as List<dynamic>? ?? [];
    return list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _api.get('/drivers/profile');
  }

  Future<List<RideType>> getRideTypes() async {
    final data = await _api.get('/ride-types');
    final list = data['ride_types'] as List<dynamic>? ?? [];
    return list.map((e) => RideType.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? language,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleColour,
    String? plateNumber,
    String? rideTypeId,
    String? payoutMethod,
    String? payoutAccount,
  }) async {
    return _api.patch(
      '/drivers/profile',
      data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (language != null) 'language': language,
        if (vehicleMake != null) 'vehicle_make': vehicleMake,
        if (vehicleModel != null) 'vehicle_model': vehicleModel,
        if (vehicleYear != null) 'vehicle_year': vehicleYear,
        if (vehicleColour != null) 'vehicle_colour': vehicleColour,
        if (plateNumber != null) 'plate_number': plateNumber,
        if (rideTypeId != null) 'ride_type_id': rideTypeId,
        if (payoutMethod != null) 'payout_method': payoutMethod,
        if (payoutAccount != null) 'payout_account': payoutAccount,
      },
    );
  }

  /// Uploads a driver onboarding document via the API (service-role storage).
  Future<String> uploadOnboardingDocument({
    required String docType,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final result = await _api.post(
      '/drivers/onboarding/upload',
      data: {
        'doc_type': docType,
        'file_name': fileName,
        if (contentType != null) 'content_type': contentType,
        'data': base64Encode(bytes),
      },
    );
    return result['url'] as String;
  }

  Future<Map<String, dynamic>> submitOnboarding({
    String? licenceUrl,
    String? registrationUrl,
    String? nationalIdUrl,
    String? profilePhotoUrl,
    String? vehicleMake,
    String? vehicleModel,
    String? plateNumber,
    String? rideTypeId,
  }) async {
    return _api.post(
      '/drivers/onboarding/documents',
      data: {
        if (licenceUrl != null) 'licence_url': licenceUrl,
        if (registrationUrl != null) 'registration_url': registrationUrl,
        if (nationalIdUrl != null) 'national_id_url': nationalIdUrl,
        if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
        if (vehicleMake != null) 'vehicle_make': vehicleMake,
        if (vehicleModel != null) 'vehicle_model': vehicleModel,
        if (plateNumber != null) 'plate_number': plateNumber,
        if (rideTypeId != null) 'ride_type_id': rideTypeId,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTransactions({int page = 1}) async {
    final data = await _api.get(
      '/drivers/transactions',
      query: {'page': page.toString()},
    );
    final list = data['transactions'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getPerformance() async {
    return _api.get('/drivers/performance');
  }

  Future<Map<String, dynamic>> requestPayout({
    required int amount,
    String? notes,
  }) async {
    return _api.post(
      '/drivers/payout-request',
      data: {'amount': amount, if (notes != null) 'notes': notes},
    );
  }

  Future<void> registerFcmToken(String token) async {
    await _api.post('/drivers/fcm-token', data: {'token': token});
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final data = await _api.get('/drivers/notifications');
    final list = data['notifications'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> markNotificationRead(String id) async {
    await _api.patch('/drivers/notifications/$id/read');
  }

  Future<List<Map<String, dynamic>>> getBanners() async {
    final data = await _api.getList('/drivers/banners');
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> getRecentRatings() async {
    final data = await _api.get('/drivers/ratings');
    final list = data['ratings'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> exportAccountData() async {
    return _api.get('/drivers/data-export');
  }

  Future<void> deleteAccount() async {
    await _api.post('/drivers/delete-account');
  }

  Future<Map<String, dynamic>> sendSos({
    required String tripId,
    double? lat,
    double? lng,
  }) async {
    return _api.post('/rides/$tripId/sos', data: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
  }

  Future<void> submitRating({
    required String tripId,
    required int stars,
    String? comment,
    List<String>? tags,
  }) async {
    await _api.post('/drivers/ratings', data: {
      'trip_id': tripId,
      'stars': stars,
      if (comment != null) 'comment': comment,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    });
  }
}
