import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

typedef TripUpdateCallback = void Function();

/// Subscribes to Supabase Realtime trip and driver-location updates.
class TripRealtimeService {
  RealtimeChannel? _tripChannel;
  RealtimeChannel? _locationChannel;
  String? _subscribedTripId;
  String? _subscribedDriverId;

  void subscribeToTrip(String tripId, TripUpdateCallback onUpdate) {
    if (!AppConfig.hasSupabase || tripId.isEmpty) return;
    if (_subscribedTripId == tripId) return;
    _unsubscribeTrip();

    _subscribedTripId = tripId;
    _tripChannel = Supabase.instance.client
        .channel('trip-$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  void subscribeToDriverLocation(String driverId, TripUpdateCallback onUpdate) {
    if (!AppConfig.hasSupabase || driverId.isEmpty) return;
    if (_subscribedDriverId == driverId) return;
    _unsubscribeLocation();

    _subscribedDriverId = driverId;
    _locationChannel = Supabase.instance.client
        .channel('driver-loc-$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'driver_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  void unsubscribeDriverLocation() {
    _unsubscribeLocation();
  }

  void unsubscribe() {
    _unsubscribeTrip();
    _unsubscribeLocation();
  }

  void _unsubscribeTrip() {
    _tripChannel?.unsubscribe();
    _tripChannel = null;
    _subscribedTripId = null;
  }

  void _unsubscribeLocation() {
    _locationChannel?.unsubscribe();
    _locationChannel = null;
    _subscribedDriverId = null;
  }
}
