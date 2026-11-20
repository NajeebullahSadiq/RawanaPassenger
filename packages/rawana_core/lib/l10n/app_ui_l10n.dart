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
