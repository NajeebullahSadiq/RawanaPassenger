import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// Copy for the redesigned booking and trip flows (passenger + driver).
/// Kept beside the generated catalog in the same hand-written style as
/// `l10n_extensions.dart`.
extension RawanaBookingL10n on AppLocalizations {
  String _t(String en, String fa, String ps) => switch (localeName) {
        'fa' => fa,
        'ps' => ps,
        _ => en,
      };

  /// Wall-clock time in the user's locale, e.g. "3:42 PM".
  String clockTime(DateTime t) => intl.DateFormat.jm(localeName).format(t);

  // ---- Shared ----
  String get pickupTitle => _t('Pickup', 'مبدأ', 'د پورته کېدو ځای');
  String get destinationTitle => _t('Destination', 'مقصد', 'منزل');
  String get cashLabel => _t('Cash', 'نقد', 'نغدې');
  String get closeLabel => _t('Close', 'بستن', 'بندول');
  String minAway(int minutes) =>
      _t('$minutes min away', '$minutes دقیقه فاصله', '$minutes دقیقې لرې');
  String arriveAt(String time) => _t('Arrive $time', 'رسیدن $time', 'رسېدل $time');
  String arrivingIn(int minutes) =>
      _t('Arriving in $minutes min', 'تا $minutes دقیقه دیگر می‌رسد', 'په $minutes دقیقو کې رارسي');
  String get lessThanAMinute => _t('Less than a minute', 'کمتر از یک دقیقه', 'له یوې دقیقې لږ');

  // ---- Passenger: home & search ----
  String get searchDestinationHint => _t('Where to?', 'کجا می‌روید؟', 'چیرته ځئ؟');
  String get setLocationOnMap => _t('Set location on map', 'تعیین موقعیت روی نقشه', 'پر نقشه ځای وټاکئ');
  String get pickupFromCurrentLocation =>
      _t('Pickup at your current location', 'سوار شدن از موقعیت فعلی', 'له اوسني ځای څخه پورته کېدل');
  String get locationOffTitle => _t('Turn on location', 'موقعیت را روشن کنید', 'ځای روښانه کړئ');
  String get locationOffBody => _t(
        'We need your location to set the pickup. You can also search for the pickup address.',
        'برای تعیین مبدأ به موقعیت شما نیاز داریم. می‌توانید آدرس مبدأ را هم جستجو کنید.',
        'د پورته کېدو ځای ټاکلو لپاره ستاسو ځای ته اړتیا ده. تاسو کولی شئ پته هم ولټوئ.',
      );
  String get searchFailed => _t(
        'Search is not available right now',
        'جستجو فعلاً در دسترس نیست',
        'لټون اوس مهال شتون نه لري',
      );
  String get noPlacesFound => _t('No places found', 'جایی پیدا نشد', 'هېڅ ځای ونه موندل شو');
  String get rideActiveChip => _t('Ride in progress', 'سفر در جریان است', 'سفر روان دی');
  String get viewRide => _t('View', 'مشاهده', 'کتل');
  String get rideLater => _t('Later', 'بعداً', 'وروسته');
  String get menuLabel => _t('Menu', 'منو', 'مینو');

  // ---- Passenger: ride options ----
  String get chooseARide => _t('Choose a ride', 'انتخاب سفر', 'سفر وټاکئ');
  String chooseRideType(String name) => _t('Choose $name', 'انتخاب $name', '$name وټاکئ');
  String seats(int n) => _t('$n seats', '$n چوکی', '$n څوکۍ');
  String get addPromoCode => _t('Add promo code', 'افزودن کد تخفیف', 'د تخفیف کوډ زیات کړئ');
  String promoAppliedChip(String code) =>
      _t('Promo $code applied', 'کد $code اعمال شد', 'کوډ $code پلي شو');
  String get removePromo => _t('Remove', 'حذف', 'لرې کول');
  String get fareDetails => _t('Fare details', 'جزئیات کرایه', 'د کرایې تفصیل');
  String get fareEstimateNote => _t(
        'Price is an estimate and is paid in cash to your driver.',
        'قیمت تخمینی است و به صورت نقد به راننده پرداخت می‌شود.',
        'بیه اټکلي ده او چلوونکي ته په نغدو ورکول کېږي.',
      );
  String get fastestBadge => _t('Fastest', 'سریع‌ترین', 'تر ټولو چټک');
  String get confirmPickupSpot => _t('Confirm pickup spot', 'تأیید محل سوار شدن', 'د پورته کېدو ځای تایید کړئ');
  String get confirmPickupDragHint => _t(
        'Move the map to put the pin where your driver should stop.',
        'نقشه را حرکت دهید تا سنجاق جایی باشد که راننده باید توقف کند.',
        'نقشه وخوځوئ چې سنجاق هغه ځای ته ورشي چېرته چې چلوونکی ودرېږي.',
      );
  String get requestRide => _t('Request ride', 'درخواست سفر', 'د سفر غوښتنه');
  String get noRidesAvailable =>
      _t('No rides available here right now', 'فعلاً سفری در اینجا موجود نیست', 'دلته اوس مهال سفر نشته');

