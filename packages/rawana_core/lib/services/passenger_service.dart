import 'dart:convert';
import 'dart:typed_data';

import '../api/api_client.dart';
import '../models/ride_type.dart';
import '../models/trip.dart';

class PassengerService {
  final ApiClient _api;

  PassengerService(this._api);

  Future<List<RideType>> getRideTypes() async {
    final data = await _api.get('/ride-types');
    final list = data['ride_types'] as List<dynamic>? ?? [];
    return list.map((e) => RideType.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Trip?> getActiveTrip() async {
    final data = await _api.get('/passengers/active-trip');
    if (data.isEmpty || data['id'] == null) return null;
    return Trip.fromJson(data);
  }

  Future<Trip> getTrip(String id) async {
    final data = await _api.get('/passengers/trips/$id');
    return Trip.fromJson(data);
  }

  /// Most recent completed trip that still has no rating from this passenger.
  Future<Trip?> getPendingRating() async {
    try {
      final data = await _api.get('/passengers/pending-rating');
      final trip = data['trip'];
      if (trip is Map<String, dynamic> && trip['id'] != null) return Trip.fromJson(trip);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<({List<Trip> trips, int total})> getTripHistory({
    int page = 1,
    String? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await _api.get('/passengers/trips', query: {
      'page': page.toString(),
      if (status != null && status.isNotEmpty) 'status': status,
      if (from != null) 'from': from.toIso8601String().split('T').first,
      if (to != null) 'to': to.toIso8601String().split('T').first,
    });
    final list = data['trips'] as List<dynamic>? ?? [];
    return (
      trips: list.map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList(),
      total: (data['total'] as num?)?.round() ?? list.length,
    );
  }

  Future<DriverLocation?> getDriverLocation() async {
    try {
      final data = await _api.get('/passengers/active-trip/driver-location');
      return DriverLocation.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<NearbyDriver>> getNearbyDrivers({
    required double lat,
    required double lng,
    String? rideTypeId,
    int radiusMeters = 5000,
  }) async {
    try {
      final data = await _api.get('/passengers/nearby-drivers', query: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius_meters': radiusMeters.toString(),
        if (rideTypeId != null) 'ride_type_id': rideTypeId,
      });
      final list = data['drivers'] as List<dynamic>? ?? [];
      return list
          .map((e) => NearbyDriver.fromJson(e as Map<String, dynamic>))
          .where((d) => d.lat.isFinite && d.lng.isFinite)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? language,
    String? profilePhotoUrl,
  }) async {
    final result = await _api.patch('/passengers/profile', data: {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (language != null) 'language': language,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
    });
    if (result.isEmpty || result['id'] == null) {
      throw Exception('Could not save profile. Please try again.');
    }
  }

  /// Uploads a profile photo via the API (service-role storage — works on web without bucket RLS).
  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final result = await _api.post('/passengers/profile-photo/upload', data: {
      'file_name': fileName,
      if (contentType != null) 'content_type': contentType,
      'data': base64Encode(bytes),
    });
    return result['url'] as String;
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _api.get('/passengers/profile');
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    final data = await _api.getList('/passengers/emergency-contacts');
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> addEmergencyContact({
    required String name,
    required String phone,
  }) async {
    return _api.post('/passengers/emergency-contacts', data: {
      'name': name,
      'phone': phone,
    });
  }

  Future<void> deleteEmergencyContact(String id) async {
    await _api.delete('/passengers/emergency-contacts/$id');
  }

  Future<List<Map<String, dynamic>>> getSavedAddresses() async {
    final data = await _api.getList('/passengers/addresses');
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> addSavedAddress({
    required String label,
    required String address,
    required double lat,
    required double lng,
  }) async {
    return _api.post('/passengers/addresses', data: {
      'label': label,
      'address': address,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> deleteSavedAddress(String id) async {
    await _api.delete('/passengers/addresses/$id');
  }

  Future<List<Map<String, dynamic>>> getBanners() async {
    final data = await _api.getList('/passengers/banners');
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<void> submitRating({
    required String tripId,
    required int stars,
    String? comment,
    List<String>? tags,
  }) async {
    await _api.post('/passengers/ratings', data: {
      'trip_id': tripId,
      'stars': stars,
      if (comment != null) 'comment': comment,
      if (tags != null) 'tags': tags,
    });
  }

  Future<void> registerFcmToken(String token) async {
    await _api.post('/passengers/fcm-token', data: {'token': token});
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final data = await _api.get('/passengers/notifications');
    final list = data['notifications'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> markNotificationRead(String id) async {
    await _api.patch('/passengers/notifications/$id/read');
  }

  Future<Map<String, dynamic>> exportAccountData() async {
    return _api.get('/passengers/data-export');
  }

  Future<void> deleteAccount() async {
    await _api.post('/passengers/delete-account');
  }

  Future<String?> getTripReceiptUrl(String tripId) async {
    try {
      final data = await _api.get('/rides/$tripId/receipt');
      return data['url'] as String?;
    } catch (_) {
      return null;
    }
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
}
