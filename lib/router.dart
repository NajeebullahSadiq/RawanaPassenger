import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import 'booking/booking_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/language_screen.dart';
import 'screens/auth_entry_screen.dart';
import 'screens/email_auth_screen.dart';
import 'screens/forgot_password_screen.dart';
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

final rootNavigatorKey = GlobalKey<NavigatorState>();
final bookingShellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
    GoRoute(path: '/auth', builder: (_, _) => const AuthEntryScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, state) => ForgotPasswordScreen(
        initialSms: state.uri.queryParameters['channel'] == 'sms',
      ),
    ),
    GoRoute(
      path: '/email-auth',
      builder: (_, state) => EmailAuthScreen(
        startAsSignUp: state.uri.queryParameters['mode'] == 'signup',
      ),
    ),
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
    // One map for the whole booking: each step is a sheet on top of it.
    ShellRoute(
      navigatorKey: bookingShellNavigatorKey,
      builder: (_, _, child) => BookingShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (_, s) => MapShellPage(key: s.pageKey, child: const HomeScreen()),
        ),
        GoRoute(
          path: '/ride-selection',
          pageBuilder: (_, s) =>
              MapShellPage(key: s.pageKey, child: const RideSelectionScreen()),
        ),
        GoRoute(
          path: '/searching',
          pageBuilder: (_, s) => MapShellPage(key: s.pageKey, child: const SearchingScreen()),
        ),
        GoRoute(
          path: '/active-trip',
          pageBuilder: (_, s) => MapShellPage(key: s.pageKey, child: const ActiveTripScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/destination',
      pageBuilder: (_, s) => sheetUpPage(
        key: s.pageKey,
        child: DestinationSearchScreen(focusPickup: s.uri.queryParameters['focus'] == 'pickup'),
      ),
    ),
    GoRoute(
      path: '/map-picker',
      pageBuilder: (_, s) => fadeThroughPage(
        key: s.pageKey,
        child: MapPickerScreen(
          mode: s.uri.queryParameters['mode'] ?? 'dropoff',
          initialLat: double.tryParse(s.uri.queryParameters['lat'] ?? ''),
          initialLng: double.tryParse(s.uri.queryParameters['lng'] ?? ''),
        ),
      ),
    ),
    GoRoute(
      path: '/trip-complete',
      pageBuilder: (_, s) => fadeThroughPage(key: s.pageKey, child: const TripCompleteScreen()),
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
    GoRoute(
      path: '/terms',
      builder: (context, _) => RawanaInfoScreen(
        title: context.l10n.termsOfService,
        sections: localizedPassengerTerms(context.l10n),
        showLegalFooter: true,
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, _) => RawanaInfoScreen(
        title: context.l10n.privacyPolicy,
        sections: localizedPrivacyPolicy(context.l10n, driver: false),
        showLegalFooter: true,
      ),
    ),
  ],
);