  // ---- Passenger: searching & matched ----
  String get connectingToDriver =>
      _t('Connecting you to a driver', 'در حال وصل کردن شما به راننده', 'تاسو له چلوونکي سره نښلول کېږئ');
  String get searchingNearbyHint => _t(
        'We are asking drivers near you. This usually takes under a minute.',
        'از راننده‌های نزدیک شما می‌پرسیم. معمولاً کمتر از یک دقیقه طول می‌کشد.',
        'له نږدې چلوونکو پوښتنه کوو. معمولاً له یوې دقیقې لږ وخت نیسي.',
      );
  String get driverFound => _t('Driver found', 'راننده پیدا شد', 'چلوونکی وموندل شو');
  String get driverOnTheWay => _t('Your driver is on the way', 'راننده در راه است', 'ستاسو چلوونکی په لاره دی');
  String get driverHereTitle => _t('Your driver is here', 'راننده رسیده است', 'ستاسو چلوونکی راورسېد');
  String get meetDriverHint => _t(
        'Meet your driver at the pickup spot.',
        'راننده را در محل سوار شدن ملاقات کنید.',
        'چلوونکی د پورته کېدو په ځای کې ووینئ.',
      );
  String headingTo(String place) => _t('Heading to $place', 'در راه $place', '$place ته روان');
  String get onYourWay => _t('On your way', 'در مسیر', 'په لاره کې');
  String get tripPinLabel => _t('Trip PIN', 'رمز سفر', 'د سفر پن');
  String get tripPinHint => _t(
        'Tell your driver this PIN to start the trip.',
        'این رمز را برای شروع سفر به راننده بگویید.',
        'د سفر پیلولو لپاره دا پن چلوونکي ته ووایاست.',
      );
  String get safetyToolkit => _t('Safety', 'ایمنی', 'خوندیتوب');
  String get safetyShareHint =>
      _t('Let someone follow your trip', 'بگذارید کسی سفر شما را دنبال کند', 'پرېږدئ څوک ستاسو سفر تعقیب کړي');
  String get safetySosHint => _t('Get help right away', 'فوراً کمک بگیرید', 'سمدستي مرسته ترلاسه کړئ');
  String get emergencyContactsHint =>
      _t('People we alert with SOS', 'افرادی که با SOS خبر می‌شوند', 'هغه کسان چې په SOS خبرېږي');

  // ---- Passenger: trip complete ----
  String howWasTripWith(String name) =>
      _t('How was your trip with $name?', 'سفر شما با $name چطور بود؟', 'له $name سره مو سفر څنګه و؟');
  String get youArrived => _t('You have arrived', 'رسیدید', 'تاسو ورسېدئ');
  String get addATip => _t('Add a tip', 'افزودن انعام', 'بخشش زیات کړئ');
  String get tipHint => _t(
        'Your whole tip goes to your driver. Pay it in cash with the fare.',
        'تمام انعام به راننده می‌رسد. آن را همراه کرایه نقد بپردازید.',
        'ټوله بخشش چلوونکي ته رسېږي. له کرایې سره یې په نغدو ورکړئ.',
      );
  String get noTip => _t('No tip', 'بدون انعام', 'بې بخششه');
  String tipAdded(String amount) => _t('Tip $amount added', 'انعام $amount افزوده شد', 'بخشش $amount زیات شو');
  String get viewReceipt => _t('View receipt', 'مشاهده رسید', 'رسید وګورئ');
  String get totalPaidCash => _t('Total (cash)', 'مجموع (نقد)', 'ټول (نغدې)');
  String get tipLabel => _t('Tip', 'انعام', 'بخشش');
  String get tripDetailsTitle => _t('Trip details', 'جزئیات سفر', 'د سفر تفصیل');
  String get whatWentWell => _t('What went well?', 'چه چیزی خوب بود؟', 'څه ښه وو؟');
  String get whatCouldBeBetter => _t('What could be better?', 'چه چیزی بهتر می‌شد؟', 'څه ښه کېدای شول؟');
  String get tipLocked => _t(
        'Your driver has already confirmed payment, so the tip can no longer change.',
        'راننده پرداخت را تأیید کرده است، بنابراین انعام دیگر تغییر نمی‌کند.',
        'چلوونکي پیسې تایید کړې، نو بخشش نور نه بدلېږي.',
      );
  String get tipFailed => _t("Couldn't update the tip. Try again.", 'انعام به‌روز نشد. دوباره تلاش کنید.', 'بخشش تازه نه شو. بیا هڅه وکړئ.');
  String get customTip => _t('Other', 'دیگر', 'نور');
  String get fareLabel => _t('Fare', 'کرایه', 'کرایه');
  String get shareReceipt => _t('Share receipt', 'اشتراک رسید', 'رسید شریک کړئ');
  String get doneLabel => _t('Done', 'تمام', 'بشپړ');

