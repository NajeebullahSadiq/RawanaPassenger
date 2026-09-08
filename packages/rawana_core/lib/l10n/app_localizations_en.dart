// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Rawana';

  @override
  String get appTitlePassenger => 'Rawana Passenger';

  @override
  String get appTitleDriver => 'Rawana Driver';

  @override
  String get appVersionFooter => 'Rawana · v1.0';

  @override
  String get rawanaDriver => 'Rawana Driver';

  @override
  String get rawanaDriverVersion => 'Rawana Driver  v1.0';

  @override
  String get rawanaDriverRole => 'Rawana driver';

  @override
  String get splashTagline => 'Smooth rides, anywhere in Kabul';

  @override
  String get splashLoading => 'Loading your ride…';

  @override
  String get driverBadge => 'DRIVER';

  @override
  String get riderBadge => 'RIDER';

  @override
  String get preparingDashboard => 'Preparing your dashboard';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get back => 'Back';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get continueAction => 'Continue';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get submit => 'Submit';

  @override
  String get details => 'Details';

  @override
  String get map => 'Map';

  @override
  String get selected => 'selected';

  @override
  String get notSet => 'Not set';

  @override
  String get other => 'Other';

  @override
  String get orDivider => 'OR';

  @override
  String get loading => 'Loading…';

  @override
  String get connecting => 'Connecting…';

  @override
  String get submitting => 'Submitting…';

  @override
  String get checking => 'Checking…';

  @override
  String get requesting => 'Requesting…';

  @override
  String get confirming => 'Confirming...';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get getStarted => 'Get Started';

  @override
  String get whereTo => 'Where to?';

  @override
  String get confirmRide => 'Confirm Ride';

  @override
  String get findingDriver => 'Finding your driver…';

  @override
  String get findingYourDriver => 'Finding your driver';

  @override
  String get driverArriving => 'Driver Arriving';

  @override
  String get tripStarted => 'On the way';

  @override
  String get tripCompleted => 'Trip Completed';

  @override
  String payCash(String amount) {
    return 'Pay $amount in cash';
  }

  @override
  String get currencyAfn => 'AFN';

  @override
  String get sendCode => 'Send code';

  @override
  String get verifyOtp => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get goOnline => 'Go online';

  @override
  String get goOffline => 'Go offline';

  @override
  String get accept => 'Accept';

  @override
  String get reject => 'Reject';

  @override
  String get decline => 'Decline';

  @override
  String get cancelRide => 'Cancel ride';

  @override
  String get earnings => 'Earnings';

  @override
  String get wallet => 'Wallet';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get logOut => 'Log out';

  @override
  String get signOut => 'Sign out';

  @override
  String get noConnection => 'No internet connection';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get youAreOfflineReconnect =>
      'You are offline — reconnect to continue';

  @override
  String get language => 'Language';

  @override
  String get chooseYourLanguage => 'Choose your language';

  @override
  String get languageChangeHint => 'You can change this anytime from settings.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDari => 'دری';

  @override
  String get languagePashto => 'پښتو';

  @override
  String get languageEnglishMeta => 'LTR · Latin';

  @override
  String get languageDariMeta => 'RTL · Dari';

  @override
  String get languagePashtoMeta => 'RTL · Pashto';

  @override
  String get onboardingSlide1Title => 'Book a ride in seconds';

  @override
  String get onboardingSlide1Body =>
      'Set your destination and confirm — the nearest driver will be on the way.';

  @override
  String get onboardingSlide2Title => 'Track every kilometre';

  @override
  String get onboardingSlide2Body =>
      'See your driver approach in real time on the map, and share trip status with loved ones.';

  @override
  String get onboardingSlide3Title => 'Cash made simple';

  @override
  String get onboardingSlide3Body =>
      'Pay your driver directly in Afghan Afghani (AFN) when you arrive. No card needed.';

  @override
  String get continueWithEmail => 'Continue with Email';

  @override
  String get continueWithPhone => 'Continue with phone';

  @override
  String get authTermsFooter =>
      'By continuing you agree to our Terms & Privacy Policy.';

  @override
  String get agreeTermsConduct =>
      'By continuing you agree to our Terms & Driver Code of Conduct.';

  @override
  String get createAccount => 'Create account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get welcomeBackCaptain => 'Welcome back, captain';

  @override
  String get signUpSubtitle => 'A few details and you are ready to ride.';

  @override
  String get signInSubtitle => 'Sign in to keep riding.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameRequired => 'Full name *';

  @override
  String get phoneNumberRequired => 'Phone number *';

  @override
  String get afPhonePrefix => '🇦🇫 +93';

  @override
  String get phoneHint => '70 123 4567';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get newHereCreateAccount => 'New here? Create an account';

  @override
  String get phoneOtpComingSoon => 'Phone OTP will be enabled in production.';

  @override
  String get authEntryHeadline => 'Let\'s get you\nmoving.';

  @override
  String get authEntrySubtitle =>
      'Sign in to book rides across Kabul in seconds.';

  @override
  String get authValueFastTitle => 'Fast booking';

  @override
  String get authValueFastBody => 'Find a nearby driver in under a minute.';

  @override
  String get authValueTrustedTitle => 'Trusted drivers';

  @override
  String get authValueTrustedBody => 'Every driver is verified and rated.';

  @override
  String get authValuePayTitle => 'Pay in AFN cash';

  @override
  String get authValuePayBody => 'No card required — pay at trip end.';

  @override
  String get driveWithRawana => 'Drive with\nRawana.';

  @override
  String get signInEmailToTest =>
      'Sign in with email to test the driver experience.';

  @override
  String get earnOnYourSchedule =>
      'Earn on your own schedule. Get verified, get rides, get paid.';

  @override
  String get earnFlexibly => 'Earn flexibly';

  @override
  String get goOnlineWhenever => 'Go online whenever you want.';

  @override
  String get dailyPayouts => 'Daily payouts';

  @override
  String get trackEveryFare => 'Track every fare in your wallet.';

  @override
  String get driverSupport => 'Driver support';

  @override
  String get supportTeam247 => 'A team that has your back, 24/7.';

  @override
  String get becomeADriver => 'Become a driver';

  @override
  String get createDriverAccountInAMinute =>
      'Create your driver account in a minute.';

  @override
  String get signInToGoOnline => 'Sign in to go online.';

  @override
  String get createDriverAccount => 'Create driver account';

  @override
  String get alreadyADriverSignIn => 'Already a driver? Sign in';

  @override
  String get newDriverCreateAccount => 'New driver? Create account';

  @override
  String get enterYourPhone => 'Enter your phone';

  @override
  String get phoneVerifyHint =>
      'We will send a 6-digit code to verify it is really you.';

  @override
  String get phoneKeepsAccountSecure =>
      'We use this to keep your driver account secure.';

  @override
  String get otpChannelSms => 'SMS';

  @override
  String get otpChannelWhatsApp => 'WhatsApp';

  @override
  String get otpSessionExpired =>
      'Session expired. Go back and request a new code.';

  @override
  String get verificationCode => 'Verification code';

  @override
  String otpEnterCodeVia(String channel) {
    return 'Enter the 6-digit code we sent via $channel.';
  }

  @override
  String otpEnterCodeViaTo(String channel, String phone) {
    return 'Enter the 6-digit code we sent via $channel to $phone.';
  }

  @override
  String resendCodeInSeconds(String seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get verificationEmailSent =>
      'Verification email sent. Check your inbox.';

  @override
  String get emailNotVerifiedYet =>
      'Email not verified yet. Check your inbox and try again.';

  @override
  String get checkYourInbox => 'Check your inbox';

  @override
  String get weSentVerificationLinkTo => 'We sent a verification link to ';

  @override
  String get yourEmailFallback => 'your email';

  @override
  String get tapLinkThenContinue =>
      '. Tap the link to verify, then come back here to continue.';

  @override
  String get tapLinkThenContinueOnboarding =>
      '. Tap the link to verify, then come back here to continue onboarding.';

  @override
  String get checkSpamTip =>
      'Tip: check your spam or promotions folder if you do not see it.';

  @override
  String get iHaveVerifiedContinue => 'I have verified - continue';

  @override
  String get resendVerificationEmail => 'Resend verification email';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get quickDemoAccess => 'Quick Demo Access';

  @override
  String get demoLoginNeedsSupabase =>
      'Supabase is required for demo login. Add SUPABASE_URL and SUPABASE_ANON_KEY.';

  @override
  String get demoLoginFailed =>
      'Demo login failed. Check demo credentials in rawana_core.';

  @override
  String get authSupabaseNotConfigured =>
      'Sign-in is not configured. Contact support.';

  @override
  String get authInvalidCredentials =>
      'Incorrect email or password. Please check and try again.';

  @override
  String get authEmailNotVerified =>
      'Please verify your email before signing in.';

  @override
  String get authEmailAlreadyExists =>
      'This email is already registered. Try signing in instead.';

  @override
  String get authRateLimit =>
      'Too many attempts. Please wait a minute and try again.';

  @override
  String get authDatabaseSignupFailed =>
      'We could not create your account because of a server error. Please try again in a moment.';

  @override
  String get authWeakPassword =>
      'Password is too weak. Use at least 8 characters with letters and numbers.';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authInvalidPhone =>
      'Enter a valid Afghan phone number (9 digits, e.g. 70 123 4567).';

  @override
  String get authInvalidOtp =>
      'That code is incorrect or expired. Request a new code and try again.';

  @override
  String get authWhatsAppUnavailable =>
      'WhatsApp sign-in is not available right now.';

  @override
  String get authGenericError => 'Something went wrong. Please try again.';

  @override
  String get completeYourProfile => 'Complete your profile';

  @override
  String get almostThere => 'Almost there!';

  @override
  String get profileSetupSubtitle =>
      'Add your name and phone so your driver can reach you.';

  @override
  String photoUploadFailed(String error) {
    return 'Photo upload failed: $error';
  }

  @override
  String get driverRegistration => 'Driver registration';

  @override
  String get yourDetails => 'Your details';

  @override
  String get needNameAndPhoneBeforeDocs =>
      'Passengers and support need your name and phone before you can upload documents.';

  @override
  String get continueToDocuments => 'Continue to documents';

  @override
  String get gettingYourLocation => 'Getting your location…';

  @override
  String get gettingLocation => 'Getting location…';

  @override
  String get currentLocation => 'Current location';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get waitingForLocation => 'Waiting for your location…';

  @override
  String get myLocation => 'My location';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get greetingNameFallback => 'there';

  @override
  String get navRide => 'Ride';

  @override
  String get help => 'Help';

  @override
  String get viewSearch => 'View search';

  @override
  String get viewRide => 'View ride';

  @override
  String get searchDestination => 'Search destination';

  @override
  String get quickHome => 'Home';

  @override
  String get quickWork => 'Work';

  @override
  String get quickSaved => 'Saved';

  @override
  String get gpsLocked => 'GPS LOCKED';

  @override
  String get gpsAcquiring => 'ACQUIRING';

  @override
  String get gpsBlocked => 'GPS BLOCKED';

  @override
  String get pickupLabel => 'PICKUP';

  @override
  String get destinationLabel => 'DESTINATION';

  @override
  String get currentLabel => 'CURRENT';

  @override
  String get driverOnTheWay => 'Driver on the way';

  @override
  String get driverIsArriving => 'Driver is arriving';

  @override
  String get onTripToDestination => 'On trip to destination';

  @override
  String get rideInProgress => 'Ride in progress';

  @override
  String noSavedAddressTitle(String label) {
    return 'No $label address';
  }

  @override
  String noSavedAddressBody(String label) {
    return 'Add a saved address labeled \"$label\" first.';
  }

  @override
  String get addAddress => 'Add address';

  @override
  String get invalidSavedAddressCoords => 'Invalid saved address coordinates';

  @override
  String get kabulFallbackPickup => 'Kabul (set exact pickup on map)';

  @override
  String get locationUnavailableEnableGps =>
      'Location unavailable. Enable GPS or tap pickup to choose on the map.';

  @override
  String get choosePickupFirst => 'Choose your pickup location first';

  @override
  String get choosePickupFirstShort => 'Choose your pickup first';

  @override
  String get couldNotSelectPlace => 'Could not select place. Try again.';

  @override
  String get selectedPickup => 'Selected pickup';

  @override
  String get selectedDestination => 'Selected destination';

  @override
  String get enableLocationToBook => 'Enable location to book a ride';

  @override
  String get planYourTrip => 'Plan your trip';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get popularPlaces => 'POPULAR PLACES';

  @override
  String get suggestions => 'SUGGESTIONS';

  @override
  String get editPickup => 'Edit pickup';

  @override
  String get searchPickupLocation => 'Search pickup location';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get chooseOnMap => 'Choose on map';

  @override
  String get movePinToPickup => 'Move the pin to your exact pickup';

  @override
  String get startTyping => 'Start typing';

  @override
  String get weWillSuggestPlaces => 'We will suggest places near you';

  @override
  String get dropPinDestination => 'Drop a pin exactly where you want to go';

  @override
  String get moveMapToChoose => 'Move the map to choose a location';

  @override
  String get choosePickup => 'Choose pickup';

  @override
  String get chooseDestination => 'Choose destination';

  @override
  String get useThisPickup => 'Use this pickup';

  @override
  String get useThisDestination => 'Use this destination';

  @override
  String get tapOrDragMap => 'Tap or drag the map, then confirm.';

  @override
  String failedToLoadRideTypes(String error) {
    return 'Failed to load ride types: $error';
  }

  @override
  String get noRideTypesAvailable => 'No ride types available';

  @override
  String get pickupConfirmed => 'Pickup confirmed';

  @override
  String get pickup => 'Pickup';

  @override
  String get destination => 'Destination';

  @override
  String get dropoff => 'Drop-off';

  @override
  String get chooseYourRide => 'Choose your ride';

  @override
  String etaMinToDestination(String minutes) {
    return '~$minutes min to destination';
  }

  @override
  String get payment => 'Payment';

  @override
  String get cashAfn => 'Cash · AFN';

  @override
  String get paymentMethodConfirmed => 'Payment method confirmed';

  @override
  String get tapToConfirmPayment => 'Tap to confirm payment at trip end';

  @override
  String requestRideWithFare(String name, String fare) {
    return 'Request $name · $fare';
  }

  @override
  String get confirmPaymentToContinue => 'Confirm payment to continue';

  @override
  String get missingTripDetails => 'Missing trip details';

  @override
  String get noDriversAvailable =>
      'No drivers available right now. Please try again.';

  @override
  String get connectingToNearbyDrivers =>
      'Connecting you to nearby drivers — usually under a minute.';

  @override
  String get retryOrCancelBelow => 'You can retry or cancel below.';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get followingLiveRouteHint =>
      'Following live route. Tap ↓ to return to trip details.';

  @override
  String get couldNotOpenWhatsAppCall => 'Could not open WhatsApp call';

  @override
  String get couldNotOpenWhatsAppMessages => 'Could not open WhatsApp messages';

  @override
  String get cancelThisRide => 'Cancel this ride?';

  @override
  String get cancelRideWarning =>
      'Your driver will be notified. Repeated cancellations may incur a fee.';

  @override
  String get keepRide => 'Keep ride';

  @override
  String get shareTripIntro => 'I\'m on a Rawana trip.';

  @override
  String shareDriver(String name) {
    return 'Driver: $name';
  }

  @override
  String shareVehicle(String vehicle) {
    return 'Vehicle: $vehicle';
  }

  @override
  String sharePlate(String plate) {
    return 'Plate: $plate';
  }

  @override
  String shareFrom(String address) {
    return 'From: $address';
  }

  @override
  String shareTo(String address) {
    return 'To: $address';
  }

  @override
  String shareCurrentLocation(String url) {
    return 'Current location: $url';
  }

  @override
  String get shareTripSubject => 'My Rawana trip';

  @override
  String get driverConfirmedHeadingPickup =>
      'Driver confirmed — heading to pickup';

  @override
  String get driverIsAtPickup => 'Driver is at your pickup';

  @override
  String get backToHome => 'Back to home';

  @override
  String get you => 'You';

  @override
  String get yourDriver => 'Your driver';

  @override
  String get followingYourTrip => 'Following your trip';

  @override
  String get driverEnRouteToPickup => 'Driver en route to pickup';

  @override
  String get safety => 'Safety';

  @override
  String get driverLiveLocation => 'Driver live location';

  @override
  String get yourPickupSpot => 'Your pickup spot';

  @override
  String get hintFollowLiveRoute =>
      'Route line updates as your driver moves. Tap Start navigation to follow live.';

  @override
  String get hintWatchDriverApproach =>
      'Watch your driver approach on the map. ETA updates automatically.';

  @override
  String get followTripRoute => 'Follow trip route';

  @override
  String get followDriverToPickup => 'Follow driver to pickup';

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get shareTrip => 'Share trip';

  @override
  String get driverArrivedNotice => 'Your driver is at your pickup location.';

  @override
  String get youHaveArrived => 'You have arrived';

  @override
  String get thanksForRiding => 'Thank you for riding with Rawana.';

  @override
  String get payYourDriver => 'PAY YOUR DRIVER';

  @override
  String get howWasYourTrip => 'How was your trip?';

  @override
  String get feedbackHelpsDrivers => 'Your feedback helps drivers improve.';

  @override
  String get ratingTagCleanCar => 'Clean car';

  @override
  String get ratingTagSafeDriving => 'Safe driving';

  @override
  String get ratingTagFriendlyDriver => 'Friendly driver';

  @override
  String get ratingTagOnTime => 'On time';

  @override
  String get ratingTagGoodNavigation => 'Good navigation';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get skipRating => 'Skip rating';

  @override
  String get reportAnIssue => 'Report an issue';

  @override
  String ratingFailed(String error) {
    return 'Rating failed: $error';
  }

  @override
  String tripTitleWithId(String id) {
    return 'Trip · $id';
  }

  @override
  String get tripSummary => 'Trip summary';

  @override
  String get totalFare => 'Total fare';

  @override
  String get driverLabel => 'DRIVER';

  @override
  String get whatsAppDriver => 'WhatsApp driver';

  @override
  String get whatsAppCallDriver => 'WhatsApp call driver';

  @override
  String get rideHistory => 'Ride history';

  @override
  String failedToLoadHistory(String error) {
    return 'Failed to load history: $error';
  }

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get pastRidesHint => 'Your past rides will appear here.';

  @override
  String fromAddress(String address) {
    return 'From $address';
  }

  @override
  String get statusSearching => 'Searching';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusDriverArriving => 'Driver arriving';

  @override
  String get statusTripStarted => 'Trip started';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get completed => 'Completed';

  @override
  String get account => 'Account';

  @override
  String failedToLoadProfile(String error) {
    return 'Failed to load profile: $error';
  }

  @override
  String get passengerFallbackName => 'Passenger';

  @override
  String get tripsStat => 'Trips';

  @override
  String get ratingStat => 'Rating';

  @override
  String get memberStat => 'Member';

  @override
  String get memberNew => 'New';

  @override
  String get preferences => 'Preferences';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get notifications => 'Notifications';

  @override
  String get safetyAndSupport => 'Safety & Support';

  @override
  String get emergencyContacts => 'Emergency contacts';

  @override
  String get helpCentre => 'Help centre';

  @override
  String get enableLocationToSaveAddress =>
      'Enable location to save this address';

  @override
  String get saveANewAddress => 'Save a new address';

  @override
  String get usesCurrentGps =>
      'Uses your current GPS location for coordinates.';

  @override
  String get addressLabel => 'Label';

  @override
  String get addressLabelHint => 'Home, Work, Gym…';

  @override
  String get addressField => 'Address';

  @override
  String get saveAddress => 'Save address';

  @override
  String failedToLoadAddresses(String error) {
    return 'Failed to load addresses: $error';
  }

  @override
  String get noSavedAddresses => 'No saved addresses';

  @override
  String get savedAddressesEmptyHint =>
      'Save Home, Work and other places\nfor one-tap booking.';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get notificationsEmptyHint =>
      'Trip updates and promotions will appear here\nwhen push notifications are enabled.';

  @override
  String get needAHand => 'Need a hand?';

  @override
  String get helpTeam247 => 'Our team is here to help, 24/7.';

  @override
  String get commonQuestions => 'Common questions';

  @override
  String get faqBookTitle => 'How do I book a ride?';

  @override
  String get faqBookBody =>
      'Open the app, tap \"Where to?\", set your destination, choose a ride type, and confirm. Your nearest driver will be on the way.';

  @override
  String get faqPayTitle => 'How do I pay?';

  @override
  String get faqPayBody =>
      'Pay the driver in Afghan Afghani (AFN) cash at the end of your trip.';

  @override
  String get reportSafetyOrTripIssue => 'Report a safety or trip issue';

  @override
  String get addEmergencyContact => 'Add emergency contact';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get saveContact => 'Save contact';

  @override
  String failedToLoadContacts(String error) {
    return 'Failed to load contacts: $error';
  }

  @override
  String get noContactsYet => 'No contacts yet';

  @override
  String get emergencyContactsEmptyHint =>
      'Add up to 3 trusted contacts.\nThey will be notified during emergencies.';

  @override
  String get navigate => 'Navigate';

  @override
  String get estimatedFare => 'Estimated fare';

  @override
  String get minutesShort => 'min';

  @override
  String get secondsShort => 'sec';

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String distanceMeters(String meters) {
    return '$meters m';
  }

  @override
  String etaMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get routeDistance => 'route distance';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get endNavigation => 'End navigation';

  @override
  String get navigating => 'Navigating';

  @override
  String get followingSelectedRoute => 'Following selected route';

  @override
  String get routes => 'Routes';

  @override
  String get routeShortest => 'Shortest';

  @override
  String get routeFastest => 'Fastest';

  @override
  String routeChipDurationDistance(String minutes, String km) {
    return '${minutes}m · ${km}km';
  }

  @override
  String get nearbyDriver => 'Nearby driver';

  @override
  String get driver => 'Driver';

  @override
  String get passenger => 'Passenger';

  @override
  String get activeRide => 'Active ride';

  @override
  String get continueOnHighlightedRoute => 'Continue on the highlighted route';

  @override
  String get startNavigation => 'Start navigation';

  @override
  String issueWithTrip(String id) {
    return 'Issue with trip #$id';
  }

  @override
  String get reportValidation =>
      'Please add a subject and at least 10 characters of detail.';

  @override
  String get reportSubmitted => 'Report submitted. Our team will follow up.';

  @override
  String failedToSubmit(String error) {
    return 'Failed to submit: $error';
  }

  @override
  String tripShortId(String id) {
    return 'Trip $id';
  }

  @override
  String get category => 'Category';

  @override
  String get subject => 'Subject';

  @override
  String get whatHappened => 'What happened?';

  @override
  String get safetyReportPriority =>
      'Safety reports are prioritised. If you are in immediate danger, contact local emergency services.';

  @override
  String get submitReport => 'Submit report';

  @override
  String get supportBilling => 'Billing / overcharge';

  @override
  String get supportDriverBehaviour => 'Driver behaviour';

  @override
  String get supportSafetyConcern => 'Safety concern';

  @override
  String get supportTechnical => 'App / technical issue';

  @override
  String get supportOther => 'Other';

  @override
  String get supportFarePayment => 'Fare / payment issue';

  @override
  String get supportPassengerBehaviour => 'Passenger behaviour';

  @override
  String get docDriverLicence => 'Driver Licence';

  @override
  String get docVehicleRegistration => 'Vehicle Registration';

  @override
  String get docNationalId => 'National ID';

  @override
  String get docProfilePhoto => 'Profile Photo';

  @override
  String get docVehicleInfo => 'Vehicle Info';

  @override
  String get supabaseRequiredForUpload =>
      'Supabase required for document upload';

  @override
  String get documentUploaded => 'Document uploaded';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get pleaseUploadAllDocuments => 'Please upload all required documents';

  @override
  String get enterVehicleMakeModelPlate =>
      'Enter vehicle make, model, and plate number';

  @override
  String get pleaseUploadDocumentFirst => 'Please upload the document first';

  @override
  String stepOfTotal(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String takeClearPhotoOf(String document) {
    return 'Take a clear, well-lit photo of your $document.';
  }

  @override
  String get tellUsAboutVehicle => 'Tell us about the vehicle you will drive.';

  @override
  String get submitForReview => 'Submit for review';

  @override
  String get captureDocument => 'Capture document';

  @override
  String get looksGoodCanRetake => 'Looks good - you can retake if needed.';

  @override
  String get jpgPngKeptPrivate => 'JPG or PNG, kept private and secure.';

  @override
  String get retakePhoto => 'Retake photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get vehicleMakeExample => 'Vehicle make (e.g. Toyota)';

  @override
  String get vehicleModelExample => 'Model (e.g. Corolla)';

  @override
  String get plateNumber => 'Plate number';

  @override
  String get couldNotCheckStatus => 'Could not check status';

  @override
  String get applicationNotApproved => 'Application not approved';

  @override
  String get applicationUnderReview => 'Application under review';

  @override
  String get documentsCouldNotBeVerified =>
      'Your documents could not be verified. Please review and resubmit.';

  @override
  String get verifyingDocuments24to48 =>
      'We are verifying your documents. This usually takes 24–48 hours. You will be notified once your account is approved.';

  @override
  String get documentsSubmitted => 'Documents submitted';

  @override
  String get reviewFailedResubmit => 'Review failed — resubmit required';

  @override
  String get backgroundVehicleVerification =>
      'Background & vehicle verification';

  @override
  String get welcomeOnboard => 'Welcome onboard';

  @override
  String get resubmitDocuments => 'Resubmit documents';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get mustBeApprovedToGoOnline =>
      'Your account must be approved before going online';

  @override
  String get enableLocationToGoOnline =>
      'Enable location to go online and receive ride requests.';

  @override
  String get couldNotGoOnline =>
      'Could not go online. Check approval and connection.';

  @override
  String get rideCancelled => 'Ride cancelled';

  @override
  String get headToPickup => 'Head to pickup';

  @override
  String get navigateToPickup => 'Navigate to pickup';

  @override
  String get atPickup => 'At pickup';

  @override
  String get continuePickup => 'Continue pickup';

  @override
  String get tripInProgress => 'Trip in progress';

  @override
  String get continueTrip => 'Continue trip';

  @override
  String get activeTrip => 'Active trip';

  @override
  String get viewTrip => 'View trip';

  @override
  String get verifiedDriver => 'Verified driver';

  @override
  String get youAreOffline => 'You are offline';

  @override
  String get youAreOnline => 'You are online';

  @override
  String get switchOnlineToReceiveRides =>
      'Switch online to start receiving rides';

  @override
  String get todaysEarnings => 'Today\'s earnings';

  @override
  String get lastSession => 'Last session';

  @override
  String get trips => 'Trips';

  @override
  String get gross => 'Gross';

  @override
  String get rating => 'Rating';

  @override
  String get receivingRides => 'Receiving rides';

  @override
  String get tapToStart => 'Tap to start';

  @override
  String acceptFailed(String error) {
    return 'Accept failed: $error';
  }

  @override
  String get newRideRequest => 'New ride request';

  @override
  String get respondNowTimeRunningOut => 'Respond now — time is running out';

  @override
  String get reviewRouteAndAccept => 'Review route and accept quickly';

  @override
  String get acceptRide => 'Accept ride';

  @override
  String get minEta => 'min ETA';

  @override
  String get distance => 'distance';

  @override
  String get passengerWillBeNotifiedTripEnds =>
      'The passenger will be notified and the trip will end.';

  @override
  String rideCancelledFee(String amount) {
    return 'Ride cancelled. Fee: $amount';
  }

  @override
  String cancelFailed(String error) {
    return 'Cancel failed: $error';
  }

  @override
  String get backToDashboard => 'Back to dashboard';

  @override
  String namePickup(String name) {
    return '$name pickup';
  }

  @override
  String get passengerPickup => 'Passenger pickup';

  @override
  String get whatsAppPassenger => 'WhatsApp passenger';

  @override
  String get whatsAppCallPassenger => 'WhatsApp call passenger';

  @override
  String get headingToPickup => 'Heading to pickup';

  @override
  String get waitingAtPickupMarker => 'Waiting at the pickup marker';

  @override
  String get passengerPickupLocation => 'Passenger pickup location';

  @override
  String get inAppNavigationStarted => 'In-app navigation started.';

  @override
  String get iveArrivedAtPickup => 'I\'ve arrived at pickup';

  @override
  String get youAreAtPickupLocation =>
      'You are at the passenger pickup location.';

  @override
  String get tapStartNavigation => 'Tap Start navigation to follow the route.';

  @override
  String get samePickupLocation =>
      'You and the passenger are at the same pickup location.';

  @override
  String get tripStartedFollowRoute =>
      'Trip started. Follow the route to the destination.';

  @override
  String get completeThisTrip => 'Complete this trip?';

  @override
  String get onlyCompleteAfterDestination =>
      'Only complete after the passenger has reached the destination.';

  @override
  String get keepDriving => 'Keep driving';

  @override
  String get completeTrip => 'Complete trip';

  @override
  String get onlyCancelIfCannotContinue =>
      'Only cancel if you cannot safely continue. The passenger will be notified.';

  @override
  String get waitingForPassenger => 'Waiting for passenger';

  @override
  String dropoffWithAddress(String address) {
    return 'Drop-off: $address';
  }

  @override
  String get atPickupStartWhenOnboard =>
      'At pickup — start trip when passenger is onboard';

  @override
  String get yourCurrentLocation => 'Your current location';

  @override
  String get mayCancelWithoutFeeNoShow =>
      'You may cancel without fee if the passenger did not show.';

  @override
  String get startTripOnceOnboard =>
      'Start the trip once the passenger is in your car.';

  @override
  String get navigateToDropoff => 'Navigate to drop-off';

  @override
  String get cancelRideNoFee => 'Cancel ride (no fee)';

  @override
  String get goToPickup => 'Go to pickup';

  @override
  String get startTrip => 'Start trip';

  @override
  String get tripStartedKeepDriving => 'Trip started - keep driving';

  @override
  String statusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String get tagPolite => 'Polite';

  @override
  String get tagOnTimeAtPickup => 'On time at pickup';

  @override
  String get tagClearDirections => 'Clear directions';

  @override
  String get tagRespectful => 'Respectful';

  @override
  String get tagEasyPickup => 'Easy pickup';

  @override
  String get couldNotUpdateAvailability => 'Could not update availability';

  @override
  String get greatJob => 'Great job!';

  @override
  String get tripCompletedFareBreakdown =>
      'Trip completed. Here\'s your fare breakdown.';

  @override
  String get rateYourPassenger => 'Rate your passenger';

  @override
  String get feedbackKeepsRawanaSafe =>
      'Your feedback helps keep Rawana safe and reliable.';

  @override
  String get openToNewRequests => 'You are open to new ride requests';

  @override
  String get goOnlineToReceiveRequests => 'Go online to receive new requests';

  @override
  String get youEarned => 'YOU EARNED';

  @override
  String get grossFare => 'Gross fare';

  @override
  String rawanaFeePercent(String percent) {
    return 'Rawana fee ($percent%)';
  }

  @override
  String get yourEarnings => 'Your earnings';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get couldNotLoadEarnings => 'Could not load earnings';

  @override
  String get platformFee => 'Platform fee';

  @override
  String get avgPerTrip => 'Avg / trip';

  @override
  String get netEarnings => 'Net earnings';

  @override
  String noTripsYetPeriod(String period) {
    return 'No trips yet $period';
  }

  @override
  String tripsCompletedOne(String count) {
    return '$count trip completed';
  }

  @override
  String tripsCompletedOther(String count) {
    return '$count trips completed';
  }

  @override
  String get howEarningsWork => 'How earnings work';

  @override
  String get earningsExplainer =>
      'Gross fares are what passengers paid. Platform fee is deducted automatically; net earnings are deposited to your wallet and become available for payout.';

  @override
  String get activitySnapshot => 'Activity snapshot';

  @override
  String get completeTripsToSeeActivity =>
      'Complete trips to see your activity pattern.';

  @override
  String get couldNotLoadWallet => 'Could not load wallet';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get couldNotLoadTransactions => 'Could not load transactions';

  @override
  String get requestPayoutQuestion => 'Request payout?';

  @override
  String willTransferToPayoutAccount(String amount) {
    return 'We will transfer $amount from your wallet. Rawana processes payouts — no bank account is required in the app.';
  }

  @override
  String get payoutRequested => 'Payout requested';

  @override
  String get availableBalance => 'Available balance';

  @override
  String pendingAmount(String amount) {
    return 'Pending $amount';
  }

  @override
  String get requestPayout => 'Request payout';

  @override
  String get noFundsYet => 'No funds yet';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get earningsPayoutsWillShowHere =>
      'Earnings and payouts will show up here.';

  @override
  String get transaction => 'Transaction';

  @override
  String get tripHistory => 'Trip history';

  @override
  String get couldNotLoadTripHistory => 'Could not load trip history';

  @override
  String get totalEarned => 'Total earned';

  @override
  String get allTrips => 'All trips';

  @override
  String get unknownDestination => 'Unknown destination';

  @override
  String get unknownPickup => 'Unknown pickup';

  @override
  String get pickupUnknown => 'Pickup unknown';

  @override
  String fromPickup(String pickup) {
    return 'From $pickup';
  }

  @override
  String get completedCancelledRidesAppearHere =>
      'Your completed and cancelled rides will appear here.';

  @override
  String failedToLoadTrip(String error) {
    return 'Failed to load trip: $error';
  }

  @override
  String durationMin(String n) {
    return '$n min';
  }

  @override
  String get openRouteInMaps => 'Open route in Maps';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get signOutNeedSignBackIn =>
      'You will need to sign back in to receive ride requests.';

  @override
  String get couldNotLoadProfile => 'Could not load profile';

  @override
  String get driverFallbackName => 'Driver';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get makeAndModel => 'Make & model';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get myDocuments => 'My documents';

  @override
  String get viewUploadedPapers => 'View uploaded verification papers';

  @override
  String get privacyAndSecurity => 'Privacy & security';

  @override
  String get manageAccountSafety => 'Manage your account safety';

  @override
  String get personalDetails => 'Personal details';

  @override
  String get vehicleMake => 'Vehicle make';

  @override
  String get vehicleModel => 'Vehicle model';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get couldNotLoadDocuments => 'Could not load documents';

  @override
  String get documentsVerified => 'Your documents are verified.';

  @override
  String get documentsAwaitingReview =>
      'Documents submitted — awaiting admin review.';

  @override
  String get uploadDocsToStartEarning =>
      'Upload your documents to start earning.';

  @override
  String get noDocumentsYet => 'No documents yet';

  @override
  String get uploadLicenceRegId =>
      'Upload your licence, registration, and ID to get approved.';

  @override
  String get uploadDocuments => 'Upload documents';

  @override
  String get submittedFiles => 'Submitted files';

  @override
  String get updateDocuments => 'Update documents';

  @override
  String documentNotUploaded(String label) {
    return '$label — not uploaded';
  }

  @override
  String get passwordMinEightChars => 'Password must be at least 8 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get requestAccountDeletion => 'Request account deletion';

  @override
  String get accountProtectedNeverSharePassword =>
      'Your account is protected with secure sign-in. Never share your password with anyone.';

  @override
  String get signInSection => 'Sign-in';

  @override
  String get notLinked => 'Not linked';

  @override
  String get verified => 'Verified';

  @override
  String get unverified => 'Unverified';

  @override
  String get changePassword => 'Change password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get policies => 'Policies';

  @override
  String get termsAndPolicies => 'Terms & policies';

  @override
  String get howRawanaOperates => 'How Rawana operates';

  @override
  String get driverGuidelines => 'Driver guidelines';

  @override
  String get bestPracticesOnPlatform => 'Best practices on the platform';

  @override
  String get teamWillProcessRequest => 'Our team will process your request';

  @override
  String get supportEmailFallback => 'Email: support@rawana.af';

  @override
  String get support => 'Support';

  @override
  String get getHelp => 'Get help';

  @override
  String get reportATripIssue => 'Report a trip issue';

  @override
  String get lostItemWrongFareRoute => 'Lost item, wrong fare, route problem';

  @override
  String get reportASafetyConcern => 'Report a safety concern';

  @override
  String get tellUsUnsafeBehaviour => 'Tell us about unsafe behaviour';

  @override
  String get contactAdmin => 'Contact admin';

  @override
  String get emailOurSupportTeam => 'Email our support team';

  @override
  String get resources => 'Resources';

  @override
  String get bestPracticesKeepRatingHigh =>
      'Best practices to keep your rating high';

  @override
  String get myReports => 'My reports';

  @override
  String couldNotLoadReports(String error) {
    return 'Could not load your reports: $error';
  }

  @override
  String get noSupportReportsYet =>
      'No support reports yet. Use the options above if you need help.';

  @override
  String get supportTicket => 'Support ticket';

  @override
  String get ticketStatusOpen => 'open';

  @override
  String get weHaveYourBack => 'We have your back';

  @override
  String get getHelp247 => 'Get help from our team, 24/7.';

  @override
  String get couldNotLoadTrips => 'Could not load trips';

  @override
  String get completeRideThenReport =>
      'Complete a ride first, then you can report an issue here.';

  @override
  String get selectTripNeedHelp => 'Select the trip you need help with';

  @override
  String get generalIssueNoTrip => 'General issue (no trip)';

  @override
  String get notificationsEmptyMessage =>
      'Ride requests, payout updates, and announcements\nwill appear here.';

  @override
  String get performance => 'Performance';

  @override
  String get couldNotLoadPerformance => 'Could not load performance';

  @override
  String get serviceMetrics => 'Service metrics';

  @override
  String get acceptanceRate => 'Acceptance rate';

  @override
  String get cancellationRate => 'Cancellation rate';

  @override
  String get totalTrips => 'Total trips';

  @override
  String get onlineTime => 'Online time';

  @override
  String hoursShort(String h) {
    return '${h}h';
  }

  @override
  String hoursMinutesShort(String h, String m) {
    return '${h}h ${m}m';
  }

  @override
  String get averageRiderRating => 'Average rider rating';

  @override
  String get higherAcceptanceLowerCancelTip =>
      'Higher acceptance and lower cancellation rates help you get more ride requests.';

  @override
  String get cancelReasonNotAtPickup => 'Passenger not at pickup';

  @override
  String get cancelReasonWrongPickup => 'Wrong pickup location';

  @override
  String get cancelReasonSafety => 'Safety concern';

  @override
  String get cancelReasonVehicle => 'Vehicle issue';

  @override
  String get cancelReasonEmergency => 'Personal emergency';

  @override
  String get cancelReasonNoShow => 'Passenger no-show';

  @override
  String get noFeePassengerNoShow =>
      'No cancellation fee — passenger did not show up after the waiting period.';

  @override
  String get cancellationFeeMayApply =>
      'A cancellation fee may apply if you cancel now.';

  @override
  String get reason => 'REASON';

  @override
  String get waitingPeriodEndedNoFee =>
      'Waiting period ended. You may cancel without a fee if the passenger did not show.';

  @override
  String freeWaitRemaining(String time) {
    return 'Free wait: $time remaining';
  }

  @override
  String get passengerNoShowWindow => 'Passenger no-show window';

  @override
  String cancelWithoutFeeIn(String time) {
    return 'Cancel without fee in $time';
  }

  @override
  String get arrived => 'Arrived';

  @override
  String get trip => 'Trip';

  @override
  String get done => 'Done';

  @override
  String get accountNotRegisteredAsDriver =>
      'This account is not registered as a driver. Sign in with your driver account.';

  @override
  String get sessionExpiredSignInAgain =>
      'Session expired. Sign out and sign in again.';

  @override
  String get driverProfileNotFound =>
      'Driver profile not found. Complete document upload first.';

  @override
  String get cannotReachRawanaServer =>
      'Cannot reach the Rawana server. Check your connection and try again.';

  @override
  String get couldNotLoadDriverProfile => 'Could not load driver profile.';

  @override
  String get driverGuideProfessionalTitle => 'Stay professional';

  @override
  String get driverGuideProfessionalBody =>
      'Greet passengers politely, keep your vehicle clean, and follow local traffic laws. A calm, respectful attitude is the fastest way to earn five-star ratings.';

  @override
  String get driverGuideAcceptTitle => 'Accept rides promptly';

  @override
  String get driverGuideAcceptBody =>
      'High acceptance rates help you receive more requests. Only go online when you are ready to drive. If you must decline, do it quickly so the passenger can find another driver.';

  @override
  String get driverGuideNavigateTitle => 'Navigate accurately';

  @override
  String get driverGuideNavigateBody =>
      'Use the in-app route to pickup and drop-off. Confirm the destination with the passenger before starting the trip. If the address is unclear, call or message through the app.';

  @override
  String get driverGuideSafetyTitle => 'Safety first';

  @override
  String get driverGuideSafetyBody =>
      'Do not drive tired or under the influence. Report safety concerns immediately through Support. In an emergency, contact local authorities first, then notify Rawana.';

  @override
  String get driverGuideFaresTitle => 'Fares & payments';

  @override
  String get driverGuideFaresBody =>
      'Fares are calculated automatically from distance, time, and zone pricing. Do not ask passengers for extra cash unless agreed in the app. Earnings appear in your wallet after each completed trip.';

  @override
  String get driverGuideCancellationsTitle => 'Cancellations';

  @override
  String get driverGuideCancellationsBody =>
      'Avoid cancelling after accepting a ride. Frequent cancellations lower your performance score and may reduce future requests. Cancel only when necessary and add a clear reason.';

  @override
  String get termsDriverAgreement => 'Driver agreement';

  @override
  String get termsDriverAgreementBody =>
      'By using Rawana Driver you agree to provide ride-hailing services in line with platform rules, local regulations, and the documents you submitted during onboarding.';

  @override
  String get termsAccountVerification => 'Account & verification';

  @override
  String get termsAccountVerificationBody =>
      'You must keep your licence, vehicle registration, and identity documents valid and up to date. Rawana may suspend accounts with expired or fraudulent documents.';

  @override
  String get termsEarningsPayouts => 'Earnings & payouts';

  @override
  String get termsEarningsPayoutsBody =>
      'Trip fares are credited to your wallet minus Rawana\'s commission. Payout requests are processed according to finance team schedules. Fraudulent activity may result in withheld balances.';

  @override
  String get termsPrivacy => 'Privacy';

  @override
  String get termsPrivacyBody =>
      'We collect location while you are online, trip history, and contact details to operate the service. Passenger phone numbers may be masked during active trips. See Privacy & security in your profile for account controls.';

  @override
  String get termsConductSuspension => 'Conduct & suspension';

  @override
  String get termsConductSuspensionBody =>
      'Harassment, discrimination, unsafe driving, or repeated complaints can lead to temporary suspension or permanent removal from the platform.';

  @override
  String get termsSupport => 'Support';

  @override
  String get termsSupportBody =>
      'For disputes, safety reports, or account help, use in-app Support or email support@rawana.af. We aim to respond to urgent safety issues as quickly as possible.';

  @override
  String get noCancellationFee => 'No cancellation fee';

  @override
  String cancellationFeeAmount(String amount) {
    return 'Cancellation fee: $amount';
  }

  @override
  String get cancelSearchTitle => 'Cancel this request?';

  @override
  String get cancelSearchBody =>
      'You can request another ride right away. There is no fee while we are still finding a driver.';

  @override
  String collectCashAmount(String amount) {
    return 'Collect $amount cash';
  }

  @override
  String get cashCollected => 'Cash collected';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String tooFarContinueAnyway(String distance) {
    return 'You are $distance m from the pin. Continue anyway?';
  }

  @override
  String get continueAnyway => 'Continue anyway';

  @override
  String payDriverCashAmount(String amount) {
    return 'Pay your driver $amount cash';
  }

  @override
  String get cashSelectedInfo => 'Cash · AFN — pay your driver at drop-off';

  @override
  String get cashFare => 'Cash fare';

  @override
  String get rideType => 'Ride type';

  @override
  String get selectRideType => 'Which rides should you receive?';

  @override
  String get fareBreakdown => 'Fare breakdown';

  @override
  String get baseFare => 'Base fare';

  @override
  String distanceFare(String km) {
    return 'Distance · $km km';
  }

  @override
  String timeFare(String minutes) {
    return 'Time · $minutes min';
  }

  @override
  String get taxLabel => 'Tax';

  @override
  String get totalCash => 'Total cash';

  @override
  String cancelGraceSeconds(String seconds) {
    return 'Free to cancel for the first $seconds seconds after a driver accepts.';
  }

  @override
  String get maxEmergencyContacts => 'You can save up to 3 emergency contacts.';

  @override
  String get maxContactsReached => 'Maximum of 3 emergency contacts reached.';

  @override
  String get useThisLocation => 'Use this location';

  @override
  String get chooseSavedPlace => 'Choose location';

  @override
  String get vehicleYear => 'Vehicle year';

  @override
  String get vehicleColour => 'Vehicle colour';

  @override
  String get openInWaze => 'Open in Waze';

  @override
  String get chooseMapsApp => 'Open in maps';

  @override
  String get findingAnotherDriver =>
      'Your previous driver cancelled. We are finding you another driver.';

  @override
  String get filterFrom => 'From date';

  @override
  String get filterTo => 'To date';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get accountBlocked => 'This account is blocked and cannot book rides.';

  @override
  String get editName => 'Edit name';

  @override
  String get promoCode => 'Promo code';

  @override
  String get applyPromo => 'Apply';

  @override
  String get promoApplied => 'Promo applied';

  @override
  String get promoInvalid => 'This promo code is not valid.';

  @override
  String get promoExpired => 'This promo code has expired.';

  @override
  String get discount => 'Discount';

  @override
  String get writeAReview => 'Write a review (optional)';

  @override
  String get ratingCommentHint => 'How was the trip?';

  @override
  String get tripReceipt => 'Trip receipt';

  @override
  String get viewReceipt => 'View receipt';

  @override
  String get maintenanceTitle => 'We’ll be back shortly';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String get forceUpdateBody => 'Please update Rawana to continue.';

  @override
  String get updateApp => 'Update app';

  @override
  String get exportMyData => 'Download my data';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Delete this account? This cannot be undone.';

  @override
  String get deleteAccountWarning =>
      'Your profile and saved places will be removed. Trip records are kept for legal and safety reasons.';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get dataExported => 'Your data file is ready.';

  @override
  String get sos => 'SOS';

  @override
  String get sosConfirm => 'Send your live location to emergency contacts?';

  @override
  String get sosSent => 'Emergency alert sent.';

  @override
  String get sosFailed => 'Could not send SOS. Share your trip instead.';

  @override
  String get sosNoContacts => 'Add an emergency contact first.';

  @override
  String get sendSos => 'Send SOS';

  @override
  String get yourTickets => 'Your tickets';

  @override
  String get noTickets => 'No support tickets yet';

  @override
  String get reply => 'Reply';

  @override
  String get sendReply => 'Send reply';

  @override
  String get recentRatings => 'Recent ratings';

  @override
  String get noRatingsYet => 'No written ratings yet';

  @override
  String get lowRatingAlert =>
      'Your rating is below the platform threshold. Focus on safe, on-time trips.';

  @override
  String get highCancelAlert =>
      'Your cancellation rate is high. Accepting more trips protects your account.';

  @override
  String typicalDriverRating(String rating) {
    return 'Nearby drivers avg. $rating';
  }

  @override
  String get tooManyCancellations =>
      'You have reached today’s cancellation limit. Try again tomorrow.';

  @override
  String get markAllRead => 'Mark read';

  @override
  String emergencyContactsCount(String count, String max) {
    return '$count of $max contacts';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String get payoutMethod => 'Payout method';

  @override
  String get payoutAccount => 'Account number';

  @override
  String get savePayoutDetails => 'Save payout details';

  @override
  String get payoutDetailsSaved => 'Payout details saved';

  @override
  String tooFarFromPickup(String distance, String required) {
    return 'You are $distance m from the pickup point. Move within $required m to confirm arrival.';
  }

  @override
  String tooFarFromDropoff(String distance, String required) {
    return 'You are $distance m from the drop-off point. Move within $required m to complete the trip.';
  }

  @override
  String get rideCancelledByPassenger => 'The passenger cancelled this ride.';

  @override
  String get rideCancelledBySupport =>
      'This ride was cancelled by Rawana support.';

  @override
  String get rideCancelledByDriver =>
      'Your driver cancelled. We are finding you another driver.';

  @override
  String get rideCancelledNoDrivers =>
      'No drivers were available for this ride.';

  @override
  String get rideCancelledGeneric => 'This ride was cancelled.';

  @override
  String get rateLastTripTitle => 'How was your last ride?';

  @override
  String rateLastTripBody(String destination) {
    return 'Rate your trip to $destination to help us keep drivers great.';
  }

  @override
  String get rateNow => 'Rate now';

  @override
  String get resumingActiveTrip =>
      'You already have a ride in progress. Taking you back to it.';

  @override
  String get youKeep => 'YOU KEEP';

  @override
  String get commissionOwedToRawana => 'Commission owed to Rawana';

  @override
  String get outstandingFeeCollected => 'Cancellation fee collected for Rawana';

  @override
  String get totalCashToCollect => 'Total cash to collect';

  @override
  String get amountOwedToRawana => 'You owe Rawana';

  @override
  String get creditFromRawana => 'Rawana owes you';

  @override
  String get balanceSettled => 'All settled';

  @override
  String get balanceSettledBody => 'You have no commission to pay right now.';

  @override
  String debtLimitLabel(String amount) {
    return 'Limit $amount';
  }

  @override
  String get debtLimitReachedTitle => 'Settle your balance to keep driving';

  @override
  String debtLimitReachedBody(String owed, String limit) {
    return 'You owe $owed. Drivers over the $limit limit cannot go online until finance records a payment.';
  }

  @override
  String get howToSettle => 'How to pay Rawana';

  @override
  String get walletCashFirstExplainer =>
      'You keep every fare in cash. Rawana\'s commission is added to your balance here and you settle it with finance.';

  @override
  String outstandingFeeIncluded(String amount) {
    return 'Includes $amount unpaid cancellation fee from a previous ride';
  }

  @override
  String cancellationFeeChargedNextRide(String amount) {
    return 'A $amount cancellation fee will be added to your next ride.';
  }

  @override
  String get txCommission => 'Commission';

  @override
  String get txSettlement => 'Payment to Rawana';

  @override
  String get txCancellationFee => 'Cancellation fee compensation';

  @override
  String get txFeeCollected => 'Cancellation fee collected';

  @override
  String get txPayout => 'Payout';

  @override
  String get txAdjustment => 'Adjustment';

  @override
  String get txCashCollected => 'Cash fare (kept by you)';
}
