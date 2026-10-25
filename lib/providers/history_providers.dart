import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rawana_core/rawana_core.dart';
import 'trip_providers.dart';

class HistoryFilter {
  const HistoryFilter({this.status, this.from, this.to});

  final String? status;
  final DateTime? from;
  final DateTime? to;

  HistoryFilter copyWith({
    String? status,
    DateTime? from,
    DateTime? to,
    bool clearStatus = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) =>
      HistoryFilter(
        status: clearStatus ? null : (status ?? this.status),
        from: clearFrom ? null : (from ?? this.from),
        to: clearTo ? null : (to ?? this.to),
      );
}

final historyFilterProvider = StateProvider<HistoryFilter>((_) => const HistoryFilter());

final tripHistoryProvider = FutureProvider<({List<Trip> trips, int total})>((ref) async {
  final filter = ref.watch(historyFilterProvider);
  return ref.read(passengerServiceProvider).getTripHistory(
        status: filter.status,
        from: filter.from,
        to: filter.to,
      );
});

class RecentPlace {
  const RecentPlace({required this.address, required this.lat, required this.lng});

  final String address;
  final double lat;
  final double lng;
}

/// Distinct drop-offs from the passenger's latest completed trips.
final recentPlacesProvider =
    FutureProvider.autoDispose<List<RecentPlace>>((ref) async {
  final history = await ref.read(passengerServiceProvider).getTripHistory();
  const distance = Distance();
  final places = <RecentPlace>[];
  for (final trip in history.trips) {
    if (trip.status != TripStatus.completed) continue;
    final lat = trip.dropoffLat;
    final lng = trip.dropoffLng;
    final address = trip.dropoffAddress.trim();
    if (lat == null || lng == null || address.isEmpty) continue;
    final duplicate = places.any(
      (p) =>
          p.address.toLowerCase() == address.toLowerCase() ||
          distance.as(LengthUnit.Meter, LatLng(p.lat, p.lng), LatLng(lat, lng)) < 75,
    );
    if (duplicate) continue;
    places.add(RecentPlace(address: address, lat: lat, lng: lng));
    if (places.length == 5) break;
  }
  return places;
});

final tripDetailProvider = FutureProvider.family<Trip, String>((ref, tripId) async {
  return ref.read(passengerServiceProvider).getTrip(tripId);
});
