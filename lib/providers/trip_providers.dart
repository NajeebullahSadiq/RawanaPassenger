import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';
import 'app_providers.dart';
import 'auth_provider.dart';
import 'live_location_providers.dart';

final tripServiceProvider = Provider<TripService>((ref) {
  return TripService(ref.watch(apiClientProvider));
});

final passengerServiceProvider = Provider<PassengerService>((ref) {
  return PassengerService(ref.watch(apiClientProvider));
});

final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService(ref.watch(apiClientProvider), role: 'passenger');
});

final mapsServiceProvider = Provider<MapsService>((ref) {
  return MapsService(ref.watch(apiClientProvider));
});

final tripChatServiceProvider = Provider<TripChatService>((ref) {
  return TripChatService(ref.watch(apiClientProvider));
});

final tripRealtimeServiceProvider = Provider<TripRealtimeService>((ref) {
  final service = TripRealtimeService();
  ref.onDispose(service.unsubscribe);
  return service;
});

final currentTripIdProvider = StateProvider<String?>((ref) => null);

final bookingDraftProvider = StateProvider<TripBookingDraft?>((ref) => null);

/// Pickup time chosen for the ride being booked; null means "now".
final scheduledPickupProvider = StateProvider<DateTime?>((ref) => null);

/// Passenger's upcoming pre-booked rides, soonest first.
final scheduledRidesProvider = FutureProvider.autoDispose<List<Trip>>((ref) async {
  if (!ref.watch(isAppLoggedInProvider)) return const [];
  return ref.read(passengerServiceProvider).getScheduledRides();
});

final rideTypesProvider = FutureProvider<List<RideType>>((ref) async {
  return ref.read(passengerServiceProvider).getRideTypes();
});

/// Trip ids the passenger explicitly skipped rating this session, so Home
/// does not keep nagging after "Skip".
final dismissedRatingPromptsProvider = StateProvider<Set<String>>((ref) => {});

/// Last completed-but-unrated trip (if the app was closed before the
/// trip-complete screen). Null when there is nothing to rate.
final pendingRatingProvider = FutureProvider.autoDispose<Trip?>((ref) async {
  if (!ref.watch(isAppLoggedInProvider)) return null;
  final active = ref.watch(activeTripProvider).valueOrNull;
  // Never prompt while a ride is live or the completion screen is showing.
  if (active != null) return null;
  final trip = await ref.read(passengerServiceProvider).getPendingRating();
  if (trip == null) return null;
  final dismissed = ref.watch(dismissedRatingPromptsProvider);
  return dismissed.contains(trip.id) ? null : trip;
});

final activeTripProvider =
    StateNotifierProvider<ActiveTripNotifier, AsyncValue<Trip?>>((ref) {
      return ActiveTripNotifier(ref);
    });

class ActiveTripNotifier extends StateNotifier<AsyncValue<Trip?>> {
  ActiveTripNotifier(this._ref) : super(const AsyncValue.loading()) {
    if (_ref.read(isAppLoggedInProvider)) {
      refresh();
    } else {
      state = const AsyncValue.data(null);
    }
  }

  final Ref _ref;
  int _matchPollGeneration = 0;

  void stopMatchPolling() {
    _matchPollGeneration++;
  }

  Future<void> refresh() async {
    try {
      var trip = await _ref.read(passengerServiceProvider).getActiveTrip();
      if (!mounted) return;
      final currentTripId = _ref.read(currentTripIdProvider);
      if (trip == null && currentTripId != null) {
        try {
          final lastTrip = await _ref
              .read(passengerServiceProvider)
              .getTrip(currentTripId);
          if (!mounted) return;
          if (lastTrip.status.isActive ||
              lastTrip.status == TripStatus.completed) {
            trip = lastTrip;
          } else {
            _ref.read(currentTripIdProvider.notifier).state = null;
          }
        } catch (_) {
          if (!mounted) return;
          _ref.read(currentTripIdProvider.notifier).state = null;
        }
      }
      if (!mounted) return;
      state = AsyncValue.data(trip);
      final realtime = _ref.read(tripRealtimeServiceProvider);
      if (trip != null) {
        _ref.read(currentTripIdProvider.notifier).state = trip.id;
        _hydrateDraftFromTrip(trip);
        if (trip.status.isActive) {
          realtime.subscribeToTrip(trip.id, () {
            if (mounted) refresh();
          });
        } else {
          realtime.unsubscribe();
        }
      } else {
        realtime.unsubscribe();
      }
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue<Trip?>.error(e, st).copyWithPrevious(state);
    }
  }

  Future<bool> pollUntilAccepted(String tripId) async {
    final generation = ++_matchPollGeneration;
    final realtime = _ref.read(tripRealtimeServiceProvider);
    realtime.subscribeToTrip(tripId, () {
      if (mounted) refresh();
    });

    for (var i = 0; i < 80; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || generation != _matchPollGeneration) return false;
      await refresh();
      if (!mounted || generation != _matchPollGeneration) return false;
      final trip = state.valueOrNull;
      if (trip == null || trip.id != tripId) {
        return false;
      }
      if (trip.status != TripStatus.searching) {
        return trip.status != TripStatus.cancelled;
      }
    }
    return false;
  }

  void clearLocalTripState({bool keepDraft = false}) {
    if (!mounted) return;
    stopMatchPolling();
    try {
      _ref.read(currentTripIdProvider.notifier).state = null;
      if (!keepDraft) {
        _ref.read(bookingDraftProvider.notifier).state = null;
      }
      _ref.read(tripRealtimeServiceProvider).unsubscribe();
      state = const AsyncValue.data(null);
    } catch (_) {
      if (mounted) state = const AsyncValue.data(null);
    }
    // Defer so map/nearby-driver dependents finish flushing before we
    // touch location providers (avoids reentrant CircularDependencyError).
    Future.microtask(() {
      if (!mounted) return;
      try {
        refreshPassengerLocationForNextBooking(_ref);
      } catch (_) {}
    });
  }

  /// Same as [clearLocalTripState] but never throws into the caller's catch.
  void tryClearLocalTripState({bool keepDraft = false}) {
    try {
      clearLocalTripState(keepDraft: keepDraft);
    } catch (_) {}
  }

  /// Re-opens a specific trip (e.g. an unrated completed one, or a live trip
  /// the server reported via `active_trip_exists`) as the current trip.
  Future<Trip?> resumeTrip(String tripId) async {
    _ref.read(currentTripIdProvider.notifier).state = tripId;
    await refresh();
    final trip = state.valueOrNull;
    return trip?.id == tripId ? trip : null;
  }

  void _hydrateDraftFromTrip(Trip trip) {
    if (_ref.read(bookingDraftProvider) != null) return;
    if (trip.pickupLat == null ||
        trip.pickupLng == null ||
        trip.dropoffLat == null ||
        trip.dropoffLng == null ||
        trip.rideTypeId == null) {
      return;
    }
    _ref.read(bookingDraftProvider.notifier).state = TripBookingDraft(
      pickupLat: trip.pickupLat!,
      pickupLng: trip.pickupLng!,
      pickupAddress: trip.pickupAddress,
      dropoffLat: trip.dropoffLat!,
      dropoffLng: trip.dropoffLng!,
      dropoffAddress: trip.dropoffAddress,
      rideTypeId: trip.rideTypeId,
    );
  }
}
