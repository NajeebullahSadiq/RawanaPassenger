import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// Copy for the shared app-wide components and redesigned account screens.
/// Same hand-written style as `booking_l10n.dart`.
extension RawanaUiL10n on AppLocalizations {
  String _t(String en, String fa, String ps) => switch (localeName) {
        'fa' => fa,
        'ps' => ps,
        _ => en,
      };

  // ---- Generic API failures (shown by friendlyApiError) ----
  String get errorNoConnection => _t(
        'Cannot reach Rawana. Check your connection and try again.',
        'به راوانا وصل نشد. اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.',
        'راوانا ته نښلول ونه شول. خپل انټرنیټ وګورئ او بیا هڅه وکړئ.',
      );
  String get errorServer => _t(
        'The server hit a problem. Please try again shortly.',
        'سرور با مشکل روبه‌رو شد. لطفاً کمی بعد دوباره تلاش کنید.',
        'سرور له ستونزې سره مخ شو. مهرباني وکړئ لږ وروسته بیا هڅه وکړئ.',
      );
  String get errorSessionExpired => _t(
        'Your session has expired. Please sign in again.',
        'نشست شما پایان یافته است. لطفاً دوباره وارد شوید.',
        'ستاسو ناسته پای ته رسېدلې. مهرباني وکړئ بیا ننوځئ.',
      );
  String get errorTooManyAttempts => _t(
        'Too many attempts. Please wait a moment and try again.',
        'تلاش‌های زیاد. لطفاً کمی صبر کنید و دوباره تلاش کنید.',
        'ډېرې هڅې. مهرباني وکړئ لږ صبر وکړئ او بیا هڅه وکړئ.',
      );
  String get errorNotFound => _t(
        'That item could not be found.',
        'این مورد پیدا نشد.',
        'دا توکی ونه موندل شو.',
      );
  String get errorInvalidDetails => _t(
        'Some details are missing or invalid.',
        'برخی جزئیات ناقص یا نادرست است.',
        'ځینې معلومات نیمګړي یا ناسم دي.',
      );
  String get errorForbidden => _t(
        'You do not have permission to do that.',
        'شما اجازهٔ این کار را ندارید.',
        'تاسو د دې کار اجازه نه لرئ.',
      );
  String get errorUnsupportedFile => _t(
        'Use a JPG, PNG, WEBP or PDF file.',
        'از فایل JPG، PNG، WEBP یا PDF استفاده کنید.',
        'JPG، PNG، WEBP یا PDF فایل وکاروئ.',
      );
  String get errorFileTooLarge => _t(
        'That file is too large (max 10 MB).',
        'این فایل خیلی بزرگ است (حداکثر ۱۰ مگابایت).',
        'دا فایل ډېر لوی دی (تر ۱۰ MB پورې).',
      );
  String get errorCallingUnavailable => _t(
        'Calling is temporarily unavailable. Use in-app chat instead.',
        'تماس فعلاً در دسترس نیست. از گفتگوی داخل برنامه استفاده کنید.',
        'زنګ وهل اوس مهال شتون نه لري. د اپ دننه چټ وکاروئ.',
      );

  // ---- Legal ----
  String get termsOfService => _t('Terms of Service', 'شرایط استفاده', 'د کارونې شرایط');
  String get privacyPolicy => _t('Privacy Policy', 'سیاست حریم خصوصی', 'د محرمیت تګلاره');
  String get byContinuingYouAgree =>
      _t('By continuing you agree to the ', 'با ادامه، شما با ', 'په دوام سره تاسو د ');
  String get andConnector => _t(' and ', ' و ', ' او ');
  String get agreeSuffix => _t('.', ' موافقت می‌کنید.', ' سره موافق یاست.');
  String get legalLastUpdated => _t('Last updated: November 2026', 'آخرین به‌روزرسانی: نوامبر ۲۰۲۶', 'وروستی تازه: نومبر ۲۰۲۶');
  String get legalQuestions => _t(
        'Questions? Contact support@rawana.af',
        'سوالی دارید؟ با support@rawana.af تماس بگیرید',
        'پوښتنه لرئ؟ له support@rawana.af سره اړیکه ونیسئ',
      );

