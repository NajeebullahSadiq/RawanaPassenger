import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/language_screen.dart';
import 'screens/auth_entry_screen.dart';
import 'screens/email_auth_screen.dart';
import 'screens/email_verify_screen.dart';
import 'screens/phone_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/destination_search_screen.dart';
import 'screens/map_picker_screen.dart';
import 'screens/ride_selection_screen.dart';
import 'screens/searching_screen.dart';
import 'screens/active_trip_screen.dart';
import 'screens/trip_complete_screen.dart';
import 'screens/ride_history_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/help_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/saved_addresses_screen.dart';
import 'screens/scheduled_rides_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
    GoRoute(path: '/auth', builder: (_, _) => const AuthEntryScreen()),
    GoRoute(path: '/email-auth', builder: (_, _) => const EmailAuthScreen()),
    GoRoute(
      path: '/email-verify',
      builder: (_, _) => const EmailVerifyScreen(),
    ),
    GoRoute(path: '/phone', builder: (_, _) => const PhoneScreen()),
    GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
    GoRoute(
      path: '/profile-setup',
      builder: (_, _) => const ProfileSetupScreen(),
    ),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/destination',
      builder: (_, _) => const DestinationSearchScreen(),
    ),
    GoRoute(
      path: '/map-picker',
      builder: (_, s) => MapPickerScreen(
        mode: s.uri.queryParameters['mode'] ?? 'dropoff',
        initialLat: double.tryParse(s.uri.queryParameters['lat'] ?? ''),
        initialLng: double.tryParse(s.uri.queryParameters['lng'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/ride-selection',
      builder: (_, _) => const RideSelectionScreen(),
    ),
    GoRoute(path: '/searching', builder: (_, _) => const SearchingScreen()),
    GoRoute(path: '/active-trip', builder: (_, _) => const ActiveTripScreen()),
    GoRoute(
      path: '/trip-complete',
      builder: (_, _) => const TripCompleteScreen(),
    ),
    GoRoute(path: '/history', builder: (_, _) => const RideHistoryScreen()),
    GoRoute(
      path: '/trip/:id',
      builder: (_, s) => TripDetailScreen(tripId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(
      path: '/saved-addresses',
      builder: (_, _) => const SavedAddressesScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, _) => const NotificationsScreen(),
    ),
    GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
    GoRoute(
      path: '/scheduled-rides',
      builder: (_, _) => const ScheduledRidesScreen(),
    ),
    GoRoute(
      path: '/emergency-contacts',
      builder: (_, _) => const EmergencyContactsScreen(),
    ),
  ],
);
