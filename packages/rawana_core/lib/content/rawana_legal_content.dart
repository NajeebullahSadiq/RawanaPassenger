import '../l10n/app_localizations.dart';
import 'rawana_driver_content.dart';

String _pick(AppLocalizations l10n, String en, String fa, String ps) => switch (l10n.localeName) {
      'fa' => fa,
      'ps' => ps,
      _ => en,
    };

RawanaInfoSection _s(AppLocalizations l10n, List<String> title, List<String> body) => RawanaInfoSection(
      title: _pick(l10n, title[0], title[1], title[2]),
      body: _pick(l10n, body[0], body[1], body[2]),
    );

/// Rider terms of service.
List<RawanaInfoSection> localizedPassengerTerms(AppLocalizations l10n) => [
      _s(l10n, [
        'Using Rawana',
        'استفاده از راوانا',
        'د راوانا کارول',
      ], [
        'Rawana connects you with independent drivers in Afghanistan. By creating an account you confirm the details you give us are accurate and that you are at least 18 years old, or riding with a parent or guardian.',
        'راوانا شما را با رانندگان مستقل در افغانستان وصل می‌کند. با ساختن حساب تأیید می‌کنید که معلومات شما درست است و حداقل ۱۸ سال سن دارید یا همراه والدین یا سرپرست سفر می‌کنید.',
        'راوانا تاسو په افغانستان کې له خپلواکو موټروانانو سره نښلوي. د حساب په جوړولو سره تاسو تایيدوئ چې ستاسو معلومات سم دي او لږ تر لږه ۱۸ کلن یاست، یا له مور و پلار یا سرپرست سره سفر کوئ.',
      ]),
      _s(l10n, [
        'Fares and payment',
        'کرایه و پرداخت',
        'کرایه او تادیه',
      ], [
        'You see the fare before you book. Trips are paid in cash (AFN) to the driver at drop-off. The final fare can change if you add stops, change the destination or wait longer than the free waiting time.',
        'کرایه را پیش از درخواست می‌بینید. پول سفر به‌صورت نقد (افغانی) هنگام رسیدن به راننده پرداخت می‌شود. اگر توقف اضافه کنید، مقصد را تغییر دهید یا بیشتر از زمان انتظار رایگان منتظر بمانید، کرایهٔ نهایی ممکن است تغییر کند.',
        'تاسو کرایه د غوښتنې مخکې وینئ. د سفر پیسې په نغدو (افغانۍ) د رسېدو پر وخت موټروان ته ورکول کېږي. که تم ځای زیات کړئ، منزل بدل کړئ یا له وړیا انتظار څخه ډېر وخت انتظار وکړئ، وروستۍ کرایه بدلېدای شي.',
      ]),
      _s(l10n, [
        'Cancellations',
        'لغو سفر',
        'د سفر لغوه کول',
      ], [
        'You can cancel for free shortly after booking. Repeated late cancellations may limit how many rides you can book that day.',
        'کمی پس از درخواست می‌توانید رایگان لغو کنید. لغوهای مکرر و دیرهنگام ممکن است تعداد سفرهای آن روز شما را محدود کند.',
        'د غوښتنې لږ وروسته تاسو کولی شئ وړیا لغوه کړئ. په پرله‌پسې ډول ناوخته لغوه کول کېدای شي په هغه ورځ ستاسو د سفرونو شمېر محدود کړي.',
      ]),
      _s(l10n, [
        'Safety and conduct',
        'امنیت و رفتار',
        'خوندیتوب او چلند',
      ], [
        'Treat drivers with respect, wear a seatbelt and do not ask a driver to break traffic rules. Use the SOS button in an emergency. Accounts involved in abuse, fraud or unsafe behaviour can be suspended.',
        'با رانندگان محترمانه رفتار کنید، کمربند ایمنی ببندید و از راننده نخواهید قوانین ترافیکی را بشکند. در حالت اضطراری از دکمهٔ SOS استفاده کنید. حساب‌هایی که در آزار، تقلب یا رفتار ناامن دست داشته باشند ممکن است مسدود شوند.',
        'له موټروانانو سره په درناوي چلند وکړئ، د خوندیتوب کمربند وتړئ او له موټروان څخه د ترافیکي قوانینو د ماتولو غوښتنه مه کوئ. په بیړني حالت کې د SOS تڼۍ وکاروئ. هغه حسابونه چې په ځورونې، درغلۍ یا ناخوندي چلند کې ښکېل وي، ځنډول کېدای شي.',
      ]),
      _s(l10n, [
        'Lost items and disputes',
        'وسایل گم‌شده و اختلافات',
        'ورک شوي شیان او شخړې',
      ], [
        'Report lost items or fare problems from the trip details page within 7 days. Our support team reviews every report and replies in the app.',
        'وسایل گم‌شده یا مشکل کرایه را تا ۷ روز از صفحهٔ جزئیات سفر گزارش دهید. تیم پشتیبانی ما هر گزارش را بررسی و در برنامه پاسخ می‌دهد.',
        'ورک شوي شیان یا د کرایې ستونزې د سفر د جزیاتو له پاڼې څخه تر ۷ ورځو پورې راپور کړئ. زموږ د ملاتړ ټیم هر راپور ګوري او په اپ کې ځواب ورکوي.',
      ]),
      _s(l10n, [
        'Changes and contact',
        'تغییرات و تماس',
        'بدلونونه او اړیکه',
      ], [
        'We may update these terms. If the changes are significant we will tell you in the app before they apply. You can delete your account at any time from Profile > Privacy.',
        'ممکن است این شرایط را به‌روز کنیم. اگر تغییرات مهم باشد، پیش از اجرا در برنامه به شما اطلاع می‌دهیم. هر زمان می‌توانید حساب خود را از پروفایل > حریم خصوصی حذف کنید.',
        'موږ کېدای شي دا شرایط تازه کړو. که بدلونونه مهم وي، د پلي کېدو مخکې به یې په اپ کې درته ووایو. تاسو هر وخت کولی شئ خپل حساب له پروفایل > محرمیت څخه ړنګ کړئ.',
      ]),
    ];

