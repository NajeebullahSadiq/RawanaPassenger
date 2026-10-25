import 'package:flutter_test/flutter_test.dart';
import 'package:rawana_core/rawana_core.dart';

void main() {
  group('scheduled trips', () {
    test('parses a reserved scheduled ride', () {
      final trip = Trip.fromJson({
        'id': 't1',
        'status': 'scheduled',
        'driver_id': 'd1',
        'scheduled_at': '2026-10-30T08:15:00Z',
        'reserved_at': '2026-10-25T10:00:00Z',
        'distance_to_pickup_meters': 2450.6,
      });
      expect(trip.status, TripStatus.scheduled);
      expect(trip.status.apiValue, 'scheduled');
      expect(trip.status.isActive, isFalse);
      expect(trip.isScheduledRide, isTrue);
      expect(trip.hasReservedDriver, isTrue);
      expect(trip.scheduledAt, DateTime.utc(2026, 10, 30, 8, 15));
      expect(trip.distanceToPickupMeters, 2451);
    });

    test('dispatched reservation keeps its schedule but is no longer reserved', () {
      final trip = Trip.fromJson({
        'id': 't2',
        'status': 'accepted',
        'driver_id': 'd1',
        'scheduled_at': '2026-10-30T08:15:00Z',
      });
      expect(trip.isScheduledRide, isTrue);
      expect(trip.hasReservedDriver, isFalse);
      expect(trip.status.isActive, isTrue);
    });

    test('on-demand ride is not scheduled', () {
      final trip = Trip.fromJson({'id': 't3', 'status': 'searching'});
      expect(trip.isScheduledRide, isFalse);
      expect(trip.scheduledAt, isNull);
    });

    test('earliest pickup is rounded up to the step after the lead time', () {
      final now = DateTime.now();
      final earliest = earliestScheduledPickup(leadMinutes: 30, step: 5);
      expect(earliest.minute % 5, 0);
      expect(earliest.second, 0);
      expect(
        earliest.isAfter(now.add(const Duration(minutes: 29, seconds: 59))),
        isTrue,
      );
      expect(
        earliest.isBefore(now.add(const Duration(minutes: 36))),
        isTrue,
      );
    });
  });
}