  // ---- Schedule ----
  String get tomorrowLabel => _t('Tomorrow', 'فردا', 'سبا');
  String get pickTime => _t('Pick a time', 'انتخاب زمان', 'وخت وټاکئ');

  // ---- Driver ----
  String get goLabel => _t('GO', 'برو', 'لاړ شه');
  String get findingTrips => _t('Finding trips', 'در حال یافتن سفر', 'سفرونه لټول کېږي');
  String get youAreOfflineTitle => _t("You're offline", 'شما آفلاین هستید', 'تاسو آفلاین یاست');
  String get onlineLabel => _t('Online', 'آنلاین', 'آنلاین');
  String get goOnlineHint => _t('Go online to start getting trips', 'برای دریافت سفر آنلاین شوید', 'د سفرونو د ترلاسه کولو لپاره آنلاین شئ');
  String get todayLabel => _t('Today', 'امروز', 'نن');
  String toPickup(int minutes, String km) =>
      _t('$minutes min ($km km) away', '$minutes دقیقه ($km کیلومتر) فاصله', '$minutes دقیقې ($km کیلومتره) لرې');
  String tripLength(int minutes, String km) =>
      _t('$minutes min ($km km) trip', 'سفر $minutes دقیقه ($km کیلومتر)', '$minutes دقیقې ($km کیلومتره) سفر');
  String get newTripRequest => _t('New trip request', 'درخواست سفر جدید', 'د نوي سفر غوښتنه');
  String get tapToAccept => _t('Tap to accept', 'برای قبول بزنید', 'د منلو لپاره ټک وکړئ');
  String get slideArrived => _t('Slide when arrived', 'پس از رسیدن بکشید', 'کله چې ورسېدئ کش یې کړئ');
  String get slideStartTrip => _t('Slide to start trip', 'برای شروع سفر بکشید', 'د سفر پیلولو لپاره کش کړئ');
  String get slideCompleteTrip => _t('Slide to complete trip', 'برای پایان سفر بکشید', 'د سفر پای ته رسولو لپاره کش کړئ');
  String get slideCashCollected => _t('Slide when cash collected', 'پس از دریافت نقد بکشید', 'کله چې نغدې واخیستې کش یې کړئ');
  String get enterRiderPin => _t("Enter rider's PIN", 'رمز مسافر را وارد کنید', 'د مسافر پن ولیکئ');
  String get enterRiderPinHint => _t(
        'Ask the rider for the 4-digit PIN shown in their app.',
        'رمز ۴ رقمی را که در اپ مسافر نشان داده شده بپرسید.',
        'له مسافر څخه هغه ۴ عددي پن وپوښتئ چې د هغه په اپ کې ښکاري.',
      );
  String get pinIncorrect => _t(
        "That PIN doesn't match. Ask the rider again.",
        'این رمز درست نیست. دوباره از مسافر بپرسید.',
        'دا پن سم نه دی. بیا له مسافر وپوښتئ.',
      );
  String get recalculatingRoute => _t('Recalculating route…', 'محاسبه دوباره مسیر…', 'لاره بیا محاسبه کېږي…');
  String get waitingForRider => _t('Waiting for rider', 'منتظر مسافر', 'د مسافر انتظار');
  String collectAmount(String amount) => _t('Collect $amount', 'دریافت $amount', '$amount واخلئ');
  String includesTip(String amount) => _t('Includes $amount tip', 'شامل $amount انعام', 'په کې $amount بخشش شامل دی');
  String rateRider(String name) => _t('How was $name?', '$name چطور بود؟', '$name څنګه و؟');
  String get backToMap => _t('Back to map', 'بازگشت به نقشه', 'نقشې ته بېرته');
  String get pickUpRider => _t('Pick up rider', 'سوار کردن مسافر', 'مسافر پورته کړئ');
  String get dropOffRider => _t('Drop off rider', 'پیاده کردن مسافر', 'مسافر کوز کړئ');
  String get tripOverview => _t('Trip overview', 'نمای کلی سفر', 'د سفر لنډیز');
  String get navigate => _t('Navigate', 'مسیریابی', 'لارښوونه');
}