/// Privacy policy shared by the rider and driver apps.
List<RawanaInfoSection> localizedPrivacyPolicy(AppLocalizations l10n, {required bool driver}) => [
      _s(l10n, [
        'What we collect',
        'چه معلوماتی جمع می‌کنیم',
        'موږ کوم معلومات راټولوو',
      ], [
        driver
            ? 'Your name, phone number, email, profile photo, driving licence, vehicle registration, national ID, vehicle details and payout account.'
            : 'Your name, phone number, email, saved places and emergency contacts.',
        driver
            ? 'نام، شمارهٔ تلفن، ایمیل، عکس پروفایل، جواز رانندگی، اسناد ثبت موتر، تذکره، مشخصات موتر و حساب دریافت پول شما.'
            : 'نام، شمارهٔ تلفن، ایمیل، مکان‌های ذخیره‌شده و مخاطبین اضطراری شما.',
        driver
            ? 'ستاسو نوم، د تلیفون شمېره، بریښنالیک، د پروفایل انځور، د موټر چلولو جواز، د موټر د ثبت سند، تذکره، د موټر جزیات او د پیسو ترلاسه کولو حساب.'
            : 'ستاسو نوم، د تلیفون شمېره، بریښنالیک، خوندي ځایونه او بیړني اړیکې.',
      ]),
      _s(l10n, [
        'Location',
        'موقعیت مکانی',
        'موقعیت',
      ], [
        driver
            ? 'While you are online and during trips we collect your location, including in the background, to match you with riders, share your position with your rider and calculate fares.'
            : 'We use your location to find your pickup, show nearby drivers and share trip progress. We only use it while you are using the app or on a trip.',
        driver
            ? 'وقتی آنلاین هستید و در طول سفر، موقعیت شما (حتی در پس‌زمینه) جمع می‌شود تا با مسافران وصل شوید، موقعیت شما به مسافر نشان داده شود و کرایه محاسبه گردد.'
            : 'از موقعیت شما برای پیدا کردن محل سوار شدن، نمایش رانندگان نزدیک و اشتراک پیشرفت سفر استفاده می‌کنیم. فقط هنگام استفاده از برنامه یا در طول سفر.',
        driver
            ? 'کله چې آنلاین یاست او د سفر پر مهال، ستاسو موقعیت (په شالید کې هم) راټولېږي ترڅو له سورلیو سره ونښلئ، ستاسو موقعیت سورلۍ ته وښودل شي او کرایه حساب شي.'
            : 'موږ ستاسو موقعیت د پورته کېدو ځای موندلو، نږدې موټروانانو ښودلو او د سفر د پرمختګ شریکولو لپاره کاروو. یوازې کله چې اپ کاروئ یا په سفر کې یاست.',
      ]),
      _s(l10n, [
        'How we use it',
        'چگونه استفاده می‌کنیم',
        'څنګه یې کاروو',
      ], [
        'To provide and improve rides, verify accounts, prevent fraud, handle support requests and keep riders and drivers safe. We never sell your personal data.',
        'برای ارائه و بهبود سفرها، تأیید حساب‌ها، جلوگیری از تقلب، رسیدگی به درخواست‌های پشتیبانی و حفظ امنیت مسافران و رانندگان. ما هرگز معلومات شخصی شما را نمی‌فروشیم.',
        'د سفرونو وړاندې کولو او ښه کولو، د حسابونو تایيد، د درغلۍ مخنیوي، د ملاتړ غوښتنو ځوابولو او د سورلیو او موټروانانو د خوندیتوب لپاره. موږ هېڅکله ستاسو شخصي معلومات نه پلورو.',
      ]),
      _s(l10n, [
        'What others see',
        'دیگران چه می‌بینند',
        'نور څه ویني',
      ], [
        driver
            ? 'Riders see your first name, photo, rating, vehicle and plate number for their trip. Your phone number is not shown in the app.'
            : 'Your driver sees your first name, rating and pickup point for the trip. Your phone number is not shown in the app.',
        driver
            ? 'مسافران برای سفر خود نام، عکس، امتیاز، موتر و نمبر پلیت شما را می‌بینند. شمارهٔ تلفن شما در برنامه نمایش داده نمی‌شود.'
            : 'رانندهٔ شما برای سفر نام، امتیاز و محل سوار شدن شما را می‌بیند. شمارهٔ تلفن شما در برنامه نمایش داده نمی‌شود.',
        driver
            ? 'سورلۍ د خپل سفر لپاره ستاسو نوم، انځور، درجه، موټر او د نمبر پلیټ ویني. ستاسو د تلیفون شمېره په اپ کې نه ښودل کېږي.'
            : 'ستاسو موټروان د سفر لپاره ستاسو نوم، درجه او د پورته کېدو ځای ویني. ستاسو د تلیفون شمېره په اپ کې نه ښودل کېږي.',
      ]),
      _s(l10n, [
        'Storage and security',
        'نگهداری و امنیت',
        'ساتنه او خوندیتوب',
      ], [
        'Data is encrypted in transit and stored with access limited to authorised staff. Trip records are kept for safety, tax and legal reasons; other data is removed when you delete your account.',
        'معلومات هنگام انتقال رمزگذاری می‌شوند و دسترسی به آن‌ها فقط برای کارمندان مجاز است. سوابق سفر به دلایل امنیتی، مالیاتی و قانونی نگهداری می‌شوند؛ سایر معلومات با حذف حساب پاک می‌شوند.',
        'معلومات د لېږد پر مهال کوډ کېږي او یوازې واکمن کارکوونکي ورته لاسرسی لري. د سفرونو ریکارډونه د خوندیتوب، مالیې او قانوني دلایلو لپاره ساتل کېږي؛ نور معلومات د حساب په ړنګولو سره پاکېږي.',
      ]),
      _s(l10n, [
        'Your choices',
        'اختیارات شما',
        'ستاسو اختیارونه',
      ], [
        'You can download your data or delete your account from Privacy settings, and turn off notifications or location in your phone settings at any time.',
        'می‌توانید معلومات خود را از تنظیمات حریم خصوصی دانلود یا حساب خود را حذف کنید و هر زمان اعلان‌ها یا موقعیت را از تنظیمات تلفن خاموش کنید.',
        'تاسو کولی شئ خپل معلومات د محرمیت له تنظیماتو ښکته کړئ یا خپل حساب ړنګ کړئ، او هر وخت خبرتیاوې یا موقعیت د تلیفون په تنظیماتو کې بند کړئ.',
      ]),
    ];
