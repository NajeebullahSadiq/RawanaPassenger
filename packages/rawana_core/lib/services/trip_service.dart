import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/booking_errors.dart';
import '../models/ride_type.dart';
import '../models/trip.dart';

class TripService {
  final ApiClient _api;

  TripService(this._api);

  Future<FareEstimate> estimateFare(TripBookingDraft draft) async {
    final data = await _api.post('/rides/estimate', data: _bookingPayload(draft));
    return FareEstimate.fromJson(data);
  }

  Future<({String tripId, int estimatedFare})> requestRide(TripBookingDraft draft) async {
    try {
      final data = await _api.post('/rides/request', data: _bookingPayload(draft));
      return (
        tripId: data['trip_id'] as String,
        estimatedFare: (data['estimated_fare'] as num).round(),
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode == 409 &&
          body is Map &&
          body['message_key'] == 'active_trip_exists' &&
          body['trip_id'] is String) {
        throw ActiveTripExistsException(
          tripId: body['trip_id'] as String,
          status: body['status'] as String?,
        );
      }
      rethrow;
    }
  }

  Future<Trip> acceptRide(String tripId) async {
    final data = await _api.post('/rides/$tripId/accept');
    return Trip.fromJson(data);
  }

  Future<void> rejectRide(String tripId) async {
    await _api.post('/rides/$tripId/reject');
  }

  Future<void> markArrived(String tripId, {bool proximityOverride = false}) async {
    await _postProximity('/rides/$tripId/arrived', proximityOverride);
  }

  Future<void> startTrip(String tripId) async {
    await _api.post('/rides/$tripId/start');
  }

  Future<CompletedRide> completeTrip(
    String tripId, {
    bool proximityOverride = false,
  }) async {
    final data = await _postProximity('/rides/$tripId/complete', proximityOverride);
    return CompletedRide.fromJson(data);
  }

  Future<({bool success, int cancellationFee})> cancelRide(
    String tripId, {
    String? reason,
  }) async {
    final data = await _api.post(
      '/rides/$tripId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return (
      success: data['success'] == true,
      cancellationFee: (data['cancellation_fee'] as num?)?.round() ?? 0,
    );
  }

  Future<CancellationPolicy> getCancellationPolicy(String tripId) async {
    final data = await _api.get('/rides/$tripId/cancellation-policy');
    return CancellationPolicy.fromJson(data);
  }

  Future<({String? cashCollectedAt, int finalFare})> confirmCash(String tripId) async {
    final data = await _api.post('/rides/$tripId/confirm-cash');
    return (
      cashCollectedAt: data['cash_collected_at'] as String?,
      finalFare: (data['finalFare'] as num?)?.round() ?? 0,
    );
  }

  Future<Map<String, dynamic>> _postProximity(String path, bool override) async {
    try {
      return await _api.post(path, data: {'proximity_override': override});
    } on DioException catch (e) {
      final mapped = proximityFromResponse(e.response?.statusCode, e.response?.data);
      if (mapped != null) throw mapped;
      rethrow;
    }
  }

  Map<String, dynamic> _bookingPayload(TripBookingDraft draft) => {
        'ride_type_id': draft.rideTypeId,
        'pickup_lat': draft.pickupLat,
        'pickup_lng': draft.pickupLng,
        'pickup_address': draft.pickupAddress,
        'dropoff_lat': draft.dropoffLat,
        'dropoff_lng': draft.dropoffLng,
        'dropoff_address': draft.dropoffAddress,
        if (draft.promoCode != null && draft.promoCode!.isNotEmpty)
          'promo_code': draft.promoCode,
      };
}