  // ---- Trip detail ----
  String get openReceipt => _t('Open receipt', 'باز کردن رسید', 'رسید پرانیزئ');
  String get receiptNotReady => _t(
        'The receipt is not ready yet. Try again in a minute.',
        'رسید هنوز آماده نیست. یک دقیقه بعد دوباره تلاش کنید.',
        'رسید لا چمتو نه دی. یوه دقیقه وروسته بیا هڅه وکړئ.',
      );

  // ---- Photos ----
  String get addPhoto => _t('Add a photo', 'افزودن عکس', 'انځور زیات کړئ');
  String get takePhoto => _t('Take a photo', 'گرفتن عکس', 'انځور واخلئ');
  String get chooseFromGallery => _t('Choose from gallery', 'انتخاب از گالری', 'له ګالري وټاکئ');
  String get changePhoto => _t('Change photo', 'تغییر عکس', 'انځور بدل کړئ');

  // ---- Auth flow ----
  String get devOtpHintWhatsApp => 'Dev WhatsApp code: 123456';
  String get devOtpHintSms => 'Dev build: check the Supabase SMS log';
  String get changeNumber => _t('Change number', 'تغییر شماره', 'شمېره بدله کړئ');
  String get verifyingCode => _t('Verifying…', 'در حال تأیید…', 'تایيدېږي…');

  String get showPassword => _t('Show password', 'نمایش رمز', 'پټنوم ښکاره کړئ');
  String get hidePassword => _t('Hide password', 'پنهان کردن رمز', 'پټنوم پټ کړئ');
  String get justNow => _t('Just now', 'همین حالا', 'همدا اوس');
  String minutesAgo(int n) => _t('$n min ago', '$n دقیقه پیش', '$n دقیقې مخکې');
  String hoursAgo(int n) => _t('$n h ago', '$n ساعت پیش', '$n ساعته مخکې');
  String get yesterdayLabel => _t('Yesterday', 'دیروز', 'پرون');

  // ---- Account ----
  String get yourData => _t('Your data', 'اطلاعات شما', 'ستاسو معلومات');
  String get legalSection => _t('Legal', 'حقوقی', 'حقوقي');
  String get nameTooShort => _t('Enter at least 2 characters', 'حداقل ۲ حرف وارد کنید', 'لږ تر لږه ۲ توري ولیکئ');
  String get fieldRequired => _t('This field is required', 'این بخش الزامی است', 'دا برخه اړینه ده');
  String get deleteLabel => _t('Delete', 'حذف', 'ړنګول');
  String get exportMyDataHint =>
      _t('Copy your account data to the clipboard', 'کپی اطلاعات حساب شما', 'ستاسو د حساب معلوماتو کاپي');
  String get deleteAccountHint =>
      _t('Permanently remove your account', 'حذف دائمی حساب شما', 'ستاسو حساب د تل لپاره لرې کول');
  String get editAddress => _t('Edit address', 'ویرایش آدرس', 'پته سمول');
  String get addressSaved => _t('Address saved', 'آدرس ذخیره شد', 'پته خوندي شوه');
  String get addressUpdated => _t('Address updated', 'آدرس به‌روز شد', 'پته تازه شوه');
  String get locationPinned => _t('Pinned on map', 'روی نقشه مشخص شد', 'په نقشه وټاکل شو');
  String get deleteAddressQuestion => _t('Delete this address?', 'این آدرس حذف شود؟', 'دا پته ړنګه شي؟');
  String deleteAddressMessage(String label) => _t(
        '"$label" will be removed from your saved places.',
        '«$label» از مکان‌های ذخیره‌شده شما حذف می‌شود.',
        '«$label» به ستاسو له خوندي ځایونو څخه لرې شي.',
      );
  String get contactSaved => _t('Contact saved', 'مخاطب ذخیره شد', 'اړیکه خوندي شوه');
  String get contactPhoneInvalid =>
      _t('Enter a valid phone number', 'یک شماره تلفن معتبر وارد کنید', 'سمه د تلیفون شمېره ولیکئ');
  String get removeContactQuestion => _t('Remove this contact?', 'این مخاطب حذف شود؟', 'دا اړیکه لرې شي؟');
  String removeContactMessage(String name) => _t(
        '$name will no longer be alerted when you press SOS.',
        'وقتی SOS را بزنید، دیگر به $name خبر داده نمی‌شود.',
        'کله چې SOS ووهئ، $name ته به نور خبر ورنه کړل شي.',
      );
  String get removeLabel => _t('Remove', 'حذف', 'لرې کول');

