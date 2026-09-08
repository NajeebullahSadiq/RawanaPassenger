import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final tripDetailProvider = FutureProvider.family<Trip, String>((ref, tripId) async {
  return ref.read(passengerServiceProvider).getTrip(tripId);
});
