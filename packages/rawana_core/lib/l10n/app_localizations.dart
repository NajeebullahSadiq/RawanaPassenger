import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_ps.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
    Locale('ps'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Rawana'**
  String get appName;

  /// No description provided for @appTitlePassenger.
  ///
  /// In en, this message translates to:
  /// **'Rawana Passenger'**
  String get appTitlePassenger;

  /// No description provided for @appTitleDriver.
  ///
  /// In en, this message translates to:
  /// **'Rawana Driver'**
  String get appTitleDriver;

  /// No description provided for @appVersionFooter.
  ///
  /// In en, this message translates to:
  /// **'Rawana · v1.0'**
  String get appVersionFooter;

  /// No description provided for @rawanaDriver.
  ///
  /// In en, this message translates to:
  /// **'Rawana Driver'**
  String get rawanaDriver;

  /// No description provided for @rawanaDriverVersion.
  ///
  /// In en, this message translates to:
  /// **'Rawana Driver  v1.0'**
  String get rawanaDriverVersion;

  /// No description provided for @rawanaDriverRole.
  ///
  /// In en, this message translates to:
  /// **'Rawana driver'**
  String get rawanaDriverRole;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Smooth rides, anywhere in Kabul'**
  String get splashTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your ride…'**
  String get splashLoading;

  /// No description provided for @driverBadge.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get driverBadge;

  /// No description provided for @riderBadge.
  ///
  /// In en, this message translates to:
  /// **'RIDER'**
  String get riderBadge;

  /// No description provided for @preparingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Preparing your dashboard'**
  String get preparingDashboard;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @requesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting…'**
  String get requesting;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming...'**
  String get confirming;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @errorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetail(String error);

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @confirmRide.
  ///
  /// In en, this message translates to:
  /// **'Confirm Ride'**
  String get confirmRide;

  /// No description provided for @findingDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding your driver…'**
  String get findingDriver;

  /// No description provided for @findingYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding your driver'**
  String get findingYourDriver;

  /// No description provided for @driverArriving.
  ///
  /// In en, this message translates to:
  /// **'Driver Arriving'**
  String get driverArriving;

  /// No description provided for @tripStarted.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get tripStarted;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip Completed'**
  String get tripCompleted;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} in cash'**
  String payCash(String amount);

  /// No description provided for @currencyAfn.
  ///
  /// In en, this message translates to:
  /// **'AFN'**
  String get currencyAfn;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyOtp;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get goOnline;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go offline'**
  String get goOffline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @cancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get cancelRide;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noConnection;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// No description provided for @youAreOfflineReconnect.
  ///
  /// In en, this message translates to:
  /// **'You are offline — reconnect to continue'**
  String get youAreOfflineReconnect;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseYourLanguage;

  /// No description provided for @languageChangeHint.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime from settings.'**
  String get languageChangeHint;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDari.
  ///
  /// In en, this message translates to:
  /// **'دری'**
  String get languageDari;

  /// No description provided for @languagePashto.
  ///
  /// In en, this message translates to:
  /// **'پښتو'**
  String get languagePashto;

  /// No description provided for @languageEnglishMeta.
  ///
  /// In en, this message translates to:
  /// **'LTR · Latin'**
  String get languageEnglishMeta;

  /// No description provided for @languageDariMeta.
  ///
  /// In en, this message translates to:
  /// **'RTL · Dari'**
  String get languageDariMeta;

  /// No description provided for @languagePashtoMeta.
  ///
  /// In en, this message translates to:
  /// **'RTL · Pashto'**
  String get languagePashtoMeta;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Book a ride in seconds'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Set your destination and confirm — the nearest driver will be on the way.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Track every kilometre'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'See your driver approach in real time on the map, and share trip status with loved ones.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Cash made simple'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Pay your driver directly in Afghan Afghani (AFN) when you arrive. No card needed.'**
  String get onboardingSlide3Body;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get continueWithPhone;

  /// No description provided for @authTermsFooter.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy Policy.'**
  String get authTermsFooter;

  /// No description provided for @agreeTermsConduct.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Driver Code of Conduct.'**
  String get agreeTermsConduct;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @welcomeBackCaptain.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, captain'**
  String get welcomeBackCaptain;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few details and you are ready to ride.'**
  String get signUpSubtitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep riding.'**
  String get signInSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name *'**
  String get fullNameRequired;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number *'**
  String get phoneNumberRequired;

  /// No description provided for @afPhonePrefix.
  ///
  /// In en, this message translates to:
  /// **'🇦🇫 +93'**
  String get afPhonePrefix;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'70 123 4567'**
  String get phoneHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @newHereCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newHereCreateAccount;

  /// No description provided for @phoneOtpComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Phone OTP will be enabled in production.'**
  String get phoneOtpComingSoon;

  /// No description provided for @authEntryHeadline.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you\nmoving.'**
  String get authEntryHeadline;

  /// No description provided for @authEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to book rides across Kabul in seconds.'**
  String get authEntrySubtitle;

  /// No description provided for @authValueFastTitle.
  ///
  /// In en, this message translates to:
  /// **'Fast booking'**
  String get authValueFastTitle;

  /// No description provided for @authValueFastBody.
  ///
  /// In en, this message translates to:
  /// **'Find a nearby driver in under a minute.'**
  String get authValueFastBody;

  /// No description provided for @authValueTrustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted drivers'**
  String get authValueTrustedTitle;

  /// No description provided for @authValueTrustedBody.
  ///
  /// In en, this message translates to:
  /// **'Every driver is verified and rated.'**
  String get authValueTrustedBody;

  /// No description provided for @authValuePayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay in AFN cash'**
  String get authValuePayTitle;

  /// No description provided for @authValuePayBody.
  ///
  /// In en, this message translates to:
  /// **'No card required — pay at trip end.'**
  String get authValuePayBody;

  /// No description provided for @driveWithRawana.
  ///
  /// In en, this message translates to:
  /// **'Drive with\nRawana.'**
  String get driveWithRawana;

  /// No description provided for @signInEmailToTest.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email to test the driver experience.'**
  String get signInEmailToTest;

  /// No description provided for @earnOnYourSchedule.
  ///
  /// In en, this message translates to:
  /// **'Earn on your own schedule. Get verified, get rides, get paid.'**
  String get earnOnYourSchedule;

  /// No description provided for @earnFlexibly.
  ///
  /// In en, this message translates to:
  /// **'Earn flexibly'**
  String get earnFlexibly;

  /// No description provided for @goOnlineWhenever.
  ///
  /// In en, this message translates to:
  /// **'Go online whenever you want.'**
  String get goOnlineWhenever;

  /// No description provided for @dailyPayouts.
  ///
  /// In en, this message translates to:
  /// **'Daily payouts'**
  String get dailyPayouts;

  /// No description provided for @trackEveryFare.
  ///
  /// In en, this message translates to:
  /// **'Track every fare in your wallet.'**
  String get trackEveryFare;

  /// No description provided for @driverSupport.
  ///
  /// In en, this message translates to:
  /// **'Driver support'**
  String get driverSupport;

  /// No description provided for @supportTeam247.
  ///
  /// In en, this message translates to:
  /// **'A team that has your back, 24/7.'**
  String get supportTeam247;

  /// No description provided for @becomeADriver.
  ///
  /// In en, this message translates to:
  /// **'Become a driver'**
  String get becomeADriver;

  /// No description provided for @createDriverAccountInAMinute.
  ///
  /// In en, this message translates to:
  /// **'Create your driver account in a minute.'**
  String get createDriverAccountInAMinute;

  /// No description provided for @signInToGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Sign in to go online.'**
  String get signInToGoOnline;

  /// No description provided for @createDriverAccount.
  ///
  /// In en, this message translates to:
  /// **'Create driver account'**
  String get createDriverAccount;

  /// No description provided for @alreadyADriverSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already a driver? Sign in'**
  String get alreadyADriverSignIn;

  /// No description provided for @newDriverCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New driver? Create account'**
  String get newDriverCreateAccount;

  /// No description provided for @enterYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone'**
  String get enterYourPhone;

  /// No description provided for @phoneVerifyHint.
  ///
  /// In en, this message translates to:
  /// **'We will send a 6-digit code to verify it is really you.'**
  String get phoneVerifyHint;

  /// No description provided for @phoneKeepsAccountSecure.
  ///
  /// In en, this message translates to:
  /// **'We use this to keep your driver account secure.'**
  String get phoneKeepsAccountSecure;

  /// No description provided for @otpChannelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get otpChannelSms;

  /// No description provided for @otpChannelWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get otpChannelWhatsApp;

  /// No description provided for @otpSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Go back and request a new code.'**
  String get otpSessionExpired;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @otpEnterCodeVia.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent via {channel}.'**
  String otpEnterCodeVia(String channel);

  /// No description provided for @otpEnterCodeViaTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent via {channel} to {phone}.'**
  String otpEnterCodeViaTo(String channel, String phone);

  /// No description provided for @resendCodeInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeInSeconds(String seconds);

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox.'**
  String get verificationEmailSent;

  /// No description provided for @emailNotVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet. Check your inbox and try again.'**
  String get emailNotVerifiedYet;

  /// No description provided for @checkYourInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get checkYourInbox;

  /// No description provided for @weSentVerificationLinkTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to '**
  String get weSentVerificationLinkTo;

  /// No description provided for @yourEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get yourEmailFallback;

  /// No description provided for @tapLinkThenContinue.
  ///
  /// In en, this message translates to:
  /// **'. Tap the link to verify, then come back here to continue.'**
  String get tapLinkThenContinue;

  /// No description provided for @tapLinkThenContinueOnboarding.
  ///
  /// In en, this message translates to:
  /// **'. Tap the link to verify, then come back here to continue onboarding.'**
  String get tapLinkThenContinueOnboarding;

  /// No description provided for @checkSpamTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: check your spam or promotions folder if you do not see it.'**
  String get checkSpamTip;

  /// No description provided for @iHaveVerifiedContinue.
  ///
  /// In en, this message translates to:
  /// **'I have verified - continue'**
  String get iHaveVerifiedContinue;

  /// No description provided for @resendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerificationEmail;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @quickDemoAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Demo Access'**
  String get quickDemoAccess;

  /// No description provided for @demoLoginNeedsSupabase.
  ///
  /// In en, this message translates to:
  /// **'Supabase is required for demo login. Add SUPABASE_URL and SUPABASE_ANON_KEY.'**
  String get demoLoginNeedsSupabase;

  /// No description provided for @demoLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Demo login failed. Check demo credentials in rawana_core.'**
  String get demoLoginFailed;

  /// No description provided for @authSupabaseNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not configured. Contact support.'**
  String get authSupabaseNotConfigured;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please check and try again.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before signing in.'**
  String get authEmailNotVerified;

  /// No description provided for @authEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Try signing in instead.'**
  String get authEmailAlreadyExists;

  /// No description provided for @authRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute and try again.'**
  String get authRateLimit;

  /// No description provided for @authDatabaseSignupFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not create your account because of a server error. Please try again in a moment.'**
  String get authDatabaseSignupFailed;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 8 characters with letters and numbers.'**
  String get authWeakPassword;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authInvalidEmail;

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Afghan phone number (9 digits, e.g. 70 123 4567).'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect or expired. Request a new code and try again.'**
  String get authInvalidOtp;

  /// No description provided for @authWhatsAppUnavailable.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp sign-in is not available right now.'**
  String get authWhatsAppUnavailable;

  /// No description provided for @authGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authGenericError;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfile;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get almostThere;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your name and phone so your driver can reach you.'**
  String get profileSetupSubtitle;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed: {error}'**
  String photoUploadFailed(String error);

  /// No description provided for @driverRegistration.
  ///
  /// In en, this message translates to:
  /// **'Driver registration'**
  String get driverRegistration;

  /// No description provided for @yourDetails.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get yourDetails;

  /// No description provided for @needNameAndPhoneBeforeDocs.
  ///
  /// In en, this message translates to:
  /// **'Passengers and support need your name and phone before you can upload documents.'**
  String get needNameAndPhoneBeforeDocs;

  /// No description provided for @continueToDocuments.
  ///
  /// In en, this message translates to:
  /// **'Continue to documents'**
  String get continueToDocuments;

  /// No description provided for @gettingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get gettingYourLocation;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location…'**
  String get gettingLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @waitingForLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your location…'**
  String get waitingForLocation;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @greetingNameFallback.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get greetingNameFallback;

  /// No description provided for @navRide.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get navRide;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @viewSearch.
  ///
  /// In en, this message translates to:
  /// **'View search'**
  String get viewSearch;

  /// No description provided for @viewRide.
  ///
  /// In en, this message translates to:
  /// **'View ride'**
  String get viewRide;

  /// No description provided for @searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Search destination'**
  String get searchDestination;

  /// No description provided for @quickHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get quickHome;

  /// No description provided for @quickWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get quickWork;

  /// No description provided for @quickSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get quickSaved;

  /// No description provided for @gpsLocked.
  ///
  /// In en, this message translates to:
  /// **'GPS LOCKED'**
  String get gpsLocked;

  /// No description provided for @gpsAcquiring.
  ///
  /// In en, this message translates to:
  /// **'ACQUIRING'**
  String get gpsAcquiring;

  /// No description provided for @gpsBlocked.
  ///
  /// In en, this message translates to:
  /// **'GPS BLOCKED'**
  String get gpsBlocked;

  /// No description provided for @pickupLabel.
  ///
  /// In en, this message translates to:
  /// **'PICKUP'**
  String get pickupLabel;

  /// No description provided for @destinationLabel.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION'**
  String get destinationLabel;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get currentLabel;

  /// No description provided for @driverOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Driver on the way'**
  String get driverOnTheWay;

  /// No description provided for @driverIsArriving.
  ///
  /// In en, this message translates to:
  /// **'Driver is arriving'**
  String get driverIsArriving;

  /// No description provided for @onTripToDestination.
  ///
  /// In en, this message translates to:
  /// **'On trip to destination'**
  String get onTripToDestination;

  /// No description provided for @rideInProgress.
  ///
  /// In en, this message translates to:
  /// **'Ride in progress'**
  String get rideInProgress;

  /// No description provided for @noSavedAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'No {label} address'**
  String noSavedAddressTitle(String label);

  /// No description provided for @noSavedAddressBody.
  ///
  /// In en, this message translates to:
  /// **'Add a saved address labeled \"{label}\" first.'**
  String noSavedAddressBody(String label);

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @invalidSavedAddressCoords.
  ///
  /// In en, this message translates to:
  /// **'Invalid saved address coordinates'**
  String get invalidSavedAddressCoords;

  /// No description provided for @kabulFallbackPickup.
  ///
  /// In en, this message translates to:
  /// **'Kabul (set exact pickup on map)'**
  String get kabulFallbackPickup;

  /// No description provided for @locationUnavailableEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Enable GPS or tap pickup to choose on the map.'**
  String get locationUnavailableEnableGps;

  /// No description provided for @choosePickupFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose your pickup location first'**
  String get choosePickupFirst;

  /// No description provided for @choosePickupFirstShort.
  ///
  /// In en, this message translates to:
  /// **'Choose your pickup first'**
  String get choosePickupFirstShort;

  /// No description provided for @couldNotSelectPlace.
  ///
  /// In en, this message translates to:
  /// **'Could not select place. Try again.'**
  String get couldNotSelectPlace;

  /// No description provided for @selectedPickup.
  ///
  /// In en, this message translates to:
  /// **'Selected pickup'**
  String get selectedPickup;

  /// No description provided for @selectedDestination.
  ///
  /// In en, this message translates to:
  /// **'Selected destination'**
  String get selectedDestination;

  /// No description provided for @enableLocationToBook.
  ///
  /// In en, this message translates to:
  /// **'Enable location to book a ride'**
  String get enableLocationToBook;

  /// No description provided for @planYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan your trip'**
  String get planYourTrip;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @popularPlaces.
  ///
  /// In en, this message translates to:
  /// **'POPULAR PLACES'**
  String get popularPlaces;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTIONS'**
  String get suggestions;

  /// No description provided for @editPickup.
  ///
  /// In en, this message translates to:
  /// **'Edit pickup'**
  String get editPickup;

  /// No description provided for @searchPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Search pickup location'**
  String get searchPickupLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get chooseOnMap;

  /// No description provided for @movePinToPickup.
  ///
  /// In en, this message translates to:
  /// **'Move the pin to your exact pickup'**
  String get movePinToPickup;

  /// No description provided for @startTyping.
  ///
  /// In en, this message translates to:
  /// **'Start typing'**
  String get startTyping;

  /// No description provided for @weWillSuggestPlaces.
  ///
  /// In en, this message translates to:
  /// **'We will suggest places near you'**
  String get weWillSuggestPlaces;

  /// No description provided for @dropPinDestination.
  ///
  /// In en, this message translates to:
  /// **'Drop a pin exactly where you want to go'**
  String get dropPinDestination;

  /// No description provided for @moveMapToChoose.
  ///
  /// In en, this message translates to:
  /// **'Move the map to choose a location'**
  String get moveMapToChoose;

  /// No description provided for @choosePickup.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup'**
  String get choosePickup;

  /// No description provided for @chooseDestination.
  ///
  /// In en, this message translates to:
  /// **'Choose destination'**
  String get chooseDestination;

  /// No description provided for @useThisPickup.
  ///
  /// In en, this message translates to:
  /// **'Use this pickup'**
  String get useThisPickup;

  /// No description provided for @useThisDestination.
  ///
  /// In en, this message translates to:
  /// **'Use this destination'**
  String get useThisDestination;

  /// No description provided for @tapOrDragMap.
  ///
  /// In en, this message translates to:
  /// **'Tap or drag the map, then confirm.'**
  String get tapOrDragMap;

  /// No description provided for @failedToLoadRideTypes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ride types: {error}'**
  String failedToLoadRideTypes(String error);

  /// No description provided for @noRideTypesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No ride types available'**
  String get noRideTypesAvailable;

  /// No description provided for @pickupConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Pickup confirmed'**
  String get pickupConfirmed;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @dropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get dropoff;

  /// No description provided for @chooseYourRide.
  ///
  /// In en, this message translates to:
  /// **'Choose your ride'**
  String get chooseYourRide;

  /// No description provided for @etaMinToDestination.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min to destination'**
  String etaMinToDestination(String minutes);

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @cashAfn.
  ///
  /// In en, this message translates to:
  /// **'Cash · AFN'**
  String get cashAfn;

  /// No description provided for @paymentMethodConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment method confirmed'**
  String get paymentMethodConfirmed;

  /// No description provided for @tapToConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Tap to confirm payment at trip end'**
  String get tapToConfirmPayment;

  /// No description provided for @requestRideWithFare.
  ///
  /// In en, this message translates to:
  /// **'Request {name} · {fare}'**
  String requestRideWithFare(String name, String fare);

  /// No description provided for @confirmPaymentToContinue.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment to continue'**
  String get confirmPaymentToContinue;

  /// No description provided for @missingTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Missing trip details'**
  String get missingTripDetails;

  /// No description provided for @noDriversAvailable.
  ///
  /// In en, this message translates to:
  /// **'No drivers available right now. Please try again.'**
  String get noDriversAvailable;

  /// No description provided for @connectingToNearbyDrivers.
  ///
  /// In en, this message translates to:
  /// **'Connecting you to nearby drivers — usually under a minute.'**
  String get connectingToNearbyDrivers;

  /// No description provided for @retryOrCancelBelow.
  ///
  /// In en, this message translates to:
  /// **'You can retry or cancel below.'**
  String get retryOrCancelBelow;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @followingLiveRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Following live route. Tap ↓ to return to trip details.'**
  String get followingLiveRouteHint;

  /// No description provided for @couldNotOpenWhatsAppCall.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp call'**
  String get couldNotOpenWhatsAppCall;

  /// No description provided for @couldNotOpenWhatsAppMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp messages'**
  String get couldNotOpenWhatsAppMessages;

  /// No description provided for @cancelThisRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel this ride?'**
  String get cancelThisRide;

  /// No description provided for @cancelRideWarning.
  ///
  /// In en, this message translates to:
  /// **'Your driver will be notified. Repeated cancellations may incur a fee.'**
  String get cancelRideWarning;

  /// No description provided for @keepRide.
  ///
  /// In en, this message translates to:
  /// **'Keep ride'**
  String get keepRide;

  /// No description provided for @shareTripIntro.
  ///
  /// In en, this message translates to:
  /// **'I\'m on a Rawana trip.'**
  String get shareTripIntro;

  /// No description provided for @shareDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String shareDriver(String name);

  /// No description provided for @shareVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: {vehicle}'**
  String shareVehicle(String vehicle);

  /// No description provided for @sharePlate.
  ///
  /// In en, this message translates to:
  /// **'Plate: {plate}'**
  String sharePlate(String plate);

  /// No description provided for @shareFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {address}'**
  String shareFrom(String address);

  /// No description provided for @shareTo.
  ///
  /// In en, this message translates to:
  /// **'To: {address}'**
  String shareTo(String address);

  /// No description provided for @shareCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location: {url}'**
  String shareCurrentLocation(String url);

  /// No description provided for @shareTripSubject.
  ///
  /// In en, this message translates to:
  /// **'My Rawana trip'**
  String get shareTripSubject;

  /// No description provided for @driverConfirmedHeadingPickup.
  ///
  /// In en, this message translates to:
  /// **'Driver confirmed — heading to pickup'**
  String get driverConfirmedHeadingPickup;

  /// No description provided for @driverIsAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Driver is at your pickup'**
  String get driverIsAtPickup;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @yourDriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver'**
  String get yourDriver;

  /// No description provided for @followingYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Following your trip'**
  String get followingYourTrip;

  /// No description provided for @driverEnRouteToPickup.
  ///
  /// In en, this message translates to:
  /// **'Driver en route to pickup'**
  String get driverEnRouteToPickup;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @driverLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Driver live location'**
  String get driverLiveLocation;

  /// No description provided for @yourPickupSpot.
  ///
  /// In en, this message translates to:
  /// **'Your pickup spot'**
  String get yourPickupSpot;

  /// No description provided for @hintFollowLiveRoute.
  ///
  /// In en, this message translates to:
  /// **'Route line updates as your driver moves. Tap Start navigation to follow live.'**
  String get hintFollowLiveRoute;

  /// No description provided for @hintWatchDriverApproach.
  ///
  /// In en, this message translates to:
  /// **'Watch your driver approach on the map. ETA updates automatically.'**
  String get hintWatchDriverApproach;

  /// No description provided for @followTripRoute.
  ///
  /// In en, this message translates to:
  /// **'Follow trip route'**
  String get followTripRoute;

  /// No description provided for @followDriverToPickup.
  ///
  /// In en, this message translates to:
  /// **'Follow driver to pickup'**
  String get followDriverToPickup;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @shareTrip.
  ///
  /// In en, this message translates to:
  /// **'Share trip'**
  String get shareTrip;

  /// No description provided for @driverArrivedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your driver is at your pickup location.'**
  String get driverArrivedNotice;

  /// No description provided for @youHaveArrived.
  ///
  /// In en, this message translates to:
  /// **'You have arrived'**
  String get youHaveArrived;

  /// No description provided for @thanksForRiding.
  ///
  /// In en, this message translates to:
  /// **'Thank you for riding with Rawana.'**
  String get thanksForRiding;

  /// No description provided for @payYourDriver.
  ///
  /// In en, this message translates to:
  /// **'PAY YOUR DRIVER'**
  String get payYourDriver;

  /// No description provided for @howWasYourTrip.
  ///
  /// In en, this message translates to:
  /// **'How was your trip?'**
  String get howWasYourTrip;

  /// No description provided for @feedbackHelpsDrivers.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps drivers improve.'**
  String get feedbackHelpsDrivers;

  /// No description provided for @ratingTagCleanCar.
  ///
  /// In en, this message translates to:
  /// **'Clean car'**
  String get ratingTagCleanCar;

  /// No description provided for @ratingTagSafeDriving.
  ///
  /// In en, this message translates to:
  /// **'Safe driving'**
  String get ratingTagSafeDriving;

  /// No description provided for @ratingTagFriendlyDriver.
  ///
  /// In en, this message translates to:
  /// **'Friendly driver'**
  String get ratingTagFriendlyDriver;

  /// No description provided for @ratingTagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get ratingTagOnTime;

  /// No description provided for @ratingTagGoodNavigation.
  ///
  /// In en, this message translates to:
  /// **'Good navigation'**
  String get ratingTagGoodNavigation;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @skipRating.
  ///
  /// In en, this message translates to:
  /// **'Skip rating'**
  String get skipRating;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportAnIssue;

  /// No description provided for @ratingFailed.
  ///
  /// In en, this message translates to:
  /// **'Rating failed: {error}'**
  String ratingFailed(String error);

  /// No description provided for @tripTitleWithId.
  ///
  /// In en, this message translates to:
  /// **'Trip · {id}'**
  String tripTitleWithId(String id);

  /// No description provided for @tripSummary.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get tripSummary;

  /// No description provided for @totalFare.
  ///
  /// In en, this message translates to:
  /// **'Total fare'**
  String get totalFare;

  /// No description provided for @driverLabel.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get driverLabel;

  /// No description provided for @whatsAppDriver.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp driver'**
  String get whatsAppDriver;

  /// No description provided for @whatsAppCallDriver.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp call driver'**
  String get whatsAppCallDriver;

  /// No description provided for @rideHistory.
  ///
  /// In en, this message translates to:
  /// **'Ride history'**
  String get rideHistory;

  /// No description provided for @failedToLoadHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history: {error}'**
  String failedToLoadHistory(String error);

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @pastRidesHint.
  ///
  /// In en, this message translates to:
  /// **'Your past rides will appear here.'**
  String get pastRidesHint;

  /// No description provided for @fromAddress.
  ///
  /// In en, this message translates to:
  /// **'From {address}'**
  String fromAddress(String address);

  /// No description provided for @statusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get statusSearching;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusDriverArriving.
  ///
  /// In en, this message translates to:
  /// **'Driver arriving'**
  String get statusDriverArriving;

  /// No description provided for @statusTripStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip started'**
  String get statusTripStarted;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile: {error}'**
  String failedToLoadProfile(String error);

  /// No description provided for @passengerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get passengerFallbackName;

  /// No description provided for @tripsStat.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tripsStat;

  /// No description provided for @ratingStat.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get ratingStat;

  /// No description provided for @memberStat.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberStat;

  /// No description provided for @memberNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get memberNew;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get savedAddresses;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @safetyAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Safety & Support'**
  String get safetyAndSupport;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get emergencyContacts;

  /// No description provided for @helpCentre.
  ///
  /// In en, this message translates to:
  /// **'Help centre'**
  String get helpCentre;

  /// No description provided for @enableLocationToSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Enable location to save this address'**
  String get enableLocationToSaveAddress;

  /// No description provided for @saveANewAddress.
  ///
  /// In en, this message translates to:
  /// **'Save a new address'**
  String get saveANewAddress;

  /// No description provided for @usesCurrentGps.
  ///
  /// In en, this message translates to:
  /// **'Uses your current GPS location for coordinates.'**
  String get usesCurrentGps;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get addressLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Home, Work, Gym…'**
  String get addressLabelHint;

  /// No description provided for @addressField.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressField;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @failedToLoadAddresses.
  ///
  /// In en, this message translates to:
  /// **'Failed to load addresses: {error}'**
  String failedToLoadAddresses(String error);

  /// No description provided for @noSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses'**
  String get noSavedAddresses;

  /// No description provided for @savedAddressesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Save Home, Work and other places\nfor one-tap booking.'**
  String get savedAddressesEmptyHint;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Trip updates and promotions will appear here\nwhen push notifications are enabled.'**
  String get notificationsEmptyHint;

  /// No description provided for @needAHand.
  ///
  /// In en, this message translates to:
  /// **'Need a hand?'**
  String get needAHand;

  /// No description provided for @helpTeam247.
  ///
  /// In en, this message translates to:
  /// **'Our team is here to help, 24/7.'**
  String get helpTeam247;

  /// No description provided for @commonQuestions.
  ///
  /// In en, this message translates to:
  /// **'Common questions'**
  String get commonQuestions;

  /// No description provided for @faqBookTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I book a ride?'**
  String get faqBookTitle;

  /// No description provided for @faqBookBody.
  ///
  /// In en, this message translates to:
  /// **'Open the app, tap \"Where to?\", set your destination, choose a ride type, and confirm. Your nearest driver will be on the way.'**
  String get faqBookBody;

  /// No description provided for @faqPayTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I pay?'**
  String get faqPayTitle;

  /// No description provided for @faqPayBody.
  ///
  /// In en, this message translates to:
  /// **'Pay the driver in Afghan Afghani (AFN) cash at the end of your trip.'**
  String get faqPayBody;

  /// No description provided for @reportSafetyOrTripIssue.
  ///
  /// In en, this message translates to:
  /// **'Report a safety or trip issue'**
  String get reportSafetyOrTripIssue;

  /// No description provided for @addEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contact'**
  String get addEmergencyContact;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get saveContact;

  /// No description provided for @failedToLoadContacts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contacts: {error}'**
  String failedToLoadContacts(String error);

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContactsYet;

  /// No description provided for @emergencyContactsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 3 trusted contacts.\nThey will be notified during emergencies.'**
  String get emergencyContactsEmptyHint;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @estimatedFare.
  ///
  /// In en, this message translates to:
  /// **'Estimated fare'**
  String get estimatedFare;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get secondsShort;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(String meters);

  /// No description provided for @etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String etaMinutes(String minutes);

  /// No description provided for @routeDistance.
  ///
  /// In en, this message translates to:
  /// **'route distance'**
  String get routeDistance;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @endNavigation.
  ///
  /// In en, this message translates to:
  /// **'End navigation'**
  String get endNavigation;

  /// No description provided for @navigating.
  ///
  /// In en, this message translates to:
  /// **'Navigating'**
  String get navigating;

  /// No description provided for @followingSelectedRoute.
  ///
  /// In en, this message translates to:
  /// **'Following selected route'**
  String get followingSelectedRoute;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @routeShortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get routeShortest;

  /// No description provided for @routeFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get routeFastest;

  /// No description provided for @routeChipDurationDistance.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m · {km}km'**
  String routeChipDurationDistance(String minutes, String km);

  /// No description provided for @nearbyDriver.
  ///
  /// In en, this message translates to:
  /// **'Nearby driver'**
  String get nearbyDriver;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @passenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get passenger;

  /// No description provided for @activeRide.
  ///
  /// In en, this message translates to:
  /// **'Active ride'**
  String get activeRide;

  /// No description provided for @continueOnHighlightedRoute.
  ///
  /// In en, this message translates to:
  /// **'Continue on the highlighted route'**
  String get continueOnHighlightedRoute;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get startNavigation;

  /// No description provided for @issueWithTrip.
  ///
  /// In en, this message translates to:
  /// **'Issue with trip #{id}'**
  String issueWithTrip(String id);

  /// No description provided for @reportValidation.
  ///
  /// In en, this message translates to:
  /// **'Please add a subject and at least 10 characters of detail.'**
  String get reportValidation;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Our team will follow up.'**
  String get reportSubmitted;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit: {error}'**
  String failedToSubmit(String error);

  /// No description provided for @tripShortId.
  ///
  /// In en, this message translates to:
  /// **'Trip {id}'**
  String tripShortId(String id);

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @whatHappened.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get whatHappened;

  /// No description provided for @safetyReportPriority.
  ///
  /// In en, this message translates to:
  /// **'Safety reports are prioritised. If you are in immediate danger, contact local emergency services.'**
  String get safetyReportPriority;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @supportBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing / overcharge'**
  String get supportBilling;

  /// No description provided for @supportDriverBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Driver behaviour'**
  String get supportDriverBehaviour;

  /// No description provided for @supportSafetyConcern.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get supportSafetyConcern;

  /// No description provided for @supportTechnical.
  ///
  /// In en, this message translates to:
  /// **'App / technical issue'**
  String get supportTechnical;

  /// No description provided for @supportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportOther;

  /// No description provided for @supportFarePayment.
  ///
  /// In en, this message translates to:
  /// **'Fare / payment issue'**
  String get supportFarePayment;

  /// No description provided for @supportPassengerBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Passenger behaviour'**
  String get supportPassengerBehaviour;

  /// No description provided for @docDriverLicence.
  ///
  /// In en, this message translates to:
  /// **'Driver Licence'**
  String get docDriverLicence;

  /// No description provided for @docVehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration'**
  String get docVehicleRegistration;

  /// No description provided for @docNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get docNationalId;

  /// No description provided for @docProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get docProfilePhoto;

  /// No description provided for @docVehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Info'**
  String get docVehicleInfo;

  /// No description provided for @supabaseRequiredForUpload.
  ///
  /// In en, this message translates to:
  /// **'Supabase required for document upload'**
  String get supabaseRequiredForUpload;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded'**
  String get documentUploaded;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @pleaseUploadAllDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please upload all required documents'**
  String get pleaseUploadAllDocuments;

  /// No description provided for @enterVehicleMakeModelPlate.
  ///
  /// In en, this message translates to:
  /// **'Enter vehicle make, model, and plate number'**
  String get enterVehicleMakeModelPlate;

  /// No description provided for @pleaseUploadDocumentFirst.
  ///
  /// In en, this message translates to:
  /// **'Please upload the document first'**
  String get pleaseUploadDocumentFirst;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfTotal(String current, String total);

  /// No description provided for @takeClearPhotoOf.
  ///
  /// In en, this message translates to:
  /// **'Take a clear, well-lit photo of your {document}.'**
  String takeClearPhotoOf(String document);

  /// No description provided for @tellUsAboutVehicle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about the vehicle you will drive.'**
  String get tellUsAboutVehicle;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;

  /// No description provided for @captureDocument.
  ///
  /// In en, this message translates to:
  /// **'Capture document'**
  String get captureDocument;

  /// No description provided for @looksGoodCanRetake.
  ///
  /// In en, this message translates to:
  /// **'Looks good - you can retake if needed.'**
  String get looksGoodCanRetake;

  /// No description provided for @jpgPngKeptPrivate.
  ///
  /// In en, this message translates to:
  /// **'JPG or PNG, kept private and secure.'**
  String get jpgPngKeptPrivate;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get retakePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @vehicleMakeExample.
  ///
  /// In en, this message translates to:
  /// **'Vehicle make (e.g. Toyota)'**
  String get vehicleMakeExample;

  /// No description provided for @vehicleModelExample.
  ///
  /// In en, this message translates to:
  /// **'Model (e.g. Corolla)'**
  String get vehicleModelExample;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get plateNumber;

  /// No description provided for @couldNotCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not check status'**
  String get couldNotCheckStatus;

  /// No description provided for @applicationNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Application not approved'**
  String get applicationNotApproved;

  /// No description provided for @applicationUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Application under review'**
  String get applicationUnderReview;

  /// No description provided for @documentsCouldNotBeVerified.
  ///
  /// In en, this message translates to:
  /// **'Your documents could not be verified. Please review and resubmit.'**
  String get documentsCouldNotBeVerified;

  /// No description provided for @verifyingDocuments24to48.
  ///
  /// In en, this message translates to:
  /// **'We are verifying your documents. This usually takes 24–48 hours. You will be notified once your account is approved.'**
  String get verifyingDocuments24to48;

  /// No description provided for @documentsSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted'**
  String get documentsSubmitted;

  /// No description provided for @reviewFailedResubmit.
  ///
  /// In en, this message translates to:
  /// **'Review failed — resubmit required'**
  String get reviewFailedResubmit;

  /// No description provided for @backgroundVehicleVerification.
  ///
  /// In en, this message translates to:
  /// **'Background & vehicle verification'**
  String get backgroundVehicleVerification;

  /// No description provided for @welcomeOnboard.
  ///
  /// In en, this message translates to:
  /// **'Welcome onboard'**
  String get welcomeOnboard;

  /// No description provided for @resubmitDocuments.
  ///
  /// In en, this message translates to:
  /// **'Resubmit documents'**
  String get resubmitDocuments;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @mustBeApprovedToGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Your account must be approved before going online'**
  String get mustBeApprovedToGoOnline;

  /// No description provided for @enableLocationToGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Enable location to go online and receive ride requests.'**
  String get enableLocationToGoOnline;

  /// No description provided for @couldNotGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Could not go online. Check approval and connection.'**
  String get couldNotGoOnline;

  /// No description provided for @rideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled'**
  String get rideCancelled;

  /// No description provided for @headToPickup.
  ///
  /// In en, this message translates to:
  /// **'Head to pickup'**
  String get headToPickup;

  /// No description provided for @navigateToPickup.
  ///
  /// In en, this message translates to:
  /// **'Navigate to pickup'**
  String get navigateToPickup;

  /// No description provided for @atPickup.
  ///
  /// In en, this message translates to:
  /// **'At pickup'**
  String get atPickup;

  /// No description provided for @continuePickup.
  ///
  /// In en, this message translates to:
  /// **'Continue pickup'**
  String get continuePickup;

  /// No description provided for @tripInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get tripInProgress;

  /// No description provided for @continueTrip.
  ///
  /// In en, this message translates to:
  /// **'Continue trip'**
  String get continueTrip;

  /// No description provided for @activeTrip.
  ///
  /// In en, this message translates to:
  /// **'Active trip'**
  String get activeTrip;

  /// No description provided for @viewTrip.
  ///
  /// In en, this message translates to:
  /// **'View trip'**
  String get viewTrip;

  /// No description provided for @verifiedDriver.
  ///
  /// In en, this message translates to:
  /// **'Verified driver'**
  String get verifiedDriver;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get youAreOffline;

  /// No description provided for @youAreOnline.
  ///
  /// In en, this message translates to:
  /// **'You are online'**
  String get youAreOnline;

  /// No description provided for @switchOnlineToReceiveRides.
  ///
  /// In en, this message translates to:
  /// **'Switch online to start receiving rides'**
  String get switchOnlineToReceiveRides;

  /// No description provided for @todaysEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s earnings'**
  String get todaysEarnings;

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last session'**
  String get lastSession;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @gross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get gross;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @receivingRides.
  ///
  /// In en, this message translates to:
  /// **'Receiving rides'**
  String get receivingRides;

  /// No description provided for @tapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get tapToStart;

  /// No description provided for @acceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Accept failed: {error}'**
  String acceptFailed(String error);

  /// No description provided for @newRideRequest.
  ///
  /// In en, this message translates to:
  /// **'New ride request'**
  String get newRideRequest;

  /// No description provided for @respondNowTimeRunningOut.
  ///
  /// In en, this message translates to:
  /// **'Respond now — time is running out'**
  String get respondNowTimeRunningOut;

  /// No description provided for @reviewRouteAndAccept.
  ///
  /// In en, this message translates to:
  /// **'Review route and accept quickly'**
  String get reviewRouteAndAccept;

  /// No description provided for @acceptRide.
  ///
  /// In en, this message translates to:
  /// **'Accept ride'**
  String get acceptRide;

  /// No description provided for @minEta.
  ///
  /// In en, this message translates to:
  /// **'min ETA'**
  String get minEta;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'distance'**
  String get distance;

  /// No description provided for @passengerWillBeNotifiedTripEnds.
  ///
  /// In en, this message translates to:
  /// **'The passenger will be notified and the trip will end.'**
  String get passengerWillBeNotifiedTripEnds;

  /// No description provided for @rideCancelledFee.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled. Fee: {amount}'**
  String rideCancelledFee(String amount);

  /// No description provided for @cancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed: {error}'**
  String cancelFailed(String error);

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to dashboard'**
  String get backToDashboard;

  /// No description provided for @namePickup.
  ///
  /// In en, this message translates to:
  /// **'{name} pickup'**
  String namePickup(String name);

  /// No description provided for @passengerPickup.
  ///
  /// In en, this message translates to:
  /// **'Passenger pickup'**
  String get passengerPickup;

  /// No description provided for @whatsAppPassenger.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp passenger'**
  String get whatsAppPassenger;

  /// No description provided for @whatsAppCallPassenger.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp call passenger'**
  String get whatsAppCallPassenger;

  /// No description provided for @headingToPickup.
  ///
  /// In en, this message translates to:
  /// **'Heading to pickup'**
  String get headingToPickup;

  /// No description provided for @waitingAtPickupMarker.
  ///
  /// In en, this message translates to:
  /// **'Waiting at the pickup marker'**
  String get waitingAtPickupMarker;

  /// No description provided for @passengerPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Passenger pickup location'**
  String get passengerPickupLocation;

  /// No description provided for @inAppNavigationStarted.
  ///
  /// In en, this message translates to:
  /// **'In-app navigation started.'**
  String get inAppNavigationStarted;

  /// No description provided for @iveArrivedAtPickup.
  ///
  /// In en, this message translates to:
  /// **'I\'ve arrived at pickup'**
  String get iveArrivedAtPickup;

  /// No description provided for @youAreAtPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'You are at the passenger pickup location.'**
  String get youAreAtPickupLocation;

  /// No description provided for @tapStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'Tap Start navigation to follow the route.'**
  String get tapStartNavigation;

  /// No description provided for @samePickupLocation.
  ///
  /// In en, this message translates to:
  /// **'You and the passenger are at the same pickup location.'**
  String get samePickupLocation;

  /// No description provided for @tripStartedFollowRoute.
  ///
  /// In en, this message translates to:
  /// **'Trip started. Follow the route to the destination.'**
  String get tripStartedFollowRoute;

  /// No description provided for @completeThisTrip.
  ///
  /// In en, this message translates to:
  /// **'Complete this trip?'**
  String get completeThisTrip;

  /// No description provided for @onlyCompleteAfterDestination.
  ///
  /// In en, this message translates to:
  /// **'Only complete after the passenger has reached the destination.'**
  String get onlyCompleteAfterDestination;

  /// No description provided for @keepDriving.
  ///
  /// In en, this message translates to:
  /// **'Keep driving'**
  String get keepDriving;

  /// No description provided for @completeTrip.
  ///
  /// In en, this message translates to:
  /// **'Complete trip'**
  String get completeTrip;

  /// No description provided for @onlyCancelIfCannotContinue.
  ///
  /// In en, this message translates to:
  /// **'Only cancel if you cannot safely continue. The passenger will be notified.'**
  String get onlyCancelIfCannotContinue;

  /// No description provided for @waitingForPassenger.
  ///
  /// In en, this message translates to:
  /// **'Waiting for passenger'**
  String get waitingForPassenger;

  /// No description provided for @dropoffWithAddress.
  ///
  /// In en, this message translates to:
  /// **'Drop-off: {address}'**
  String dropoffWithAddress(String address);

  /// No description provided for @atPickupStartWhenOnboard.
  ///
  /// In en, this message translates to:
  /// **'At pickup — start trip when passenger is onboard'**
  String get atPickupStartWhenOnboard;

  /// No description provided for @yourCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get yourCurrentLocation;

  /// No description provided for @mayCancelWithoutFeeNoShow.
  ///
  /// In en, this message translates to:
  /// **'You may cancel without fee if the passenger did not show.'**
  String get mayCancelWithoutFeeNoShow;

  /// No description provided for @startTripOnceOnboard.
  ///
  /// In en, this message translates to:
  /// **'Start the trip once the passenger is in your car.'**
  String get startTripOnceOnboard;

  /// No description provided for @navigateToDropoff.
  ///
  /// In en, this message translates to:
  /// **'Navigate to drop-off'**
  String get navigateToDropoff;

  /// No description provided for @cancelRideNoFee.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride (no fee)'**
  String get cancelRideNoFee;

  /// No description provided for @goToPickup.
  ///
  /// In en, this message translates to:
  /// **'Go to pickup'**
  String get goToPickup;

  /// No description provided for @startTrip.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// No description provided for @tripStartedKeepDriving.
  ///
  /// In en, this message translates to:
  /// **'Trip started - keep driving'**
  String get tripStartedKeepDriving;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(String status);

  /// No description provided for @tagPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get tagPolite;

  /// No description provided for @tagOnTimeAtPickup.
  ///
  /// In en, this message translates to:
  /// **'On time at pickup'**
  String get tagOnTimeAtPickup;

  /// No description provided for @tagClearDirections.
  ///
  /// In en, this message translates to:
  /// **'Clear directions'**
  String get tagClearDirections;

  /// No description provided for @tagRespectful.
  ///
  /// In en, this message translates to:
  /// **'Respectful'**
  String get tagRespectful;

  /// No description provided for @tagEasyPickup.
  ///
  /// In en, this message translates to:
  /// **'Easy pickup'**
  String get tagEasyPickup;

  /// No description provided for @couldNotUpdateAvailability.
  ///
  /// In en, this message translates to:
  /// **'Could not update availability'**
  String get couldNotUpdateAvailability;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get greatJob;

  /// No description provided for @tripCompletedFareBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Trip completed. Here\'s your fare breakdown.'**
  String get tripCompletedFareBreakdown;

  /// No description provided for @rateYourPassenger.
  ///
  /// In en, this message translates to:
  /// **'Rate your passenger'**
  String get rateYourPassenger;

  /// No description provided for @feedbackKeepsRawanaSafe.
  ///
  /// In en, this message translates to:
  /// **'Your feedback helps keep Rawana safe and reliable.'**
  String get feedbackKeepsRawanaSafe;

  /// No description provided for @openToNewRequests.
  ///
  /// In en, this message translates to:
  /// **'You are open to new ride requests'**
  String get openToNewRequests;

  /// No description provided for @goOnlineToReceiveRequests.
  ///
  /// In en, this message translates to:
  /// **'Go online to receive new requests'**
  String get goOnlineToReceiveRequests;

  /// No description provided for @youEarned.
  ///
  /// In en, this message translates to:
  /// **'YOU EARNED'**
  String get youEarned;

  /// No description provided for @grossFare.
  ///
  /// In en, this message translates to:
  /// **'Gross fare'**
  String get grossFare;

  /// No description provided for @rawanaFeePercent.
  ///
  /// In en, this message translates to:
  /// **'Rawana fee ({percent}%)'**
  String rawanaFeePercent(String percent);

  /// No description provided for @yourEarnings.
  ///
  /// In en, this message translates to:
  /// **'Your earnings'**
  String get yourEarnings;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @couldNotLoadEarnings.
  ///
  /// In en, this message translates to:
  /// **'Could not load earnings'**
  String get couldNotLoadEarnings;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform fee'**
  String get platformFee;

  /// No description provided for @avgPerTrip.
  ///
  /// In en, this message translates to:
  /// **'Avg / trip'**
  String get avgPerTrip;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net earnings'**
  String get netEarnings;

  /// No description provided for @noTripsYetPeriod.
  ///
  /// In en, this message translates to:
  /// **'No trips yet {period}'**
  String noTripsYetPeriod(String period);

  /// No description provided for @tripsCompletedOne.
  ///
  /// In en, this message translates to:
  /// **'{count} trip completed'**
  String tripsCompletedOne(String count);

  /// No description provided for @tripsCompletedOther.
  ///
  /// In en, this message translates to:
  /// **'{count} trips completed'**
  String tripsCompletedOther(String count);

  /// No description provided for @howEarningsWork.
  ///
  /// In en, this message translates to:
  /// **'How earnings work'**
  String get howEarningsWork;

  /// No description provided for @earningsExplainer.
  ///
  /// In en, this message translates to:
  /// **'Gross fares are what passengers paid. Platform fee is deducted automatically; net earnings are deposited to your wallet and become available for payout.'**
  String get earningsExplainer;

  /// No description provided for @activitySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Activity snapshot'**
  String get activitySnapshot;

  /// No description provided for @completeTripsToSeeActivity.
  ///
  /// In en, this message translates to:
  /// **'Complete trips to see your activity pattern.'**
  String get completeTripsToSeeActivity;

  /// No description provided for @couldNotLoadWallet.
  ///
  /// In en, this message translates to:
  /// **'Could not load wallet'**
  String get couldNotLoadWallet;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @couldNotLoadTransactions.
  ///
  /// In en, this message translates to:
  /// **'Could not load transactions'**
  String get couldNotLoadTransactions;

  /// No description provided for @requestPayoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Request payout?'**
  String get requestPayoutQuestion;

  /// No description provided for @willTransferToPayoutAccount.
  ///
  /// In en, this message translates to:
  /// **'We will transfer {amount} from your wallet. Rawana processes payouts — no bank account is required in the app.'**
  String willTransferToPayoutAccount(String amount);

  /// No description provided for @payoutRequested.
  ///
  /// In en, this message translates to:
  /// **'Payout requested'**
  String get payoutRequested;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get availableBalance;

  /// No description provided for @pendingAmount.
  ///
  /// In en, this message translates to:
  /// **'Pending {amount}'**
  String pendingAmount(String amount);

  /// No description provided for @requestPayout.
  ///
  /// In en, this message translates to:
  /// **'Request payout'**
  String get requestPayout;

  /// No description provided for @noFundsYet.
  ///
  /// In en, this message translates to:
  /// **'No funds yet'**
  String get noFundsYet;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @earningsPayoutsWillShowHere.
  ///
  /// In en, this message translates to:
  /// **'Earnings and payouts will show up here.'**
  String get earningsPayoutsWillShowHere;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistory;

  /// No description provided for @couldNotLoadTripHistory.
  ///
  /// In en, this message translates to:
  /// **'Could not load trip history'**
  String get couldNotLoadTripHistory;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total earned'**
  String get totalEarned;

  /// No description provided for @allTrips.
  ///
  /// In en, this message translates to:
  /// **'All trips'**
  String get allTrips;

  /// No description provided for @unknownDestination.
  ///
  /// In en, this message translates to:
  /// **'Unknown destination'**
  String get unknownDestination;

  /// No description provided for @unknownPickup.
  ///
  /// In en, this message translates to:
  /// **'Unknown pickup'**
  String get unknownPickup;

  /// No description provided for @pickupUnknown.
  ///
  /// In en, this message translates to:
  /// **'Pickup unknown'**
  String get pickupUnknown;

  /// No description provided for @fromPickup.
  ///
  /// In en, this message translates to:
  /// **'From {pickup}'**
  String fromPickup(String pickup);

  /// No description provided for @completedCancelledRidesAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your completed and cancelled rides will appear here.'**
  String get completedCancelledRidesAppearHere;

  /// No description provided for @failedToLoadTrip.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trip: {error}'**
  String failedToLoadTrip(String error);

  /// No description provided for @durationMin.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String durationMin(String n);

  /// No description provided for @openRouteInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open route in Maps'**
  String get openRouteInMaps;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQuestion;

  /// No description provided for @signOutNeedSignBackIn.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign back in to receive ride requests.'**
  String get signOutNeedSignBackIn;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get couldNotLoadProfile;

  /// No description provided for @driverFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverFallbackName;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @makeAndModel.
  ///
  /// In en, this message translates to:
  /// **'Make & model'**
  String get makeAndModel;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @myDocuments.
  ///
  /// In en, this message translates to:
  /// **'My documents'**
  String get myDocuments;

  /// No description provided for @viewUploadedPapers.
  ///
  /// In en, this message translates to:
  /// **'View uploaded verification papers'**
  String get viewUploadedPapers;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get privacyAndSecurity;

  /// No description provided for @manageAccountSafety.
  ///
  /// In en, this message translates to:
  /// **'Manage your account safety'**
  String get manageAccountSafety;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @vehicleMake.
  ///
  /// In en, this message translates to:
  /// **'Vehicle make'**
  String get vehicleMake;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle model'**
  String get vehicleModel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @couldNotLoadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Could not load documents'**
  String get couldNotLoadDocuments;

  /// No description provided for @documentsVerified.
  ///
  /// In en, this message translates to:
  /// **'Your documents are verified.'**
  String get documentsVerified;

  /// No description provided for @documentsAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted — awaiting admin review.'**
  String get documentsAwaitingReview;

  /// No description provided for @uploadDocsToStartEarning.
  ///
  /// In en, this message translates to:
  /// **'Upload your documents to start earning.'**
  String get uploadDocsToStartEarning;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocumentsYet;

  /// No description provided for @uploadLicenceRegId.
  ///
  /// In en, this message translates to:
  /// **'Upload your licence, registration, and ID to get approved.'**
  String get uploadLicenceRegId;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get uploadDocuments;

  /// No description provided for @submittedFiles.
  ///
  /// In en, this message translates to:
  /// **'Submitted files'**
  String get submittedFiles;

  /// No description provided for @updateDocuments.
  ///
  /// In en, this message translates to:
  /// **'Update documents'**
  String get updateDocuments;

  /// No description provided for @documentNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'{label} — not uploaded'**
  String documentNotUploaded(String label);

  /// No description provided for @passwordMinEightChars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinEightChars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @requestAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get requestAccountDeletion;

  /// No description provided for @accountProtectedNeverSharePassword.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected with secure sign-in. Never share your password with anyone.'**
  String get accountProtectedNeverSharePassword;

  /// No description provided for @signInSection.
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get signInSection;

  /// No description provided for @notLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get notLinked;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePassword;

  /// No description provided for @policies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get policies;

  /// No description provided for @termsAndPolicies.
  ///
  /// In en, this message translates to:
  /// **'Terms & policies'**
  String get termsAndPolicies;

  /// No description provided for @howRawanaOperates.
  ///
  /// In en, this message translates to:
  /// **'How Rawana operates'**
  String get howRawanaOperates;

  /// No description provided for @driverGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Driver guidelines'**
  String get driverGuidelines;

  /// No description provided for @bestPracticesOnPlatform.
  ///
  /// In en, this message translates to:
  /// **'Best practices on the platform'**
  String get bestPracticesOnPlatform;

  /// No description provided for @teamWillProcessRequest.
  ///
  /// In en, this message translates to:
  /// **'Our team will process your request'**
  String get teamWillProcessRequest;

  /// No description provided for @supportEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'Email: support@rawana.af'**
  String get supportEmailFallback;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get getHelp;

  /// No description provided for @reportATripIssue.
  ///
  /// In en, this message translates to:
  /// **'Report a trip issue'**
  String get reportATripIssue;

  /// No description provided for @lostItemWrongFareRoute.
  ///
  /// In en, this message translates to:
  /// **'Lost item, wrong fare, route problem'**
  String get lostItemWrongFareRoute;

  /// No description provided for @reportASafetyConcern.
  ///
  /// In en, this message translates to:
  /// **'Report a safety concern'**
  String get reportASafetyConcern;

  /// No description provided for @tellUsUnsafeBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Tell us about unsafe behaviour'**
  String get tellUsUnsafeBehaviour;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact admin'**
  String get contactAdmin;

  /// No description provided for @emailOurSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Email our support team'**
  String get emailOurSupportTeam;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @bestPracticesKeepRatingHigh.
  ///
  /// In en, this message translates to:
  /// **'Best practices to keep your rating high'**
  String get bestPracticesKeepRatingHigh;

  /// No description provided for @myReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get myReports;

  /// No description provided for @couldNotLoadReports.
  ///
  /// In en, this message translates to:
  /// **'Could not load your reports: {error}'**
  String couldNotLoadReports(String error);

  /// No description provided for @noSupportReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No support reports yet. Use the options above if you need help.'**
  String get noSupportReportsYet;

  /// No description provided for @supportTicket.
  ///
  /// In en, this message translates to:
  /// **'Support ticket'**
  String get supportTicket;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get ticketStatusOpen;

  /// No description provided for @weHaveYourBack.
  ///
  /// In en, this message translates to:
  /// **'We have your back'**
  String get weHaveYourBack;

  /// No description provided for @getHelp247.
  ///
  /// In en, this message translates to:
  /// **'Get help from our team, 24/7.'**
  String get getHelp247;

  /// No description provided for @couldNotLoadTrips.
  ///
  /// In en, this message translates to:
  /// **'Could not load trips'**
  String get couldNotLoadTrips;

  /// No description provided for @completeRideThenReport.
  ///
  /// In en, this message translates to:
  /// **'Complete a ride first, then you can report an issue here.'**
  String get completeRideThenReport;

  /// No description provided for @selectTripNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Select the trip you need help with'**
  String get selectTripNeedHelp;

  /// No description provided for @generalIssueNoTrip.
  ///
  /// In en, this message translates to:
  /// **'General issue (no trip)'**
  String get generalIssueNoTrip;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Ride requests, payout updates, and announcements\nwill appear here.'**
  String get notificationsEmptyMessage;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @couldNotLoadPerformance.
  ///
  /// In en, this message translates to:
  /// **'Could not load performance'**
  String get couldNotLoadPerformance;

  /// No description provided for @serviceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Service metrics'**
  String get serviceMetrics;

  /// No description provided for @acceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'Acceptance rate'**
  String get acceptanceRate;

  /// No description provided for @cancellationRate.
  ///
  /// In en, this message translates to:
  /// **'Cancellation rate'**
  String get cancellationRate;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total trips'**
  String get totalTrips;

  /// No description provided for @onlineTime.
  ///
  /// In en, this message translates to:
  /// **'Online time'**
  String get onlineTime;

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String hoursShort(String h);

  /// No description provided for @hoursMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String hoursMinutesShort(String h, String m);

  /// No description provided for @averageRiderRating.
  ///
  /// In en, this message translates to:
  /// **'Average rider rating'**
  String get averageRiderRating;

  /// No description provided for @higherAcceptanceLowerCancelTip.
  ///
  /// In en, this message translates to:
  /// **'Higher acceptance and lower cancellation rates help you get more ride requests.'**
  String get higherAcceptanceLowerCancelTip;

  /// No description provided for @cancelReasonNotAtPickup.
  ///
  /// In en, this message translates to:
  /// **'Passenger not at pickup'**
  String get cancelReasonNotAtPickup;

  /// No description provided for @cancelReasonWrongPickup.
  ///
  /// In en, this message translates to:
  /// **'Wrong pickup location'**
  String get cancelReasonWrongPickup;

  /// No description provided for @cancelReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get cancelReasonSafety;

  /// No description provided for @cancelReasonVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle issue'**
  String get cancelReasonVehicle;

  /// No description provided for @cancelReasonEmergency.
  ///
  /// In en, this message translates to:
  /// **'Personal emergency'**
  String get cancelReasonEmergency;

  /// No description provided for @cancelReasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'Passenger no-show'**
  String get cancelReasonNoShow;

  /// No description provided for @noFeePassengerNoShow.
  ///
  /// In en, this message translates to:
  /// **'No cancellation fee — passenger did not show up after the waiting period.'**
  String get noFeePassengerNoShow;

  /// No description provided for @cancellationFeeMayApply.
  ///
  /// In en, this message translates to:
  /// **'A cancellation fee may apply if you cancel now.'**
  String get cancellationFeeMayApply;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'REASON'**
  String get reason;

  /// No description provided for @waitingPeriodEndedNoFee.
  ///
  /// In en, this message translates to:
  /// **'Waiting period ended. You may cancel without a fee if the passenger did not show.'**
  String get waitingPeriodEndedNoFee;

  /// No description provided for @freeWaitRemaining.
  ///
  /// In en, this message translates to:
  /// **'Free wait: {time} remaining'**
  String freeWaitRemaining(String time);

  /// No description provided for @passengerNoShowWindow.
  ///
  /// In en, this message translates to:
  /// **'Passenger no-show window'**
  String get passengerNoShowWindow;

  /// No description provided for @cancelWithoutFeeIn.
  ///
  /// In en, this message translates to:
  /// **'Cancel without fee in {time}'**
  String cancelWithoutFeeIn(String time);

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

  /// No description provided for @trip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get trip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @accountNotRegisteredAsDriver.
  ///
  /// In en, this message translates to:
  /// **'This account is not registered as a driver. Sign in with your driver account.'**
  String get accountNotRegisteredAsDriver;

  /// No description provided for @sessionExpiredSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Sign out and sign in again.'**
  String get sessionExpiredSignInAgain;

  /// No description provided for @driverProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Driver profile not found. Complete document upload first.'**
  String get driverProfileNotFound;

  /// No description provided for @cannotReachRawanaServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the Rawana server. Check your connection and try again.'**
  String get cannotReachRawanaServer;

  /// No description provided for @couldNotLoadDriverProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load driver profile.'**
  String get couldNotLoadDriverProfile;

  /// No description provided for @driverGuideProfessionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay professional'**
  String get driverGuideProfessionalTitle;

  /// No description provided for @driverGuideProfessionalBody.
  ///
  /// In en, this message translates to:
  /// **'Greet passengers politely, keep your vehicle clean, and follow local traffic laws. A calm, respectful attitude is the fastest way to earn five-star ratings.'**
  String get driverGuideProfessionalBody;

  /// No description provided for @driverGuideAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Accept rides promptly'**
  String get driverGuideAcceptTitle;

  /// No description provided for @driverGuideAcceptBody.
  ///
  /// In en, this message translates to:
  /// **'High acceptance rates help you receive more requests. Only go online when you are ready to drive. If you must decline, do it quickly so the passenger can find another driver.'**
  String get driverGuideAcceptBody;

  /// No description provided for @driverGuideNavigateTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate accurately'**
  String get driverGuideNavigateTitle;

  /// No description provided for @driverGuideNavigateBody.
  ///
  /// In en, this message translates to:
  /// **'Use the in-app route to pickup and drop-off. Confirm the destination with the passenger before starting the trip. If the address is unclear, call or message through the app.'**
  String get driverGuideNavigateBody;

  /// No description provided for @driverGuideSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety first'**
  String get driverGuideSafetyTitle;

  /// No description provided for @driverGuideSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Do not drive tired or under the influence. Report safety concerns immediately through Support. In an emergency, contact local authorities first, then notify Rawana.'**
  String get driverGuideSafetyBody;

  /// No description provided for @driverGuideFaresTitle.
  ///
  /// In en, this message translates to:
  /// **'Fares & payments'**
  String get driverGuideFaresTitle;

  /// No description provided for @driverGuideFaresBody.
  ///
  /// In en, this message translates to:
  /// **'Fares are calculated automatically from distance, time, and zone pricing. Do not ask passengers for extra cash unless agreed in the app. Earnings appear in your wallet after each completed trip.'**
  String get driverGuideFaresBody;

  /// No description provided for @driverGuideCancellationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellations'**
  String get driverGuideCancellationsTitle;

  /// No description provided for @driverGuideCancellationsBody.
  ///
  /// In en, this message translates to:
  /// **'Avoid cancelling after accepting a ride. Frequent cancellations lower your performance score and may reduce future requests. Cancel only when necessary and add a clear reason.'**
  String get driverGuideCancellationsBody;

  /// No description provided for @termsDriverAgreement.
  ///
  /// In en, this message translates to:
  /// **'Driver agreement'**
  String get termsDriverAgreement;

  /// No description provided for @termsDriverAgreementBody.
  ///
  /// In en, this message translates to:
  /// **'By using Rawana Driver you agree to provide ride-hailing services in line with platform rules, local regulations, and the documents you submitted during onboarding.'**
  String get termsDriverAgreementBody;

  /// No description provided for @termsAccountVerification.
  ///
  /// In en, this message translates to:
  /// **'Account & verification'**
  String get termsAccountVerification;

  /// No description provided for @termsAccountVerificationBody.
  ///
  /// In en, this message translates to:
  /// **'You must keep your licence, vehicle registration, and identity documents valid and up to date. Rawana may suspend accounts with expired or fraudulent documents.'**
  String get termsAccountVerificationBody;

  /// No description provided for @termsEarningsPayouts.
  ///
  /// In en, this message translates to:
  /// **'Earnings & payouts'**
  String get termsEarningsPayouts;

  /// No description provided for @termsEarningsPayoutsBody.
  ///
  /// In en, this message translates to:
  /// **'Trip fares are credited to your wallet minus Rawana\'s commission. Payout requests are processed according to finance team schedules. Fraudulent activity may result in withheld balances.'**
  String get termsEarningsPayoutsBody;

  /// No description provided for @termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get termsPrivacy;

  /// No description provided for @termsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'We collect location while you are online, trip history, and contact details to operate the service. Passenger phone numbers may be masked during active trips. See Privacy & security in your profile for account controls.'**
  String get termsPrivacyBody;

  /// No description provided for @termsConductSuspension.
  ///
  /// In en, this message translates to:
  /// **'Conduct & suspension'**
  String get termsConductSuspension;

  /// No description provided for @termsConductSuspensionBody.
  ///
  /// In en, this message translates to:
  /// **'Harassment, discrimination, unsafe driving, or repeated complaints can lead to temporary suspension or permanent removal from the platform.'**
  String get termsConductSuspensionBody;

  /// No description provided for @termsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get termsSupport;

  /// No description provided for @termsSupportBody.
  ///
  /// In en, this message translates to:
  /// **'For disputes, safety reports, or account help, use in-app Support or email support@rawana.af. We aim to respond to urgent safety issues as quickly as possible.'**
  String get termsSupportBody;

  /// No description provided for @noCancellationFee.
  ///
  /// In en, this message translates to:
  /// **'No cancellation fee'**
  String get noCancellationFee;

  /// No description provided for @cancellationFeeAmount.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fee: {amount}'**
  String cancellationFeeAmount(String amount);

  /// No description provided for @cancelSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get cancelSearchTitle;

  /// No description provided for @cancelSearchBody.
  ///
  /// In en, this message translates to:
  /// **'You can request another ride right away. There is no fee while we are still finding a driver.'**
  String get cancelSearchBody;

  /// No description provided for @collectCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Collect {amount} cash'**
  String collectCashAmount(String amount);

  /// No description provided for @cashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get cashCollected;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @tooFarContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} m from the pin. Continue anyway?'**
  String tooFarContinueAnyway(String distance);

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get continueAnyway;

  /// No description provided for @payDriverCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay your driver {amount} cash'**
  String payDriverCashAmount(String amount);

  /// No description provided for @cashSelectedInfo.
  ///
  /// In en, this message translates to:
  /// **'Cash · AFN — pay your driver at drop-off'**
  String get cashSelectedInfo;

  /// No description provided for @cashFare.
  ///
  /// In en, this message translates to:
  /// **'Cash fare'**
  String get cashFare;

  /// No description provided for @rideType.
  ///
  /// In en, this message translates to:
  /// **'Ride type'**
  String get rideType;

  /// No description provided for @selectRideType.
  ///
  /// In en, this message translates to:
  /// **'Which rides should you receive?'**
  String get selectRideType;

  /// No description provided for @fareBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Fare breakdown'**
  String get fareBreakdown;

  /// No description provided for @baseFare.
  ///
  /// In en, this message translates to:
  /// **'Base fare'**
  String get baseFare;

  /// No description provided for @distanceFare.
  ///
  /// In en, this message translates to:
  /// **'Distance · {km} km'**
  String distanceFare(String km);

  /// No description provided for @timeFare.
  ///
  /// In en, this message translates to:
  /// **'Time · {minutes} min'**
  String timeFare(String minutes);

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @totalCash.
  ///
  /// In en, this message translates to:
  /// **'Total cash'**
  String get totalCash;

  /// No description provided for @cancelGraceSeconds.
  ///
  /// In en, this message translates to:
  /// **'Free to cancel for the first {seconds} seconds after a driver accepts.'**
  String cancelGraceSeconds(String seconds);

  /// No description provided for @maxEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'You can save up to 3 emergency contacts.'**
  String get maxEmergencyContacts;

  /// No description provided for @maxContactsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum of 3 emergency contacts reached.'**
  String get maxContactsReached;

  /// No description provided for @useThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get useThisLocation;

  /// No description provided for @chooseSavedPlace.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get chooseSavedPlace;

  /// No description provided for @vehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Vehicle year'**
  String get vehicleYear;

  /// No description provided for @vehicleColour.
  ///
  /// In en, this message translates to:
  /// **'Vehicle colour'**
  String get vehicleColour;

  /// No description provided for @openInWaze.
  ///
  /// In en, this message translates to:
  /// **'Open in Waze'**
  String get openInWaze;

  /// No description provided for @chooseMapsApp.
  ///
  /// In en, this message translates to:
  /// **'Open in maps'**
  String get chooseMapsApp;

  /// No description provided for @findingAnotherDriver.
  ///
  /// In en, this message translates to:
  /// **'Your previous driver cancelled. We are finding you another driver.'**
  String get findingAnotherDriver;

  /// No description provided for @filterFrom.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get filterFrom;

  /// No description provided for @filterTo.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get filterTo;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'This account is blocked and cannot book rides.'**
  String get accountBlocked;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @applyPromo.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyPromo;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo applied'**
  String get promoApplied;

  /// No description provided for @promoInvalid.
  ///
  /// In en, this message translates to:
  /// **'This promo code is not valid.'**
  String get promoInvalid;

  /// No description provided for @promoExpired.
  ///
  /// In en, this message translates to:
  /// **'This promo code has expired.'**
  String get promoExpired;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review (optional)'**
  String get writeAReview;

  /// No description provided for @ratingCommentHint.
  ///
  /// In en, this message translates to:
  /// **'How was the trip?'**
  String get ratingCommentHint;

  /// No description provided for @tripReceipt.
  ///
  /// In en, this message translates to:
  /// **'Trip receipt'**
  String get tripReceipt;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'We’ll be back shortly'**
  String get maintenanceTitle;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'Please update Rawana to continue.'**
  String get forceUpdateBody;

  /// No description provided for @updateApp.
  ///
  /// In en, this message translates to:
  /// **'Update app'**
  String get updateApp;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get exportMyData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this account? This cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Your profile and saved places will be removed. Trip records are kept for legal and safety reasons.'**
  String get deleteAccountWarning;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @dataExported.
  ///
  /// In en, this message translates to:
  /// **'Your data file is ready.'**
  String get dataExported;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @sosConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send your live location to emergency contacts?'**
  String get sosConfirm;

  /// No description provided for @sosSent.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert sent.'**
  String get sosSent;

  /// No description provided for @sosFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send SOS. Share your trip instead.'**
  String get sosFailed;

  /// No description provided for @sosNoContacts.
  ///
  /// In en, this message translates to:
  /// **'Add an emergency contact first.'**
  String get sosNoContacts;

  /// No description provided for @sendSos.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get sendSos;

  /// No description provided for @yourTickets.
  ///
  /// In en, this message translates to:
  /// **'Your tickets'**
  String get yourTickets;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get noTickets;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @sendReply.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get sendReply;

  /// No description provided for @recentRatings.
  ///
  /// In en, this message translates to:
  /// **'Recent ratings'**
  String get recentRatings;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No written ratings yet'**
  String get noRatingsYet;

  /// No description provided for @lowRatingAlert.
  ///
  /// In en, this message translates to:
  /// **'Your rating is below the platform threshold. Focus on safe, on-time trips.'**
  String get lowRatingAlert;

  /// No description provided for @highCancelAlert.
  ///
  /// In en, this message translates to:
  /// **'Your cancellation rate is high. Accepting more trips protects your account.'**
  String get highCancelAlert;

  /// No description provided for @typicalDriverRating.
  ///
  /// In en, this message translates to:
  /// **'Nearby drivers avg. {rating}'**
  String typicalDriverRating(String rating);

  /// No description provided for @tooManyCancellations.
  ///
  /// In en, this message translates to:
  /// **'You have reached today’s cancellation limit. Try again tomorrow.'**
  String get tooManyCancellations;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markAllRead;

  /// No description provided for @emergencyContactsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} contacts'**
  String emergencyContactsCount(String count, String max);

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @payoutMethod.
  ///
  /// In en, this message translates to:
  /// **'Payout method'**
  String get payoutMethod;

  /// No description provided for @payoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get payoutAccount;

  /// No description provided for @savePayoutDetails.
  ///
  /// In en, this message translates to:
  /// **'Save payout details'**
  String get savePayoutDetails;

  /// No description provided for @payoutDetailsSaved.
  ///
  /// In en, this message translates to:
  /// **'Payout details saved'**
  String get payoutDetailsSaved;

  /// No description provided for @tooFarFromPickup.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} m from the pickup point. Move within {required} m to confirm arrival.'**
  String tooFarFromPickup(String distance, String required);

  /// No description provided for @tooFarFromDropoff.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} m from the drop-off point. Move within {required} m to complete the trip.'**
  String tooFarFromDropoff(String distance, String required);

  /// No description provided for @rideCancelledByPassenger.
  ///
  /// In en, this message translates to:
  /// **'The passenger cancelled this ride.'**
  String get rideCancelledByPassenger;

  /// No description provided for @rideCancelledBySupport.
  ///
  /// In en, this message translates to:
  /// **'This ride was cancelled by Rawana support.'**
  String get rideCancelledBySupport;

  /// No description provided for @rideCancelledByDriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver cancelled. We are finding you another driver.'**
  String get rideCancelledByDriver;

  /// No description provided for @rideCancelledNoDrivers.
  ///
  /// In en, this message translates to:
  /// **'No drivers were available for this ride.'**
  String get rideCancelledNoDrivers;

  /// No description provided for @rideCancelledGeneric.
  ///
  /// In en, this message translates to:
  /// **'This ride was cancelled.'**
  String get rideCancelledGeneric;

  /// No description provided for @rateLastTripTitle.
  ///
  /// In en, this message translates to:
  /// **'How was your last ride?'**
  String get rateLastTripTitle;

  /// No description provided for @rateLastTripBody.
  ///
  /// In en, this message translates to:
  /// **'Rate your trip to {destination} to help us keep drivers great.'**
  String rateLastTripBody(String destination);

  /// No description provided for @rateNow.
  ///
  /// In en, this message translates to:
  /// **'Rate now'**
  String get rateNow;

  /// No description provided for @resumingActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'You already have a ride in progress. Taking you back to it.'**
  String get resumingActiveTrip;

  /// No description provided for @youKeep.
  ///
  /// In en, this message translates to:
  /// **'YOU KEEP'**
  String get youKeep;

  /// No description provided for @commissionOwedToRawana.
  ///
  /// In en, this message translates to:
  /// **'Commission owed to Rawana'**
  String get commissionOwedToRawana;

  /// No description provided for @outstandingFeeCollected.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fee collected for Rawana'**
  String get outstandingFeeCollected;

  /// No description provided for @totalCashToCollect.
  ///
  /// In en, this message translates to:
  /// **'Total cash to collect'**
  String get totalCashToCollect;

  /// No description provided for @amountOwedToRawana.
  ///
  /// In en, this message translates to:
  /// **'You owe Rawana'**
  String get amountOwedToRawana;

  /// No description provided for @creditFromRawana.
  ///
  /// In en, this message translates to:
  /// **'Rawana owes you'**
  String get creditFromRawana;

  /// No description provided for @balanceSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get balanceSettled;

  /// No description provided for @balanceSettledBody.
  ///
  /// In en, this message translates to:
  /// **'You have no commission to pay right now.'**
  String get balanceSettledBody;

  /// No description provided for @debtLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit {amount}'**
  String debtLimitLabel(String amount);

  /// No description provided for @debtLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle your balance to keep driving'**
  String get debtLimitReachedTitle;

  /// No description provided for @debtLimitReachedBody.
  ///
  /// In en, this message translates to:
  /// **'You owe {owed}. Drivers over the {limit} limit cannot go online until finance records a payment.'**
  String debtLimitReachedBody(String owed, String limit);

  /// No description provided for @howToSettle.
  ///
  /// In en, this message translates to:
  /// **'How to pay Rawana'**
  String get howToSettle;

  /// No description provided for @walletCashFirstExplainer.
  ///
  /// In en, this message translates to:
  /// **'You keep every fare in cash. Rawana\'s commission is added to your balance here and you settle it with finance.'**
  String get walletCashFirstExplainer;

  /// No description provided for @outstandingFeeIncluded.
  ///
  /// In en, this message translates to:
  /// **'Includes {amount} unpaid cancellation fee from a previous ride'**
  String outstandingFeeIncluded(String amount);

  /// No description provided for @cancellationFeeChargedNextRide.
  ///
  /// In en, this message translates to:
  /// **'A {amount} cancellation fee will be added to your next ride.'**
  String cancellationFeeChargedNextRide(String amount);

  /// No description provided for @txCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get txCommission;

  /// No description provided for @txSettlement.
  ///
  /// In en, this message translates to:
  /// **'Payment to Rawana'**
  String get txSettlement;

  /// No description provided for @txCancellationFee.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fee compensation'**
  String get txCancellationFee;

  /// No description provided for @txFeeCollected.
  ///
  /// In en, this message translates to:
  /// **'Cancellation fee collected'**
  String get txFeeCollected;

  /// No description provided for @txPayout.
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get txPayout;

  /// No description provided for @txAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get txAdjustment;

  /// No description provided for @txCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash fare (kept by you)'**
  String get txCashCollected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa', 'ps'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
    case 'ps':
      return AppLocalizationsPs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
