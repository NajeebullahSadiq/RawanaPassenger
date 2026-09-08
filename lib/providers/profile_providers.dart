import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'trip_providers.dart';

final passengerProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(passengerServiceProvider).getProfile();
});

final emergencyContactsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(passengerServiceProvider).getEmergencyContacts();
});

final savedAddressesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(passengerServiceProvider).getSavedAddresses();
});

final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(passengerServiceProvider).getBanners();
});

final notificationsInboxProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(passengerServiceProvider).getNotifications();
});