  // ---- Driver onboarding ----
  String get reviewerNote => _t('Note from our review team', 'یادداشت تیم بررسی ما', 'زموږ د بیاکتنې ټیم یادښت');
  String get statusAutoRefresh =>
      _t('This page updates automatically.', 'این صفحه به‌طور خودکار به‌روز می‌شود.', 'دا پاڼه په خپله تازه کېږي.');

  String get approvalPending => _t('In review', 'در حال بررسی', 'د بیاکتنې لاندې');
  String get approvalApproved => _t('Approved', 'تأیید شد', 'تایید شو');
  String get approvalRejected => _t('Not approved', 'تأیید نشد', 'تایید نه شو');
  String approvalStatusLabel(String status) => switch (status) {
        'approved' => approvalApproved,
        'rejected' => approvalRejected,
        _ => approvalPending,
      };
  /// Rating tags are stored by their English label.
  String ratingTagLabel(String key) => switch (key) {
        'Clean car' => ratingTagCleanCar,
        'Safe driving' => ratingTagSafeDriving,
        'Friendly driver' => ratingTagFriendlyDriver,
        'On time' => ratingTagOnTime,
        'Good navigation' => ratingTagGoodNavigation,
        _ => key,
      };

  String get onlineTrackingTitle => _t(
        'You are online',
        'شما آنلاین هستید',
        'تاسو آنلاین یاست',
      );
  String get onlineTrackingBody => _t(
        'Rawana is sharing your location to match you with nearby riders.',
        'روانا موقعیت شما را برای وصل‌کردن با مسافران نزدیک شریک می‌کند.',
        'روانا ستاسو موقعیت د نږدې سپرلیو سره د نښلولو لپاره شریکوي.',
      );

  String get addPayoutDetailsFirst => _t(
        'Add your payout method and account below before requesting a payout.',
        'پیش از درخواست پرداخت، روش و حساب پرداخت خود را در پایین اضافه کنید.',
        'د تادیې غوښتنې مخکې، لاندې خپله د تادیې طریقه او حساب ورګډ کړئ.',
      );
  String payoutDestination(String method, String account) => _t(
        'To: $method · $account',
        'به: $method · $account',
        'ته: $method · $account',
      );

  String vehicleYearInvalid(int max) =>
      _t('Enter a year between 1980 and $max', 'سالی بین ۱۹۸۰ و $max وارد کنید', 'د ۱۹۸۰ او $max ترمنځ کال ولیکئ');

  // ---- Support ----
  String get ticketStatusInProgress => _t('In progress', 'در حال بررسی', 'د څېړنې لاندې');
  String get ticketStatusResolved => _t('Resolved', 'حل شد', 'حل شو');
  String get supportAgentLabel => _t('Rawana support', 'پشتیبانی روانا', 'د روانا ملاتړ');
  String get youLabel => _t('You', 'شما', 'تاسو');
  String get ticketResolvedNote =>
      _t('This ticket is resolved. Reply to reopen it.', 'این درخواست حل شده است. برای باز کردن دوباره پاسخ دهید.', 'دا غوښتنه حل شوې. د بیا پرانیستلو لپاره ځواب ورکړئ.');

