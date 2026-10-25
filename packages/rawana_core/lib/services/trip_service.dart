import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/booking_errors.dart';
import '../models/ride_type.dart';
import '../models/trip.dart';

class TripService {
  final ApiClient _api;

  TripService(this._api);

  Future<FareEstimate> estimateFare(TripBookingDraft draft) async {
    final data = await _api.post('/rides/estimate', data: {
      ..._bookingPayload(draft),
      if (draft.scheduledAt != null) 'scheduled_at': draft.scheduledAt!.toUtc().toIso8601String(),
    });
    return FareEstimate.fromJson(data);
  }

  /// Books a ride for `draft.scheduledAt`. The trip stays `scheduled` until
  /// the server dispatches it shortly before pickup.
  Future<Trip> scheduleRide(TripBookingDraft draft) async {
    final data = await _api.post('/rides/schedule', data: {
      ..._bookingPayload(draft),
      'scheduled_at': draft.scheduledAt!.toUtc().toIso8601String(),
    });
    return Trip.fromJson(data);
  }

  /// Driver commits to a scheduled ride ahead of time.
  Future<Trip> reserveScheduledRide(String tripId) async {
    final data = await _api.post('/rides/$tripId/reserve');
    return Trip.fromJson(data);
  }

  /// Driver hands a reserved ride back to the marketplace.
  Future<void> releaseScheduledRide(String tripId) async {
    await _api.post('/rides/$tripId/release');
  }

  /// [expectedCash] is the price the passenger saw; the server refuses with
  /// [FareChangedException] instead of booking at a higher price.
  Future<({String tripId, int estimatedFare})> requestRide(
    TripBookingDraft draft, {
    int? expectedCash,
  }) async {
    try {
      final data = await _api.post('/rides/request', data: {
        ..._bookingPayload(draft),
        if (expectedCash != null) 'expected_cash': expectedCash,
      });
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
      if (e.response?.statusCode == 409 &&
          body is Map &&
          body['message_key'] == 'fare_changed' &&
          body['cash_to_collect'] is num) {
        throw FareChangedException(
          cashToCollect: (body['cash_to_collect'] as num).round(),
          expectedCash: (body['expected_cash'] as num?)?.round() ?? 0,
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
        if (draft.routeDistanceKm != null)
          'route_distance_km': draft.routeDistanceKm,
      };
}