  // ---- Help ----
  String get faqCancelTitle => _t('Can I cancel a ride?', 'آیا می‌توانم سفر را لغو کنم؟', 'ایا زه سفر لغوه کولی شم؟');
  String get faqCancelBody => _t(
        'Yes. Tap Cancel on the trip screen. If a cancellation fee applies, you will see it before you confirm.',
        'بله. در صفحه سفر روی لغو بزنید. اگر هزینه لغو وجود داشته باشد، پیش از تأیید به شما نشان داده می‌شود.',
        'هو. د سفر په پاڼه کې لغوه کېکاږئ. که د لغوې فیس وي، د تایید مخکې به یې ووینئ.',
      );
  String get faqSafetyTitle => _t('How does SOS work?', 'SOS چگونه کار می‌کند؟', 'SOS څنګه کار کوي؟');
  String get faqSafetyBody => _t(
        'During a ride, tap SOS to alert your emergency contacts with your live trip details. In immediate danger, call 119.',
        'در طول سفر روی SOS بزنید تا مخاطبین اضطراری شما با جزئیات زنده سفر خبر شوند. در خطر فوری با ۱۱۹ تماس بگیرید.',
        'د سفر پر مهال SOS کېکاږئ څو ستاسو بیړني اړیکې د سفر ژوندیو معلوماتو سره خبر شي. په سمدستي خطر کې ۱۱۹ ته زنګ ووهئ.',
      );
  String get faqScheduleTitle => _t('Can I book a ride for later?', 'آیا می‌توانم سفر را برای بعد رزرو کنم؟', 'ایا زه د وروسته لپاره سفر بک کولی شم؟');
  String get faqScheduleBody => _t(
        'Yes. When choosing your ride, pick a later pickup time instead of now. You can see or cancel it under Scheduled rides.',
        'بله. هنگام انتخاب سفر، به جای حالا یک زمان بعدی برای سوار شدن انتخاب کنید. می‌توانید آن را در سفرهای زمان‌بندی‌شده ببینید یا لغو کنید.',
        'هو. د سفر د ټاکلو پر مهال، د اوس پر ځای د سپرېدو وروسته وخت وټاکئ. تاسو یې په مهالویش شویو سفرونو کې لیدلی یا لغوه کولی شئ.',
      );
  String get faqLostItemTitle => _t('I left something in the car', 'چیزی را در موتر جا گذاشتم', 'ما څه په موټر کې پاتې کړي');
  String get faqLostItemBody => _t(
        'Open the trip in Ride history and tap Report an issue. Our team will contact the driver for you.',
        'سفر را از تاریخچه سفرها باز کنید و روی گزارش مشکل بزنید. تیم ما برای شما با راننده تماس می‌گیرد.',
        'سفر د سفرونو له تاریخچې پرانیزئ او د ستونزې راپور کېکاږئ. زموږ ټیم به ستاسو لپاره له چلوونکي سره اړیکه ونیسي.',
      );

  /// Short relative time for feeds: "Just now", "5 min ago", "Yesterday", "12 Mar".
  String relativeTime(DateTime t, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final local = t.toLocal();
    final diff = ref.difference(local);
    if (diff.inMinutes < 1) return justNow;
    if (diff.inMinutes < 60) return minutesAgo(diff.inMinutes);
    if (diff.inHours < 24 && local.day == ref.day) return hoursAgo(diff.inHours);
    final yesterday = DateTime(ref.year, ref.month, ref.day).subtract(const Duration(days: 1));
    if (!local.isBefore(yesterday)) return yesterdayLabel;
    if (local.year == ref.year) return intl.DateFormat.MMMd(localeName).format(local);
    return intl.DateFormat.yMMMd(localeName).format(local);
  }
}
