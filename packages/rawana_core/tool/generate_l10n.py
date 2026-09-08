#!/usr/bin/env python3
"""Generate ARB files and Flutter AppLocalizations Dart sources."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

STRINGS: dict[str, dict[str, str]] = {
    # Brand / chrome
    "appName": {"en": "Rawana", "fa": "روانا", "ps": "روانا"},
    "appTitlePassenger": {"en": "Rawana Passenger", "fa": "روانا مسافر", "ps": "روانا مسافر"},
    "appTitleDriver": {"en": "Rawana Driver", "fa": "روانا راننده", "ps": "روانا چلوونکی"},
    "appVersionFooter": {"en": "Rawana · v1.0", "fa": "روانا · نسخه ۱.۰", "ps": "روانا · نسخه ۱.۰"},
    "rawanaDriver": {"en": "Rawana Driver", "fa": "روانا راننده", "ps": "روانا چلوونکی"},
    "rawanaDriverVersion": {"en": "Rawana Driver  v1.0", "fa": "روانا راننده  نسخه ۱.۰", "ps": "روانا چلوونکی  نسخه ۱.۰"},
    "rawanaDriverRole": {"en": "Rawana driver", "fa": "راننده روانا", "ps": "د روانا چلوونکی"},
    "splashTagline": {"en": "Smooth rides, anywhere in Kabul", "fa": "سفرهای راحت، در هر نقطه کابل", "ps": "آرام سفرونه، په ټول کابل کې"},
    "splashLoading": {"en": "Loading your ride…", "fa": "سفر شما بارگذاری می‌شود…", "ps": "ستاسو سفر بارېږي…"},
    "driverBadge": {"en": "DRIVER", "fa": "راننده", "ps": "چلوونکی"},
    "riderBadge": {"en": "RIDER", "fa": "مسافر", "ps": "مسافر"},
    "preparingDashboard": {"en": "Preparing your dashboard", "fa": "داشبورد شما آماده می‌شود", "ps": "ستاسو ډشبورډ چمتو کېږي"},

    # Common actions
    "cancel": {"en": "Cancel", "fa": "لغو", "ps": "لغوه"},
    "confirm": {"en": "Confirm", "fa": "تأیید", "ps": "تایید"},
    "next": {"en": "Next", "fa": "بعدی", "ps": "بل"},
    "skip": {"en": "Skip", "fa": "رد کردن", "ps": "پرېښودل"},
    "back": {"en": "Back", "fa": "بازگشت", "ps": "شاته"},
    "edit": {"en": "Edit", "fa": "ویرایش", "ps": "سمول"},
    "retry": {"en": "Retry", "fa": "تلاش دوباره", "ps": "بیا هڅه"},
    "tryAgain": {"en": "Try again", "fa": "دوباره تلاش کنید", "ps": "بیا هڅه وکړئ"},
    "continueAction": {"en": "Continue", "fa": "ادامه", "ps": "ادامه"},
    "add": {"en": "Add", "fa": "افزودن", "ps": "زیاتول"},
    "save": {"en": "Save", "fa": "ذخیره", "ps": "ساتل"},
    "submit": {"en": "Submit", "fa": "ارسال", "ps": "لېږل"},
    "details": {"en": "Details", "fa": "جزئیات", "ps": "تفصیل"},
    "map": {"en": "Map", "fa": "نقشه", "ps": "نقشه"},
    "selected": {"en": "selected", "fa": "انتخاب‌شده", "ps": "ټاکل شوی"},
    "notSet": {"en": "Not set", "fa": "تنظیم نشده", "ps": "نه دی ټاکل شوی"},
    "other": {"en": "Other", "fa": "سایر", "ps": "نور"},
    "orDivider": {"en": "OR", "fa": "یا", "ps": "یا"},
    "loading": {"en": "Loading…", "fa": "در حال بارگذاری…", "ps": "بارېږي…"},
    "connecting": {"en": "Connecting…", "fa": "در حال اتصال…", "ps": "نښلول کېږي…"},
    "submitting": {"en": "Submitting…", "fa": "در حال ارسال…", "ps": "لېږل کېږي…"},
    "checking": {"en": "Checking…", "fa": "در حال بررسی…", "ps": "چک کېږي…"},
    "requesting": {"en": "Requesting…", "fa": "در حال درخواست…", "ps": "غوښتنه کېږي…"},
    "confirming": {"en": "Confirming...", "fa": "در حال تأیید...", "ps": "تایید کېږي..."},
    "signingIn": {"en": "Signing in…", "fa": "در حال ورود…", "ps": "ننوتل کېږي…"},
    "somethingWentWrong": {"en": "Something went wrong", "fa": "مشکلی پیش آمد", "ps": "ستونزه رامنځته شوه"},
    "errorWithDetail": {"en": "Error: {error}", "fa": "خطا: {error}", "ps": "تېروتنه: {error}"},
    "getStarted": {"en": "Get Started", "fa": "شروع کنید", "ps": "پیل کړئ"},

    # Existing catalog keys
    "whereTo": {"en": "Where to?", "fa": "کجا می‌روید؟", "ps": "چیرته ځئ؟"},
    "confirmRide": {"en": "Confirm Ride", "fa": "تأیید سفر", "ps": "سفر تایید کړئ"},
    "findingDriver": {"en": "Finding your driver…", "fa": "در حال یافتن راننده…", "ps": "چلوونکی په لټه کې…"},
    "findingYourDriver": {"en": "Finding your driver", "fa": "در حال یافتن راننده", "ps": "ستاسو چلوونکی لټول کېږي"},
    "driverArriving": {"en": "Driver Arriving", "fa": "راننده در راه است", "ps": "چلوونکی رارسېږي"},
    "tripStarted": {"en": "On the way", "fa": "در مسیر مقصد", "ps": "په لاره کې"},
    "tripCompleted": {"en": "Trip Completed", "fa": "سفر تکمیل شد", "ps": "سفر بشپړ شو"},
    "payCash": {"en": "Pay {amount} in cash", "fa": "پرداخت {amount} نقدی", "ps": "نغدي {amount} ورکړئ"},
    "currencyAfn": {"en": "AFN", "fa": "افغانی", "ps": "افغانۍ"},
    "sendCode": {"en": "Send code", "fa": "ارسال کد", "ps": "کوډ ولیږئ"},
    "verifyOtp": {"en": "Verify", "fa": "تأیید", "ps": "تایید"},
    "resendCode": {"en": "Resend code", "fa": "ارسال مجدد", "ps": "بیا ولیږئ"},
    "goOnline": {"en": "Go online", "fa": "آنلاین شوید", "ps": "آنلاین شئ"},
    "goOffline": {"en": "Go offline", "fa": "آفلاین شوید", "ps": "آفلاین شئ"},
    "accept": {"en": "Accept", "fa": "قبول", "ps": "منل"},
    "reject": {"en": "Reject", "fa": "رد", "ps": "رد"},
    "decline": {"en": "Decline", "fa": "رد کردن", "ps": "ردول"},
    "cancelRide": {"en": "Cancel ride", "fa": "لغو سفر", "ps": "سفر لغوه کړئ"},
    "earnings": {"en": "Earnings", "fa": "درآمد", "ps": "عاید"},
    "wallet": {"en": "Wallet", "fa": "کیف پول", "ps": "بټوه"},
    "history": {"en": "History", "fa": "تاریخچه", "ps": "تاریخچه"},
    "profile": {"en": "Profile", "fa": "پروفایل", "ps": "پروفایل"},
    "logout": {"en": "Logout", "fa": "خروج", "ps": "وتل"},
    "logOut": {"en": "Log out", "fa": "خروج", "ps": "وتل"},
    "signOut": {"en": "Sign out", "fa": "خروج از حساب", "ps": "له حسابه وتل"},
    "noConnection": {"en": "No internet connection", "fa": "اتصال اینترنت وجود ندارد", "ps": "انټرنیټ نشته"},
    "reconnecting": {"en": "Reconnecting…", "fa": "در حال اتصال مجدد…", "ps": "بیا نښلول…"},
    "youAreOfflineReconnect": {"en": "You are offline — reconnect to continue", "fa": "آفلاین هستید — برای ادامه وصل شوید", "ps": "تاسو آفلاین یاست — د دوام لپاره وصل شئ"},

    # Language
    "language": {"en": "Language", "fa": "زبان", "ps": "ژبه"},
    "chooseYourLanguage": {"en": "Choose your language", "fa": "زبان خود را انتخاب کنید", "ps": "خپله ژبه وټاکئ"},
    "languageChangeHint": {"en": "You can change this anytime from settings.", "fa": "هر زمان می‌توانید این را از تنظیمات تغییر دهید.", "ps": "دا هر وخت له تنظیماتو بدلولی شئ."},
    "languageEnglish": {"en": "English", "fa": "English", "ps": "English"},
    "languageDari": {"en": "دری", "fa": "دری", "ps": "دري"},
    "languagePashto": {"en": "پښتو", "fa": "پښتو", "ps": "پښتو"},
    "languageEnglishMeta": {"en": "LTR · Latin", "fa": "چپ به راست · لاتین", "ps": "کيڼ نه ښي · لاتین"},
    "languageDariMeta": {"en": "RTL · Dari", "fa": "راست به چپ · دری", "ps": "ښي نه کيڼ · دري"},
    "languagePashtoMeta": {"en": "RTL · Pashto", "fa": "راست به چپ · پشتو", "ps": "ښي نه کيڼ · پښتو"},

    # Onboarding
    "onboardingSlide1Title": {"en": "Book a ride in seconds", "fa": "سفر را در چند ثانیه رزرو کنید", "ps": "سفر په ثانیو کې ونیسئ"},
    "onboardingSlide1Body": {"en": "Set your destination and confirm — the nearest driver will be on the way.", "fa": "مقصد را مشخص کنید و تأیید کنید — نزدیک‌ترین راننده در راه خواهد بود.", "ps": "خپل منزل وټاکئ او تایید یې کړئ — نږدې چلوونکی به په لاره وي."},
    "onboardingSlide2Title": {"en": "Track every kilometre", "fa": "هر کیلومتر را دنبال کنید", "ps": "هر کیلومتر تعقیب کړئ"},
    "onboardingSlide2Body": {"en": "See your driver approach in real time on the map, and share trip status with loved ones.", "fa": "راننده را زنده روی نقشه ببینید و وضعیت سفر را با عزیزان شریک کنید.", "ps": "خپل چلوونکی په ژوندۍ نقشه کې وګورئ او د سفر حالت له خپلوانو سره شریک کړئ."},
    "onboardingSlide3Title": {"en": "Cash made simple", "fa": "پرداخت نقدی ساده", "ps": "نغدي تادیه ساده شوه"},
    "onboardingSlide3Body": {"en": "Pay your driver directly in Afghan Afghani (AFN) when you arrive. No card needed.", "fa": "در مقصد مستقیماً به افغانی (AFN) به راننده بپردازید. کارت لازم نیست.", "ps": "په منزل کې چلوونکي ته په افغانۍ (AFN) ورکړئ. کارت ته اړتیا نشته."},

    # Auth shared
    "continueWithEmail": {"en": "Continue with Email", "fa": "ادامه با ایمیل", "ps": "د ایمیل سره ادامه"},
    "continueWithPhone": {"en": "Continue with phone", "fa": "ادامه با تلفن", "ps": "د تلیفون سره ادامه"},
    "authTermsFooter": {"en": "By continuing you agree to our Terms & Privacy Policy.", "fa": "با ادامه، با شرایط و سیاست حریم خصوصی موافقت می‌کنید.", "ps": "په دوام سره زموږ شرایط او د محرمیت تګلاره منئ."},
    "agreeTermsConduct": {"en": "By continuing you agree to our Terms & Driver Code of Conduct.", "fa": "با ادامه، با شرایط و آیین‌نامه رانندگان موافقت می‌کنید.", "ps": "په دوام سره زموږ شرایط او د چلوونکو د چلند اصول منئ."},
    "createAccount": {"en": "Create account", "fa": "ایجاد حساب", "ps": "حساب جوړول"},
    "welcomeBack": {"en": "Welcome back", "fa": "خوش آمدید", "ps": "بیرته ښه راغلاست"},
    "welcomeBackCaptain": {"en": "Welcome back, captain", "fa": "خوش آمدید، کاپیتان", "ps": "بیرته ښه راغلاست، کپتان"},
    "signUpSubtitle": {"en": "A few details and you are ready to ride.", "fa": "چند جزئیات و آماده سفر هستید.", "ps": "یو څو معلومات او تاسو د سفر لپاره چمتو یاست."},
    "signInSubtitle": {"en": "Sign in to keep riding.", "fa": "وارد شوید تا سفر ادامه یابد.", "ps": "ننوزئ ترڅو سفر ته دوام ورکړئ."},
    "emailLabel": {"en": "Email", "fa": "ایمیل", "ps": "ایمیل"},
    "emailOptional": {"en": "Email (optional)", "fa": "ایمیل (اختیاری)", "ps": "ایمیل (اختیاري)"},
    "fullName": {"en": "Full name", "fa": "نام کامل", "ps": "بشپړ نوم"},
    "fullNameRequired": {"en": "Full name *", "fa": "نام کامل *", "ps": "بشپړ نوم *"},
    "phoneNumberRequired": {"en": "Phone number *", "fa": "شماره تلفن *", "ps": "د تلیفون شمېره *"},
    "afPhonePrefix": {"en": "🇦🇫 +93", "fa": "🇦🇫 +93", "ps": "🇦🇫 +93"},
    "phoneHint": {"en": "70 123 4567", "fa": "70 123 4567", "ps": "70 123 4567"},
    "passwordLabel": {"en": "Password", "fa": "رمز عبور", "ps": "پاسورډ"},
    "signIn": {"en": "Sign in", "fa": "ورود", "ps": "ننوتل"},
    "alreadyHaveAccount": {"en": "Already have an account? Sign in", "fa": "حساب دارید؟ وارد شوید", "ps": "حساب لرئ؟ ننوزئ"},
    "newHereCreateAccount": {"en": "New here? Create an account", "fa": "تازه هستید؟ حساب بسازید", "ps": "نوی یاست؟ حساب جوړ کړئ"},
    "phoneOtpComingSoon": {"en": "Phone OTP will be enabled in production.", "fa": "کد تلفنی در نسخه نهایی فعال می‌شود.", "ps": "د تلیفون کوډ به په اصلي نسخه کې فعال شي."},
    "authEntryHeadline": {"en": "Let's get you\nmoving.", "fa": "بیایید حرکت\nکنیم.", "ps": "راځئ تاسو\nوخوځوو."},
    "authEntrySubtitle": {"en": "Sign in to book rides across Kabul in seconds.", "fa": "وارد شوید و در چند ثانیه در کابل سفر رزرو کنید.", "ps": "ننوزئ او په کابل کې په ثانیو کې سفر ونیسئ."},
    "authValueFastTitle": {"en": "Fast booking", "fa": "رزرو سریع", "ps": "چټک نیول"},
    "authValueFastBody": {"en": "Find a nearby driver in under a minute.", "fa": "راننده نزدیک را در کمتر از یک دقیقه پیدا کنید.", "ps": "نږدې چلوونکی په یوه دقیقه کې ومومئ."},
    "authValueTrustedTitle": {"en": "Trusted drivers", "fa": "رانندگان معتبر", "ps": "باوري چلوونکي"},
    "authValueTrustedBody": {"en": "Every driver is verified and rated.", "fa": "هر راننده تأیید و امتیازدهی شده است.", "ps": "هر چلوونکی تایید او درجه بندي شوی دی."},
    "authValuePayTitle": {"en": "Pay in AFN cash", "fa": "پرداخت نقدی افغانی", "ps": "په افغانۍ نغدي ورکړئ"},
    "authValuePayBody": {"en": "No card required — pay at trip end.", "fa": "کارت لازم نیست — در پایان سفر بپردازید.", "ps": "کارت ته اړتیا نشته — د سفر په پای کې ورکړئ."},
    "driveWithRawana": {"en": "Drive with\nRawana.", "fa": "با روانا\nرانندگی کنید.", "ps": "د روانا سره\nموټر چلوئ."},
    "signInEmailToTest": {"en": "Sign in with email to test the driver experience.", "fa": "با ایمیل وارد شوید تا تجربه راننده را ببینید.", "ps": "د چلوونکي تجربه ازمویلو لپاره په ایمیل ننوزئ."},
    "earnOnYourSchedule": {"en": "Earn on your own schedule. Get verified, get rides, get paid.", "fa": "طبق برنامه خود درآمد داشته باشید. تأیید شوید، سفر بگیرید، پول بگیرید.", "ps": "په خپل مهال عاید وکړئ. تایید شئ، سفرونه واخلئ، پیسې واخلئ."},
    "earnFlexibly": {"en": "Earn flexibly", "fa": "درآمد انعطاف‌پذیر", "ps": "انعطاف منونکی عاید"},
    "goOnlineWhenever": {"en": "Go online whenever you want.", "fa": "هر زمان که بخواهید آنلاین شوید.", "ps": "هر وخت چې غواړئ آنلاین شئ."},
    "dailyPayouts": {"en": "Daily payouts", "fa": "پرداخت روزانه", "ps": "ورځني تادیات"},
    "trackEveryFare": {"en": "Track every fare in your wallet.", "fa": "هر کرایه را در کیف پول دنبال کنید.", "ps": "هر کرایه په خپله بټوه کې تعقیب کړئ."},
    "driverSupport": {"en": "Driver support", "fa": "پشتیبانی راننده", "ps": "د چلوونکي ملاتړ"},
    "supportTeam247": {"en": "A team that has your back, 24/7.", "fa": "تیمی که شبانه‌روز پشتیبان شماست.", "ps": "یوه ډله چې شپه او ورځ ستاسو مل وي."},
    "becomeADriver": {"en": "Become a driver", "fa": "راننده شوید", "ps": "چلوونکی شئ"},
    "createDriverAccountInAMinute": {"en": "Create your driver account in a minute.", "fa": "حساب رانندگی را در یک دقیقه بسازید.", "ps": "خپل د چلوونکي حساب په یوه دقیقه کې جوړ کړئ."},
    "signInToGoOnline": {"en": "Sign in to go online.", "fa": "برای آنلاین شدن وارد شوید.", "ps": "د آنلاین کېدو لپاره ننوزئ."},
    "createDriverAccount": {"en": "Create driver account", "fa": "ایجاد حساب راننده", "ps": "د چلوونکي حساب جوړول"},
    "alreadyADriverSignIn": {"en": "Already a driver? Sign in", "fa": "قبلاً راننده هستید؟ وارد شوید", "ps": "دمخه چلوونکی یاست؟ ننوزئ"},
    "newDriverCreateAccount": {"en": "New driver? Create account", "fa": "راننده جدید؟ حساب بسازید", "ps": "نوی چلوونکی؟ حساب جوړ کړئ"},
    "enterYourPhone": {"en": "Enter your phone", "fa": "شماره تلفن را وارد کنید", "ps": "خپل تلیفون ولیکئ"},
    "phoneVerifyHint": {"en": "We will send a 6-digit code to verify it is really you.", "fa": "یک کد ۶ رقمی می‌فرستیم تا هویت شما تأیید شود.", "ps": "یو ۶ عددي کوډ درلېږو ترڅو تایید شي چې تاسو یاست."},
    "phoneKeepsAccountSecure": {"en": "We use this to keep your driver account secure.", "fa": "از این برای امنیت حساب رانندگی شما استفاده می‌کنیم.", "ps": "دا ستاسو د چلوونکي حساب د خوندي ساتلو لپاره کاروو."},
    "otpChannelSms": {"en": "SMS", "fa": "پیامک", "ps": "ایس‌ام‌اس"},
    "otpChannelWhatsApp": {"en": "WhatsApp", "fa": "واتساپ", "ps": "واټساپ"},
    "otpSessionExpired": {"en": "Session expired. Go back and request a new code.", "fa": "نشست منقضی شد. برگردید و کد جدید بگیرید.", "ps": "ناسته پای ته ورسېده. شاته لاړ شئ او نوی کوډ وغواړئ."},
    "verificationCode": {"en": "Verification code", "fa": "کد تأیید", "ps": "د تایید کوډ"},
    "otpEnterCodeVia": {"en": "Enter the 6-digit code we sent via {channel}.", "fa": "کد ۶ رقمی را که از طریق {channel} فرستادیم وارد کنید.", "ps": "هغه ۶ عددي کوډ وليکئ چې له {channel} مو درلېږلی."},
    "otpEnterCodeViaTo": {"en": "Enter the 6-digit code we sent via {channel} to {phone}.", "fa": "کد ۶ رقمی را که از طریق {channel} به {phone} فرستادیم وارد کنید.", "ps": "هغه ۶ عددي کوډ وليکئ چې له {channel} مو {phone} ته لېږلی."},
    "resendCodeInSeconds": {"en": "Resend code in {seconds}s", "fa": "ارسال مجدد تا {seconds} ثانیه", "ps": "کوډ به په {seconds} ثانیو کې بیا واستول شي"},
    "verificationEmailSent": {"en": "Verification email sent. Check your inbox.", "fa": "ایمیل تأیید ارسال شد. صندوق ورودی را بررسی کنید.", "ps": "د تایید ایمیل ولېږل شو. خپل انباکس وګورئ."},
    "emailNotVerifiedYet": {"en": "Email not verified yet. Check your inbox and try again.", "fa": "ایمیل هنوز تأیید نشده. صندوق ورودی را بررسی کنید و دوباره تلاش کنید.", "ps": "ایمیل لا نه دی تایید شوی. انباکس وګورئ او بیا هڅه وکړئ."},
    "checkYourInbox": {"en": "Check your inbox", "fa": "صندوق ورودی را بررسی کنید", "ps": "خپل انباکس وګورئ"},
    "weSentVerificationLinkTo": {"en": "We sent a verification link to ", "fa": "لینک تأیید را به ", "ps": "موږ د تایید لینک "} ,
    "yourEmailFallback": {"en": "your email", "fa": "ایمیل شما", "ps": "ستاسو ایمیل"},
    "tapLinkThenContinue": {"en": ". Tap the link to verify, then come back here to continue.", "fa": " فرستادیم. روی لینک بزنید و سپس برای ادامه به اینجا برگردید.", "ps": " ته ولېږه. لینک کېکاږئ او بیا دلته د دوام لپاره راشئ."},
    "tapLinkThenContinueOnboarding": {"en": ". Tap the link to verify, then come back here to continue onboarding.", "fa": " فرستادیم. روی لینک بزنید و سپس برای ادامه ثبت‌نام به اینجا برگردید.", "ps": " ته ولېږه. لینک کېکاږئ او بیا دلته د نوم لیکنې د دوام لپاره راشئ."},
    "checkSpamTip": {"en": "Tip: check your spam or promotions folder if you do not see it.", "fa": "نکته: اگر ندیدید پوشه هرزنامه یا تبلیغات را بررسی کنید.", "ps": "لارښوونه: که نه وینئ نو سپیم یا پروموشن فولډر وګورئ."},
    "iHaveVerifiedContinue": {"en": "I have verified - continue", "fa": "تأیید کردم — ادامه", "ps": "ما تایید کړ — ادامه"},
    "resendVerificationEmail": {"en": "Resend verification email", "fa": "ارسال دوباره ایمیل تأیید", "ps": "د تایید ایمیل بیا ولېږئ"},
    "backToSignIn": {"en": "Back to sign in", "fa": "بازگشت به ورود", "ps": "بېرته ننوتلو ته"},
    "quickDemoAccess": {"en": "Quick Demo Access", "fa": "ورود آزمایشی سریع", "ps": "چټک ازمایښتي لاسرسی"},
    "demoLoginNeedsSupabase": {"en": "Supabase is required for demo login. Add SUPABASE_URL and SUPABASE_ANON_KEY.", "fa": "برای ورود آزمایشی سوپابیس لازم است.", "ps": "د ازمایښتي ننوتلو لپاره سوپابیس اړین دی."},
    "demoLoginFailed": {"en": "Demo login failed. Check demo credentials in rawana_core.", "fa": "ورود آزمایشی ناموفق بود.", "ps": "ازمایښتي ننوتل ناکام شول."},

    # Auth errors
    "authSupabaseNotConfigured": {"en": "Sign-in is not configured. Contact support.", "fa": "ورود پیکربندی نشده است. با پشتیبانی تماس بگیرید.", "ps": "ننوتل نه دي تنظیم شوي. له ملاتړ سره اړیکه ونیسئ."},
    "authInvalidCredentials": {"en": "Incorrect email or password. Please check and try again.", "fa": "ایمیل یا رمز نادرست است. دوباره تلاش کنید.", "ps": "ایمیل یا پاسورډ ناسم دی. بیا هڅه وکړئ."},
    "authEmailNotVerified": {"en": "Please verify your email before signing in.", "fa": "قبل از ورود ایمیل خود را تأیید کنید.", "ps": "مخکې له ننوتلو خپل ایمیل تایید کړئ."},
    "authEmailAlreadyExists": {"en": "This email is already registered. Try signing in instead.", "fa": "این ایمیل قبلاً ثبت شده. وارد شوید.", "ps": "دا ایمیل دمخه ثبت دی. پر ځای یې ننوزئ."},
    "authRateLimit": {"en": "Too many attempts. Please wait a minute and try again.", "fa": "تلاش‌های زیاد. یک دقیقه صبر کنید و دوباره تلاش کنید.", "ps": "ډېرې هڅې. یوه دقیقه انتظار وکړئ او بیا هڅه وکړئ."},
    "authDatabaseSignupFailed": {"en": "We could not create your account because of a server error. Please try again in a moment.", "fa": "به‌خاطر خطای سرور حساب ساخته نشد. کمی بعد دوباره تلاش کنید.", "ps": "د سرور د تېروتنې له امله حساب جوړ نه شو. لږ وروسته بیا هڅه وکړئ."},
    "authWeakPassword": {"en": "Password is too weak. Use at least 8 characters with letters and numbers.", "fa": "رمز ضعیف است. حداقل ۸ حرف با حروف و عدد استفاده کنید.", "ps": "پاسورډ کمزوری دی. لږ تر لږه ۸ توري د حروفو او شمېرو سره وکاروئ."},
    "authInvalidEmail": {"en": "Enter a valid email address.", "fa": "یک ایمیل معتبر وارد کنید.", "ps": "سم ایمیل پته وليکئ."},
    "authInvalidPhone": {"en": "Enter a valid Afghan phone number (9 digits, e.g. 70 123 4567).", "fa": "شماره افغانی معتبر وارد کنید (۹ رقم، مثلاً 70 123 4567).", "ps": "سمه افغانۍ تلیفون شمېره وليکئ (۹ عدد، لکه 70 123 4567)."},
    "authInvalidOtp": {"en": "That code is incorrect or expired. Request a new code and try again.", "fa": "کد نادرست یا منقضی است. کد جدید بگیرید.", "ps": "کوډ ناسم یا ختم شوی دی. نوی کوډ وغواړئ."},
    "authWhatsAppUnavailable": {"en": "WhatsApp sign-in is not available right now.", "fa": "ورود واتساپ فعلاً در دسترس نیست.", "ps": "د واټساپ ننوتل اوس شتون نلري."},
    "authGenericError": {"en": "Something went wrong. Please try again.", "fa": "مشکلی پیش آمد. دوباره تلاش کنید.", "ps": "ستونزه رامنځته شوه. بیا هڅه وکړئ."},

    # Profile setup
    "completeYourProfile": {"en": "Complete your profile", "fa": "پروفایل خود را تکمیل کنید", "ps": "خپل پروفایل بشپړ کړئ"},
    "almostThere": {"en": "Almost there!", "fa": "تقریباً تمام شد!", "ps": "نږدې بشپړ شو!"},
    "profileSetupSubtitle": {"en": "Add your name and phone so your driver can reach you.", "fa": "نام و تلفن را اضافه کنید تا راننده بتواند با شما تماس بگیرد.", "ps": "خپل نوم او تلیفون ولیکئ ترڅو چلوونکی درسره اړیکه ونیسي."},
    "photoUploadFailed": {"en": "Photo upload failed: {error}", "fa": "بارگذاری عکس ناموفق: {error}", "ps": "د عکس پورته کول ناکام شول: {error}"},
    "driverRegistration": {"en": "Driver registration", "fa": "ثبت‌نام راننده", "ps": "د چلوونکي نوم لیکنه"},
    "yourDetails": {"en": "Your details", "fa": "اطلاعات شما", "ps": "ستاسو معلومات"},
    "needNameAndPhoneBeforeDocs": {"en": "Passengers and support need your name and phone before you can upload documents.", "fa": "قبل از بارگذاری مدارک، نام و تلفن شما لازم است.", "ps": "مخکې له اسنادو پورته کولو نوم او تلیفون اړین دي."},
    "continueToDocuments": {"en": "Continue to documents", "fa": "ادامه به مدارک", "ps": "اسنادو ته ادامه"},

    # Passenger home / trip
    "gettingYourLocation": {"en": "Getting your location…", "fa": "موقعیت شما گرفته می‌شود…", "ps": "ستاسو موقعیت اخیستل کېږي…"},
    "gettingLocation": {"en": "Getting location…", "fa": "گرفتن موقعیت…", "ps": "موقعیت اخیستل کېږي…"},
    "currentLocation": {"en": "Current location", "fa": "موقعیت فعلی", "ps": "اوسنی موقعیت"},
    "locationUnavailable": {"en": "Location unavailable", "fa": "موقعیت در دسترس نیست", "ps": "موقعیت شتون نلري"},
    "waitingForLocation": {"en": "Waiting for your location…", "fa": "منتظر موقعیت شما…", "ps": "ستاسو موقعیت ته انتظار…"},
    "myLocation": {"en": "My location", "fa": "موقعیت من", "ps": "زما موقعیت"},
    "helloName": {"en": "Hello, {name}", "fa": "سلام، {name}", "ps": "سلام، {name}"},
    "greetingNameFallback": {"en": "there", "fa": "دوست", "ps": "ملګریه"},
    "navRide": {"en": "Ride", "fa": "سفر", "ps": "سفر"},
    "help": {"en": "Help", "fa": "راهنما", "ps": "مرسته"},
    "viewSearch": {"en": "View search", "fa": "مشاهده جستجو", "ps": "لټون وګورئ"},
    "viewRide": {"en": "View ride", "fa": "مشاهده سفر", "ps": "سفر وګورئ"},
    "searchDestination": {"en": "Search destination", "fa": "جستجوی مقصد", "ps": "منزل ولټوئ"},
    "quickHome": {"en": "Home", "fa": "خانه", "ps": "کور"},
    "quickWork": {"en": "Work", "fa": "محل کار", "ps": "کار"},
    "quickSaved": {"en": "Saved", "fa": "ذخیره‌شده", "ps": "ساتل شوي"},
    "gpsLocked": {"en": "GPS LOCKED", "fa": "جی‌پی‌اس قفل شد", "ps": "جی‌پی‌اس قفل شو"},
    "gpsAcquiring": {"en": "ACQUIRING", "fa": "در حال دریافت", "ps": "ترلاسه کېږي"},
    "gpsBlocked": {"en": "GPS BLOCKED", "fa": "جی‌پی‌اس مسدود", "ps": "جی‌پی‌اس بند دی"},
    "pickupLabel": {"en": "PICKUP", "fa": "سوار شدن", "ps": "پورته کېدل"},
    "destinationLabel": {"en": "DESTINATION", "fa": "مقصد", "ps": "منزل"},
    "currentLabel": {"en": "CURRENT", "fa": "فعلی", "ps": "اوسنی"},
    "driverOnTheWay": {"en": "Driver on the way", "fa": "راننده در راه است", "ps": "چلوونکی په لاره دی"},
    "driverIsArriving": {"en": "Driver is arriving", "fa": "راننده می‌رسد", "ps": "چلوونکی رارسیږي"},
    "onTripToDestination": {"en": "On trip to destination", "fa": "در مسیر مقصد", "ps": "منزل ته په سفر کې"},
    "rideInProgress": {"en": "Ride in progress", "fa": "سفر در جریان است", "ps": "سفر روان دی"},
    "noSavedAddressTitle": {"en": "No {label} address", "fa": "آدرس {label} وجود ندارد", "ps": "د {label} پته نشته"},
    "noSavedAddressBody": {"en": "Add a saved address labeled \"{label}\" first.", "fa": "ابتدا یک آدرس ذخیره‌شده با برچسب «{label}» اضافه کنید.", "ps": "لومړی یوه ساتل شوې پته د «{label}» نوم سره اضافه کړئ."},
    "addAddress": {"en": "Add address", "fa": "افزودن آدرس", "ps": "پته زیاته کړئ"},
    "invalidSavedAddressCoords": {"en": "Invalid saved address coordinates", "fa": "مختصات آدرس ذخیره‌شده نامعتبر است", "ps": "د ساتل شوې پتې همغږي ناسمې دي"},
    "kabulFallbackPickup": {"en": "Kabul (set exact pickup on map)", "fa": "کابل (نقطه سوار شدن را روی نقشه مشخص کنید)", "ps": "کابل (سم پورته کېدل په نقشه کې وټاکئ)"},
    "locationUnavailableEnableGps": {"en": "Location unavailable. Enable GPS or tap pickup to choose on the map.", "fa": "موقعیت در دسترس نیست. جی‌پی‌اس را روشن کنید یا سوار شدن را روی نقشه انتخاب کنید.", "ps": "موقعیت نشته. جی‌پی‌اس فعال کړئ یا په نقشه کې پورته کېدل وټاکئ."},
    "choosePickupFirst": {"en": "Choose your pickup location first", "fa": "ابتدا محل سوار شدن را انتخاب کنید", "ps": "لومړی د پورته کېدو ځای وټاکئ"},
    "choosePickupFirstShort": {"en": "Choose your pickup first", "fa": "ابتدا سوار شدن را انتخاب کنید", "ps": "لومړی پورته کېدل وټاکئ"},
    "couldNotSelectPlace": {"en": "Could not select place. Try again.", "fa": "مکان انتخاب نشد. دوباره تلاش کنید.", "ps": "ځای و نه ټاکل شو. بیا هڅه وکړئ."},
    "selectedPickup": {"en": "Selected pickup", "fa": "سوار شدن انتخاب‌شده", "ps": "ټاکل شوی پورته کېدل"},
    "selectedDestination": {"en": "Selected destination", "fa": "مقصد انتخاب‌شده", "ps": "ټاکل شوی منزل"},
    "enableLocationToBook": {"en": "Enable location to book a ride", "fa": "برای رزرو سفر موقعیت را فعال کنید", "ps": "د سفر نیولو لپاره موقعیت فعال کړئ"},
    "planYourTrip": {"en": "Plan your trip", "fa": "سفر خود را برنامه‌ریزی کنید", "ps": "خپل سفر پلان کړئ"},
    "fromLabel": {"en": "From", "fa": "از", "ps": "له"},
    "toLabel": {"en": "To", "fa": "به", "ps": "ته"},
    "popularPlaces": {"en": "POPULAR PLACES", "fa": "مکان‌های محبوب", "ps": "مشهور ځایونه"},
    "suggestions": {"en": "SUGGESTIONS", "fa": "پیشنهادها", "ps": "وړاندیزونه"},
    "editPickup": {"en": "Edit pickup", "fa": "ویرایش سوار شدن", "ps": "پورته کېدل سمول"},
    "searchPickupLocation": {"en": "Search pickup location", "fa": "جستجوی محل سوار شدن", "ps": "د پورته کېدو ځای ولټوئ"},
    "useCurrentLocation": {"en": "Use current location", "fa": "استفاده از موقعیت فعلی", "ps": "اوسنی موقعیت وکاروئ"},
    "chooseOnMap": {"en": "Choose on map", "fa": "انتخاب روی نقشه", "ps": "په نقشه کې وټاکئ"},
    "movePinToPickup": {"en": "Move the pin to your exact pickup", "fa": "پین را به محل دقیق سوار شدن ببرید", "ps": "پن د سم پورته کېدو ځای ته یوسئ"},
    "startTyping": {"en": "Start typing", "fa": "شروع به نوشتن کنید", "ps": "لیکل پیل کړئ"},
    "weWillSuggestPlaces": {"en": "We will suggest places near you", "fa": "مکان‌های نزدیک شما را پیشنهاد می‌کنیم", "ps": "موږ به نږدې ځایونه درته وړاندیز کړو"},
    "dropPinDestination": {"en": "Drop a pin exactly where you want to go", "fa": "پین را دقیقاً جایی که می‌روید بگذارید", "ps": "پن هلته کېږدئ چې تلل غواړئ"},
    "moveMapToChoose": {"en": "Move the map to choose a location", "fa": "نقشه را حرکت دهید تا مکان را انتخاب کنید", "ps": "نقشه حرکت کړئ ترڅو ځای وټاکئ"},
    "choosePickup": {"en": "Choose pickup", "fa": "انتخاب سوار شدن", "ps": "پورته کېدل وټاکئ"},
    "chooseDestination": {"en": "Choose destination", "fa": "انتخاب مقصد", "ps": "منزل وټاکئ"},
    "useThisPickup": {"en": "Use this pickup", "fa": "استفاده از این سوار شدن", "ps": "دا پورته کېدل وکاروئ"},
    "useThisDestination": {"en": "Use this destination", "fa": "استفاده از این مقصد", "ps": "دا منزل وکاروئ"},
    "tapOrDragMap": {"en": "Tap or drag the map, then confirm.", "fa": "نقشه را لمس یا بکشید، سپس تأیید کنید.", "ps": "نقشه کېکاږئ یا یې وباسئ، بیا تایید کړئ."},
    "failedToLoadRideTypes": {"en": "Failed to load ride types: {error}", "fa": "بارگذاری نوع سفر ناموفق: {error}", "ps": "د سفر ډولونه پورته نه شول: {error}"},
    "noRideTypesAvailable": {"en": "No ride types available", "fa": "نوع سفری موجود نیست", "ps": "د سفر ډول نشته"},
    "pickupConfirmed": {"en": "Pickup confirmed", "fa": "سوار شدن تأیید شد", "ps": "پورته کېدل تایید شول"},
    "pickup": {"en": "Pickup", "fa": "سوار شدن", "ps": "پورته کېدل"},
    "destination": {"en": "Destination", "fa": "مقصد", "ps": "منزل"},
    "dropoff": {"en": "Drop-off", "fa": "پیاده شدن", "ps": "کوزېدل"},
    "chooseYourRide": {"en": "Choose your ride", "fa": "سفر خود را انتخاب کنید", "ps": "خپل سفر وټاکئ"},
    "etaMinToDestination": {"en": "~{minutes} min to destination", "fa": "حدود {minutes} دقیقه تا مقصد", "ps": "تر منزل شاوخوا {minutes} دقیقې"},
    "payment": {"en": "Payment", "fa": "پرداخت", "ps": "تادیه"},
    "cashAfn": {"en": "Cash · AFN", "fa": "نقدی · افغانی", "ps": "نغدي · افغانۍ"},
    "paymentMethodConfirmed": {"en": "Payment method confirmed", "fa": "روش پرداخت تأیید شد", "ps": "د تادیې طریقه تایید شوه"},
    "tapToConfirmPayment": {"en": "Tap to confirm payment at trip end", "fa": "برای تأیید پرداخت در پایان سفر بزنید", "ps": "د سفر په پای کې د تادیې لپاره کېکاږئ"},
    "requestRideWithFare": {"en": "Request {name} · {fare}", "fa": "درخواست {name} · {fare}", "ps": "{name} وغواړئ · {fare}"},
    "confirmPaymentToContinue": {"en": "Confirm payment to continue", "fa": "برای ادامه پرداخت را تأیید کنید", "ps": "د دوام لپاره تادیه تایید کړئ"},
    "missingTripDetails": {"en": "Missing trip details", "fa": "جزئیات سفر ناقص است", "ps": "د سفر تفصیل نشتې"},
    "noDriversAvailable": {"en": "No drivers available right now. Please try again.", "fa": "الان راننده‌ای موجود نیست. دوباره تلاش کنید.", "ps": "اوس چلوونکی نشته. بیا هڅه وکړئ."},
    "connectingToNearbyDrivers": {"en": "Connecting you to nearby drivers — usually under a minute.", "fa": "شما را به رانندگان نزدیک وصل می‌کنیم — معمولاً کمتر از یک دقیقه.", "ps": "تاسو نږدې چلوونکو سره نښلوو — معمولاً په یوه دقیقه کې."},
    "retryOrCancelBelow": {"en": "You can retry or cancel below.", "fa": "می‌توانید پایین دوباره تلاش کنید یا لغو کنید.", "ps": "لاندې بیا هڅه یا لغوه کولی شئ."},
    "cancelRequest": {"en": "Cancel request", "fa": "لغو درخواست", "ps": "غوښتنه لغوه کړئ"},
    "followingLiveRouteHint": {"en": "Following live route. Tap ↓ to return to trip details.", "fa": "مسیر زنده دنبال می‌شود. برای بازگشت به جزئیات ↓ را بزنید.", "ps": "ژوندۍ لاره تعقیبېږي. د تفصیل لپاره ↓ کېکاږئ."},
    "couldNotOpenWhatsAppCall": {"en": "Could not open WhatsApp call", "fa": "تماس واتساپ باز نشد", "ps": "د واټساپ زنګ پرانیستل نه شو"},
    "couldNotOpenWhatsAppMessages": {"en": "Could not open WhatsApp messages", "fa": "پیام واتساپ باز نشد", "ps": "د واټساپ پیغامونه پرانیستل نه شول"},
    "cancelThisRide": {"en": "Cancel this ride?", "fa": "این سفر لغو شود؟", "ps": "دا سفر لغوه شي؟"},
    "cancelRideWarning": {"en": "Your driver will be notified. Repeated cancellations may incur a fee.", "fa": "راننده مطلع می‌شود. لغو مکرر ممکن است هزینه داشته باشد.", "ps": "چلوونکی به خبر شي. پرله‌پسې لغوه کېدای شي فیس ولري."},
    "keepRide": {"en": "Keep ride", "fa": "سفر بماند", "ps": "سفر وساتئ"},
    "shareTripIntro": {"en": "I'm on a Rawana trip.", "fa": "من در سفر روانا هستم.", "ps": "زه د روانا په سفر کې یم."},
    "shareDriver": {"en": "Driver: {name}", "fa": "راننده: {name}", "ps": "چلوونکی: {name}"},
    "shareVehicle": {"en": "Vehicle: {vehicle}", "fa": "موتر: {vehicle}", "ps": "موټر: {vehicle}"},
    "sharePlate": {"en": "Plate: {plate}", "fa": "نمبر پلیت: {plate}", "ps": "پلیټ: {plate}"},
    "shareFrom": {"en": "From: {address}", "fa": "از: {address}", "ps": "له: {address}"},
    "shareTo": {"en": "To: {address}", "fa": "به: {address}", "ps": "ته: {address}"},
    "shareCurrentLocation": {"en": "Current location: {url}", "fa": "موقعیت فعلی: {url}", "ps": "اوسنی موقعیت: {url}"},
    "shareTripSubject": {"en": "My Rawana trip", "fa": "سفر روانا من", "ps": "زما د روانا سفر"},
    "driverConfirmedHeadingPickup": {"en": "Driver confirmed — heading to pickup", "fa": "راننده تأیید کرد — به سمت سوار شدن", "ps": "چلوونکی تایید شو — پورته کېدو ته روان دی"},
    "driverIsAtPickup": {"en": "Driver is at your pickup", "fa": "راننده در محل سوار شدن است", "ps": "چلوونکی ستاسو د پورته کېدو په ځای دی"},
    "backToHome": {"en": "Back to home", "fa": "بازگشت به خانه", "ps": "کور ته شاته"},
    "you": {"en": "You", "fa": "شما", "ps": "تاسو"},
    "yourDriver": {"en": "Your driver", "fa": "راننده شما", "ps": "ستاسو چلوونکی"},
    "followingYourTrip": {"en": "Following your trip", "fa": "دنبال کردن سفر شما", "ps": "ستاسو سفر تعقیبېږي"},
    "driverEnRouteToPickup": {"en": "Driver en route to pickup", "fa": "راننده در مسیر سوار شدن", "ps": "چلوونکی پورته کېدو ته په لاره دی"},
    "safety": {"en": "Safety", "fa": "ایمنی", "ps": "خوندیتوب"},
    "driverLiveLocation": {"en": "Driver live location", "fa": "موقعیت زنده راننده", "ps": "د چلوونکي ژوندی موقعیت"},
    "yourPickupSpot": {"en": "Your pickup spot", "fa": "محل سوار شدن شما", "ps": "ستاسو د پورته کېدو ځای"},
    "hintFollowLiveRoute": {"en": "Route line updates as your driver moves. Tap Start navigation to follow live.", "fa": "خط مسیر با حرکت راننده به‌روز می‌شود. برای دنبال کردن زنده، شروع ناوبری را بزنید.", "ps": "لاره د چلوونکي په خوځښت تازه کېږي. د ژوندي تعقیب لپاره نیویګیشن پیل کړئ."},
    "hintWatchDriverApproach": {"en": "Watch your driver approach on the map. ETA updates automatically.", "fa": "نزدیک شدن راننده را روی نقشه ببینید. زمان تقریبی خودکار به‌روز می‌شود.", "ps": "خپل چلوونکی په نقشه کې وګورئ. اټکل وخت په خپل سر تازه کېږي."},
    "followTripRoute": {"en": "Follow trip route", "fa": "دنبال کردن مسیر سفر", "ps": "د سفر لاره تعقیب کړئ"},
    "followDriverToPickup": {"en": "Follow driver to pickup", "fa": "دنبال کردن راننده تا سوار شدن", "ps": "چلوونکی تر پورته کېدو تعقیب کړئ"},
    "call": {"en": "Call", "fa": "تماس", "ps": "زنګ"},
    "message": {"en": "Message", "fa": "پیام", "ps": "پیغام"},
    "shareTrip": {"en": "Share trip", "fa": "اشتراک سفر", "ps": "سفر شریک کړئ"},
    "driverArrivedNotice": {"en": "Your driver is at your pickup location.", "fa": "راننده شما در محل سوار شدن است.", "ps": "ستاسو چلوونکی د پورته کېدو په ځای دی."},
    "youHaveArrived": {"en": "You have arrived", "fa": "رسیدید", "ps": "تاسو ورسېدلئ"},
    "thanksForRiding": {"en": "Thank you for riding with Rawana.", "fa": "از سفر با روانا سپاسگزاریم.", "ps": "د روانا سره د سفر لپاره مننه."},
    "payYourDriver": {"en": "PAY YOUR DRIVER", "fa": "به راننده بپردازید", "ps": "خپل چلوونکي ته ورکړئ"},
    "howWasYourTrip": {"en": "How was your trip?", "fa": "سفر چطور بود؟", "ps": "سفر څنګه و؟"},
    "feedbackHelpsDrivers": {"en": "Your feedback helps drivers improve.", "fa": "بازخورد شما به رانندگان کمک می‌کند بهتر شوند.", "ps": "ستاسو نظر چلوونکو ته د ښه کېدو مرسته کوي."},
    "ratingTagCleanCar": {"en": "Clean car", "fa": "موتر تمیز", "ps": "پاک موټر"},
    "ratingTagSafeDriving": {"en": "Safe driving", "fa": "رانندگی ایمن", "ps": "خوندي چلول"},
    "ratingTagFriendlyDriver": {"en": "Friendly driver", "fa": "راننده مؤدب", "ps": "مهربان چلوونکی"},
    "ratingTagOnTime": {"en": "On time", "fa": "به‌موقع", "ps": "پر وخت"},
    "ratingTagGoodNavigation": {"en": "Good navigation", "fa": "مسیریابی خوب", "ps": "ښه لارښوونه"},
    "submitRating": {"en": "Submit rating", "fa": "ارسال امتیاز", "ps": "درجه ولېږئ"},
    "skipRating": {"en": "Skip rating", "fa": "رد کردن امتیاز", "ps": "درجه پرېږدئ"},
    "reportAnIssue": {"en": "Report an issue", "fa": "گزارش مشکل", "ps": "ستونزه راپور کړئ"},
    "ratingFailed": {"en": "Rating failed: {error}", "fa": "امتیازدهی ناموفق: {error}", "ps": "درجه بندي ناکامه شوه: {error}"},
    "tripTitleWithId": {"en": "Trip · {id}", "fa": "سفر · {id}", "ps": "سفر · {id}"},
    "tripSummary": {"en": "Trip summary", "fa": "خلاصه سفر", "ps": "د سفر لنډیز"},
    "totalFare": {"en": "Total fare", "fa": "کرایه کل", "ps": "ټول کرایه"},
    "driverLabel": {"en": "DRIVER", "fa": "راننده", "ps": "چلوونکی"},
    "whatsAppDriver": {"en": "WhatsApp driver", "fa": "واتساپ راننده", "ps": "چلوونکي ته واټساپ"},
    "whatsAppCallDriver": {"en": "WhatsApp call driver", "fa": "تماس واتساپ با راننده", "ps": "چلوونکي ته د واټساپ زنګ"},
    "rideHistory": {"en": "Ride history", "fa": "تاریخچه سفرها", "ps": "د سفرونو تاریخچه"},
    "failedToLoadHistory": {"en": "Failed to load history: {error}", "fa": "بارگذاری تاریخچه ناموفق: {error}", "ps": "تاریخچه پورته نه شوه: {error}"},
    "noTripsYet": {"en": "No trips yet", "fa": "هنوز سفری نیست", "ps": "تر اوسه سفر نشته"},
    "pastRidesHint": {"en": "Your past rides will appear here.", "fa": "سفرهای گذشته اینجا ظاهر می‌شوند.", "ps": "ستاسو پخواني سفرونه به دلته ښکاره شي."},
    "fromAddress": {"en": "From {address}", "fa": "از {address}", "ps": "له {address}"},

    # Trip status
    "statusSearching": {"en": "Searching", "fa": "در حال جستجو", "ps": "لټون"},
    "statusAccepted": {"en": "Accepted", "fa": "پذیرفته شد", "ps": "ومنل شو"},
    "statusDriverArriving": {"en": "Driver arriving", "fa": "راننده در راه", "ps": "چلوونکی رارسیږي"},
    "statusTripStarted": {"en": "Trip started", "fa": "سفر شروع شد", "ps": "سفر پیل شو"},
    "statusCompleted": {"en": "Completed", "fa": "تکمیل شد", "ps": "بشپړ شو"},
    "statusCancelled": {"en": "Cancelled", "fa": "لغو شد", "ps": "لغوه شو"},
    "completed": {"en": "Completed", "fa": "تکمیل‌شده", "ps": "بشپړ"},

    # Passenger account
    "account": {"en": "Account", "fa": "حساب", "ps": "حساب"},
    "failedToLoadProfile": {"en": "Failed to load profile: {error}", "fa": "بارگذاری پروفایل ناموفق: {error}", "ps": "پروفایل پورته نه شو: {error}"},
    "passengerFallbackName": {"en": "Passenger", "fa": "مسافر", "ps": "مسافر"},
    "tripsStat": {"en": "Trips", "fa": "سفرها", "ps": "سفرونه"},
    "ratingStat": {"en": "Rating", "fa": "امتیاز", "ps": "درجه"},
    "memberStat": {"en": "Member", "fa": "عضو", "ps": "غړی"},
    "memberNew": {"en": "New", "fa": "جدید", "ps": "نوی"},
    "preferences": {"en": "Preferences", "fa": "ترجیحات", "ps": "غوره توبونه"},
    "savedAddresses": {"en": "Saved addresses", "fa": "آدرس‌های ذخیره‌شده", "ps": "ساتل شوې پتې"},
    "notifications": {"en": "Notifications", "fa": "اعلان‌ها", "ps": "خبرتیاوې"},
    "safetyAndSupport": {"en": "Safety & Support", "fa": "ایمنی و پشتیبانی", "ps": "خوندیتوب او ملاتړ"},
    "emergencyContacts": {"en": "Emergency contacts", "fa": "مخاطبین اضطراری", "ps": "د بیړني اړیکې"},
    "helpCentre": {"en": "Help centre", "fa": "مرکز راهنما", "ps": "د مرستې مرکز"},
    "enableLocationToSaveAddress": {"en": "Enable location to save this address", "fa": "برای ذخیره این آدرس موقعیت را فعال کنید", "ps": "د دې پتې ساتلو لپاره موقعیت فعال کړئ"},
    "saveANewAddress": {"en": "Save a new address", "fa": "ذخیره آدرس جدید", "ps": "نوې پته وساتئ"},
    "usesCurrentGps": {"en": "Uses your current GPS location for coordinates.", "fa": "از موقعیت فعلی جی‌پی‌اس برای مختصات استفاده می‌کند.", "ps": "د همغږۍ لپاره ستاسو اوسنی جی‌پی‌اس کاروي."},
    "addressLabel": {"en": "Label", "fa": "برچسب", "ps": "نوم"},
    "addressLabelHint": {"en": "Home, Work, Gym…", "fa": "خانه، کار، ورزشگاه…", "ps": "کور، کار، جم…"},
    "addressField": {"en": "Address", "fa": "آدرس", "ps": "پته"},
    "saveAddress": {"en": "Save address", "fa": "ذخیره آدرس", "ps": "پته وساتئ"},
    "failedToLoadAddresses": {"en": "Failed to load addresses: {error}", "fa": "بارگذاری آدرس‌ها ناموفق: {error}", "ps": "پتې پورته نه شوې: {error}"},
    "noSavedAddresses": {"en": "No saved addresses", "fa": "آدرس ذخیره‌شده‌ای نیست", "ps": "ساتل شوې پته نشته"},
    "savedAddressesEmptyHint": {"en": "Save Home, Work and other places\nfor one-tap booking.", "fa": "خانه، کار و مکان‌های دیگر را ذخیره کنید\nتا با یک ضربه رزرو کنید.", "ps": "کور، کار او نور ځایونه وساتئ\nترڅو په یوه ټپ سفر ونیسئ."},
    "noNotificationsYet": {"en": "No notifications yet", "fa": "هنوز اعلانی نیست", "ps": "تر اوسه خبرتیا نشته"},
    "notificationsEmptyHint": {"en": "Trip updates and promotions will appear here\nwhen push notifications are enabled.", "fa": "به‌روزرسانی سفر و پیشنهادها اینجا ظاهر می‌شوند\nوقتی اعلان‌ها فعال باشند.", "ps": "د سفر تازه معلومات او وړاندیزونه به دلته ښکاره شي\nکله چې خبرتیاوې فعالې وي."},
    "needAHand": {"en": "Need a hand?", "fa": "کمک می‌خواهید؟", "ps": "مرستې ته اړتیا لرئ؟"},
    "helpTeam247": {"en": "Our team is here to help, 24/7.", "fa": "تیم ما شبانه‌روز آماده کمک است.", "ps": "زموږ ډله شپه او ورځ د مرستې لپاره ده."},
    "commonQuestions": {"en": "Common questions", "fa": "سؤالات رایج", "ps": "عامې پوښتنې"},
    "faqBookTitle": {"en": "How do I book a ride?", "fa": "چگونه سفر رزرو کنم؟", "ps": "سفر څنګه ونیسم؟"},
    "faqBookBody": {"en": "Open the app, tap \"Where to?\", set your destination, choose a ride type, and confirm. Your nearest driver will be on the way.", "fa": "برنامه را باز کنید، «کجا می‌روید؟» را بزنید، مقصد را مشخص کنید، نوع سفر را انتخاب و تأیید کنید. نزدیک‌ترین راننده در راه خواهد بود.", "ps": "اپ خلاص کړئ، «چیرته ځئ؟» کېکاږئ، منزل وټاکئ، ډول وټاکئ او تایید کړئ. نږدې چلوونکی به په لاره وي."},
    "faqPayTitle": {"en": "How do I pay?", "fa": "چگونه پرداخت کنم؟", "ps": "څنګه ورکړم؟"},
    "faqPayBody": {"en": "Pay the driver in Afghan Afghani (AFN) cash at the end of your trip.", "fa": "در پایان سفر به افغانی نقد به راننده بپردازید.", "ps": "د سفر په پای کې چلوونکي ته په افغانۍ نغدي ورکړئ."},
    "reportSafetyOrTripIssue": {"en": "Report a safety or trip issue", "fa": "گزارش مشکل ایمنی یا سفر", "ps": "د خوندیتوب یا سفر ستونزه راپور کړئ"},
    "addEmergencyContact": {"en": "Add emergency contact", "fa": "افزودن مخاطب اضطراری", "ps": "بیړنۍ اړیکه زیاته کړئ"},
    "name": {"en": "Name", "fa": "نام", "ps": "نوم"},
    "phone": {"en": "Phone", "fa": "تلفن", "ps": "تلیفون"},
    "saveContact": {"en": "Save contact", "fa": "ذخیره مخاطب", "ps": "اړیکه وساتئ"},
    "failedToLoadContacts": {"en": "Failed to load contacts: {error}", "fa": "بارگذاری مخاطبین ناموفق: {error}", "ps": "اړیکې پورته نه شوې: {error}"},
    "noContactsYet": {"en": "No contacts yet", "fa": "هنوز مخاطبی نیست", "ps": "تر اوسه اړیکه نشته"},
    "emergencyContactsEmptyHint": {"en": "Add up to 3 trusted contacts.\nThey will be notified during emergencies.", "fa": "تا ۳ مخاطب مورد اعتماد اضافه کنید.\nدر مواقع اضطراری مطلع می‌شوند.", "ps": "تر ۳ باوري اړیکو پورې زیاتې کړئ.\nپه بیړني حالاتو کې به خبر شي."},

    # Shared trip widgets
    "navigate": {"en": "Navigate", "fa": "مسیریابی", "ps": "لارښوونه"},
    "estimatedFare": {"en": "Estimated fare", "fa": "کرایه تقریبی", "ps": "اټکل شوی کرایه"},
    "minutesShort": {"en": "min", "fa": "دقیقه", "ps": "دقیقې"},
    "secondsShort": {"en": "sec", "fa": "ثانیه", "ps": "ثانیې"},
    "distanceKm": {"en": "{km} km", "fa": "{km} کیلومتر", "ps": "{km} کیلومتره"},
    "distanceMeters": {"en": "{meters} m", "fa": "{meters} متر", "ps": "{meters} متره"},
    "etaMinutes": {"en": "{minutes} min", "fa": "{minutes} دقیقه", "ps": "{minutes} دقیقې"},
    "routeDistance": {"en": "route distance", "fa": "فاصله مسیر", "ps": "د لارې واټن"},
    "whatsApp": {"en": "WhatsApp", "fa": "واتساپ", "ps": "واټساپ"},
    "endNavigation": {"en": "End navigation", "fa": "پایان ناوبری", "ps": "نیویګیشن پای"},
    "navigating": {"en": "Navigating", "fa": "در حال مسیریابی", "ps": "لارښوونه کېږي"},
    "followingSelectedRoute": {"en": "Following selected route", "fa": "دنبال کردن مسیر انتخاب‌شده", "ps": "ټاکل شوې لاره تعقیبېږي"},
    "routes": {"en": "Routes", "fa": "مسیرها", "ps": "لارې"},
    "routeShortest": {"en": "Shortest", "fa": "کوتاه‌ترین", "ps": "لنډه"},
    "routeFastest": {"en": "Fastest", "fa": "سریع‌ترین", "ps": "چټکه"},
    "routeChipDurationDistance": {"en": "{minutes}m · {km}km", "fa": "{minutes}د · {km}کم", "ps": "{minutes}د · {km}کم"},
    "nearbyDriver": {"en": "Nearby driver", "fa": "راننده نزدیک", "ps": "نږدې چلوونکی"},
    "driver": {"en": "Driver", "fa": "راننده", "ps": "چلوونکی"},
    "passenger": {"en": "Passenger", "fa": "مسافر", "ps": "مسافر"},
    "activeRide": {"en": "Active ride", "fa": "سفر فعال", "ps": "فعال سفر"},
    "continueOnHighlightedRoute": {"en": "Continue on the highlighted route", "fa": "در مسیر مشخص‌شده ادامه دهید", "ps": "په په نښه شوې لاره ادامه ورکړئ"},
    "startNavigation": {"en": "Start navigation", "fa": "شروع ناوبری", "ps": "نیویګیشن پیل کړئ"},

    # Support / report
    "issueWithTrip": {"en": "Issue with trip #{id}", "fa": "مشکل در سفر #{id}", "ps": "د سفر ستونزه #{id}"},
    "reportValidation": {"en": "Please add a subject and at least 10 characters of detail.", "fa": "موضوع و حداقل ۱۰ حرف توضیح وارد کنید.", "ps": "موضوع او لږ تر لږه ۱۰ توري تفصیل ولیکئ."},
    "reportSubmitted": {"en": "Report submitted. Our team will follow up.", "fa": "گزارش ارسال شد. تیم ما پیگیری می‌کند.", "ps": "راپور ولېږل شو. زموږ ډله به تعقیب کړي."},
    "failedToSubmit": {"en": "Failed to submit: {error}", "fa": "ارسال ناموفق: {error}", "ps": "لېږل ناکام شول: {error}"},
    "tripShortId": {"en": "Trip {id}", "fa": "سفر {id}", "ps": "سفر {id}"},
    "category": {"en": "Category", "fa": "دسته‌بندی", "ps": "کټګوري"},
    "subject": {"en": "Subject", "fa": "موضوع", "ps": "موضوع"},
    "whatHappened": {"en": "What happened?", "fa": "چه اتفاقی افتاد؟", "ps": "څه وشول؟"},
    "safetyReportPriority": {"en": "Safety reports are prioritised. If you are in immediate danger, contact local emergency services.", "fa": "گزارش‌های ایمنی در اولویت هستند. اگر در خطر فوری هستید با خدمات اضطراری محلی تماس بگیرید.", "ps": "د خوندیتوب راپورونه لومړیتوب لري. که په سمدستي خطر کې یاست له سیمه‌ییزو بیړنیو خدماتو سره اړیکه ونیسئ."},
    "submitReport": {"en": "Submit report", "fa": "ارسال گزارش", "ps": "راپور ولېږئ"},
    "supportBilling": {"en": "Billing / overcharge", "fa": "صورت‌حساب / اضافه دریافت", "ps": "بل / زیات اخیستل"},
    "supportDriverBehaviour": {"en": "Driver behaviour", "fa": "رفتار راننده", "ps": "د چلوونکي چلند"},
    "supportSafetyConcern": {"en": "Safety concern", "fa": "نگرانی ایمنی", "ps": "د خوندیتوب اندیښنه"},
    "supportTechnical": {"en": "App / technical issue", "fa": "مشکل برنامه / فنی", "ps": "د اپ / تخنیکي ستونزه"},
    "supportOther": {"en": "Other", "fa": "سایر", "ps": "نور"},
    "supportFarePayment": {"en": "Fare / payment issue", "fa": "مشکل کرایه / پرداخت", "ps": "د کرایې / تادیې ستونزه"},
    "supportPassengerBehaviour": {"en": "Passenger behaviour", "fa": "رفتار مسافر", "ps": "د مسافر چلند"},

    # Driver onboarding / documents
    "docDriverLicence": {"en": "Driver Licence", "fa": "جواز رانندگی", "ps": "د چلولو جواز"},
    "docVehicleRegistration": {"en": "Vehicle Registration", "fa": "ثبت موتر", "ps": "د موټر ثبت"},
    "docNationalId": {"en": "National ID", "fa": "تذکره", "ps": "تذکره"},
    "docProfilePhoto": {"en": "Profile Photo", "fa": "عکس پروفایل", "ps": "د پروفایل انځور"},
    "docVehicleInfo": {"en": "Vehicle Info", "fa": "اطلاعات موتر", "ps": "د موټر معلومات"},
    "supabaseRequiredForUpload": {"en": "Supabase required for document upload", "fa": "برای بارگذاری مدرک سوپابیس لازم است", "ps": "د سند پورته کولو لپاره سوپابیس اړین دی"},
    "documentUploaded": {"en": "Document uploaded", "fa": "مدرک بارگذاری شد", "ps": "سند پورته شو"},
    "uploadFailed": {"en": "Upload failed: {error}", "fa": "بارگذاری ناموفق: {error}", "ps": "پورته کول ناکام شول: {error}"},
    "pleaseUploadAllDocuments": {"en": "Please upload all required documents", "fa": "همه مدارک لازم را بارگذاری کنید", "ps": "ټول اړین اسناد پورته کړئ"},
    "enterVehicleMakeModelPlate": {"en": "Enter vehicle make, model, and plate number", "fa": "نوع، مدل و نمبر پلیت موتر را وارد کنید", "ps": "د موټر جوړونکی، ماډل او پلیټ ولیکئ"},
    "pleaseUploadDocumentFirst": {"en": "Please upload the document first", "fa": "ابتدا مدرک را بارگذاری کنید", "ps": "لومړی سند پورته کړئ"},
    "stepOfTotal": {"en": "Step {current} of {total}", "fa": "مرحله {current} از {total}", "ps": "پړاو {current} له {total}"},
    "takeClearPhotoOf": {"en": "Take a clear, well-lit photo of your {document}.", "fa": "از {document} خود یک عکس واضح و روشن بگیرید.", "ps": "د خپل {document} یو روښانه او څرګند انځور واخلئ."},
    "tellUsAboutVehicle": {"en": "Tell us about the vehicle you will drive.", "fa": "درباره موتری که می‌رانید بگویید.", "ps": "د هغه موټر په اړه ووایاست چې چلوئ یې."},
    "submitForReview": {"en": "Submit for review", "fa": "ارسال برای بررسی", "ps": "د کتنې لپاره ولېږئ"},
    "captureDocument": {"en": "Capture document", "fa": "گرفتن مدرک", "ps": "سند واخلئ"},
    "looksGoodCanRetake": {"en": "Looks good - you can retake if needed.", "fa": "خوب است — در صورت نیاز دوباره بگیرید.", "ps": "ښه ښکاري — که اړتیا وي بیا یې واخلئ."},
    "jpgPngKeptPrivate": {"en": "JPG or PNG, kept private and secure.", "fa": "JPG یا PNG، خصوصی و امن نگهداری می‌شود.", "ps": "JPG یا PNG، پټ او خوندي ساتل کېږي."},
    "retakePhoto": {"en": "Retake photo", "fa": "گرفتن دوباره عکس", "ps": "انځور بیا واخلئ"},
    "takePhoto": {"en": "Take photo", "fa": "گرفتن عکس", "ps": "انځور واخلئ"},
    "vehicleMakeExample": {"en": "Vehicle make (e.g. Toyota)", "fa": "نوع موتر (مثلاً تویوتا)", "ps": "د موټر جوړونکی (لکه ټویوټا)"},
    "vehicleModelExample": {"en": "Model (e.g. Corolla)", "fa": "مدل (مثلاً کرولا)", "ps": "ماډل (لکه کورولا)"},
    "plateNumber": {"en": "Plate number", "fa": "نمبر پلیت", "ps": "د پلیټ شمېره"},
    "couldNotCheckStatus": {"en": "Could not check status", "fa": "وضعیت بررسی نشد", "ps": "حالت و نه کتل شو"},
    "applicationNotApproved": {"en": "Application not approved", "fa": "درخواست تأیید نشد", "ps": "غوښتنه ونه منل شوه"},
    "applicationUnderReview": {"en": "Application under review", "fa": "درخواست در حال بررسی", "ps": "غوښتنه تر کتنې لاندې ده"},
    "documentsCouldNotBeVerified": {"en": "Your documents could not be verified. Please review and resubmit.", "fa": "مدارک شما تأیید نشد. بررسی و دوباره ارسال کنید.", "ps": "ستاسو اسناد تایید نه شول. وګورئ او بیا یې ولېږئ."},
    "verifyingDocuments24to48": {"en": "We are verifying your documents. This usually takes 24–48 hours. You will be notified once your account is approved.", "fa": "مدارک شما بررسی می‌شود. معمولاً ۲۴ تا ۴۸ ساعت طول می‌کشد. پس از تأیید مطلع می‌شوید.", "ps": "ستاسو اسناد چک کېږي. معمولاً ۲۴–۴۸ ساعتونه وخت نیسي. کله چې حساب تایید شي خبر به شئ."},
    "documentsSubmitted": {"en": "Documents submitted", "fa": "مدارک ارسال شد", "ps": "اسناد ولېږل شول"},
    "reviewFailedResubmit": {"en": "Review failed — resubmit required", "fa": "بررسی ناموفق — ارسال دوباره لازم است", "ps": "کتنه ناکامه — بیا لېږل اړین دي"},
    "backgroundVehicleVerification": {"en": "Background & vehicle verification", "fa": "بررسی سابقه و موتر", "ps": "د شالید او موټر تایید"},
    "welcomeOnboard": {"en": "Welcome onboard", "fa": "به جمع ما خوش آمدید", "ps": "ښه راغلاست"},
    "resubmitDocuments": {"en": "Resubmit documents", "fa": "ارسال دوباره مدارک", "ps": "اسناد بیا ولېږئ"},
    "refreshStatus": {"en": "Refresh status", "fa": "تازه‌سازی وضعیت", "ps": "حالت تازه کړئ"},

    # Driver dashboard / trip
    "mustBeApprovedToGoOnline": {"en": "Your account must be approved before going online", "fa": "قبل از آنلاین شدن حساب باید تأیید شود", "ps": "مخکې له آنلاین کېدو باید حساب تایید شي"},
    "enableLocationToGoOnline": {"en": "Enable location to go online and receive ride requests.", "fa": "برای آنلاین شدن و دریافت درخواست موقعیت را فعال کنید.", "ps": "د آنلاین کېدو او د سفر غوښتنو لپاره موقعیت فعال کړئ."},
    "couldNotGoOnline": {"en": "Could not go online. Check approval and connection.", "fa": "آنلاین نشدید. تأیید و اتصال را بررسی کنید.", "ps": "آنلاین نه شوئ. تایید او اتصال وګورئ."},
    "rideCancelled": {"en": "Ride cancelled", "fa": "سفر لغو شد", "ps": "سفر لغوه شو"},
    "headToPickup": {"en": "Head to pickup", "fa": "به محل سوار شدن بروید", "ps": "پورته کېدو ته لاړ شئ"},
    "navigateToPickup": {"en": "Navigate to pickup", "fa": "مسیریابی تا سوار شدن", "ps": "پورته کېدو ته لارښوونه"},
    "atPickup": {"en": "At pickup", "fa": "در محل سوار شدن", "ps": "په پورته کېدو کې"},
    "continuePickup": {"en": "Continue pickup", "fa": "ادامه سوار شدن", "ps": "پورته کېدو ته ادامه"},
    "tripInProgress": {"en": "Trip in progress", "fa": "سفر در جریان", "ps": "سفر روان دی"},
    "continueTrip": {"en": "Continue trip", "fa": "ادامه سفر", "ps": "سفر ته ادامه"},
    "activeTrip": {"en": "Active trip", "fa": "سفر فعال", "ps": "فعال سفر"},
    "viewTrip": {"en": "View trip", "fa": "مشاهده سفر", "ps": "سفر وګورئ"},
    "verifiedDriver": {"en": "Verified driver", "fa": "راننده تأییدشده", "ps": "تایید شوی چلوونکی"},
    "youAreOffline": {"en": "You are offline", "fa": "آفلاین هستید", "ps": "تاسو آفلاین یاست"},
    "youAreOnline": {"en": "You are online", "fa": "آنلاین هستید", "ps": "تاسو آنلاین یاست"},
    "switchOnlineToReceiveRides": {"en": "Switch online to start receiving rides", "fa": "برای دریافت سفر آنلاین شوید", "ps": "د سفرونو ترلاسه کولو لپاره آنلاین شئ"},
    "todaysEarnings": {"en": "Today's earnings", "fa": "درآمد امروز", "ps": "د نن عاید"},
    "lastSession": {"en": "Last session", "fa": "آخرین نشست", "ps": "تېره ناسته"},
    "trips": {"en": "Trips", "fa": "سفرها", "ps": "سفرونه"},
    "gross": {"en": "Gross", "fa": "ناخالص", "ps": "ټول"},
    "rating": {"en": "Rating", "fa": "امتیاز", "ps": "درجه"},
    "receivingRides": {"en": "Receiving rides", "fa": "در حال دریافت سفر", "ps": "سفرونه ترلاسه کېږي"},
    "tapToStart": {"en": "Tap to start", "fa": "برای شروع بزنید", "ps": "د پیل لپاره کېکاږئ"},
    "acceptFailed": {"en": "Accept failed: {error}", "fa": "قبول ناموفق: {error}", "ps": "منل ناکام شول: {error}"},
    "newRideRequest": {"en": "New ride request", "fa": "درخواست سفر جدید", "ps": "د نوي سفر غوښتنه"},
    "respondNowTimeRunningOut": {"en": "Respond now — time is running out", "fa": "الان پاسخ دهید — وقت کم است", "ps": "اوس ځواب ورکړئ — وخت ختمېږي"},
    "reviewRouteAndAccept": {"en": "Review route and accept quickly", "fa": "مسیر را ببینید و سریع قبول کنید", "ps": "لاره وګورئ او ژر یې ومنئ"},
    "acceptRide": {"en": "Accept ride", "fa": "قبول سفر", "ps": "سفر ومنئ"},
    "minEta": {"en": "min ETA", "fa": "دقیقه تقریبی", "ps": "اټکل دقیقې"},
    "distance": {"en": "distance", "fa": "فاصله", "ps": "واټن"},
    "passengerWillBeNotifiedTripEnds": {"en": "The passenger will be notified and the trip will end.", "fa": "مسافر مطلع می‌شود و سفر پایان می‌یابد.", "ps": "مسافر به خبر شي او سفر به پای ته ورسي."},
    "rideCancelledFee": {"en": "Ride cancelled. Fee: {amount}", "fa": "سفر لغو شد. هزینه: {amount}", "ps": "سفر لغوه شو. فیس: {amount}"},
    "cancelFailed": {"en": "Cancel failed: {error}", "fa": "لغو ناموفق: {error}", "ps": "لغوه ناکامه شوه: {error}"},
    "backToDashboard": {"en": "Back to dashboard", "fa": "بازگشت به داشبورد", "ps": "ډشبورډ ته شاته"},
    "namePickup": {"en": "{name} pickup", "fa": "سوار شدن {name}", "ps": "د {name} پورته کېدل"},
    "passengerPickup": {"en": "Passenger pickup", "fa": "سوار کردن مسافر", "ps": "د مسافر پورته کېدل"},
    "whatsAppPassenger": {"en": "WhatsApp passenger", "fa": "واتساپ مسافر", "ps": "مسافر ته واټساپ"},
    "whatsAppCallPassenger": {"en": "WhatsApp call passenger", "fa": "تماس واتساپ با مسافر", "ps": "مسافر ته د واټساپ زنګ"},
    "headingToPickup": {"en": "Heading to pickup", "fa": "به سمت سوار شدن", "ps": "پورته کېدو ته روان"},
    "waitingAtPickupMarker": {"en": "Waiting at the pickup marker", "fa": "منتظر در نشانه سوار شدن", "ps": "د پورته کېدو په نښه کې انتظار"},
    "passengerPickupLocation": {"en": "Passenger pickup location", "fa": "محل سوار شدن مسافر", "ps": "د مسافر د پورته کېدو ځای"},
    "inAppNavigationStarted": {"en": "In-app navigation started.", "fa": "ناوبری داخل برنامه شروع شد.", "ps": "په اپ کې نیویګیشن پیل شو."},
    "iveArrivedAtPickup": {"en": "I've arrived at pickup", "fa": "به محل سوار شدن رسیدم", "ps": "پورته کېدو ته ورسېدم"},
    "youAreAtPickupLocation": {"en": "You are at the passenger pickup location.", "fa": "شما در محل سوار شدن مسافر هستید.", "ps": "تاسو د مسافر د پورته کېدو په ځای یاست."},
    "tapStartNavigation": {"en": "Tap Start navigation to follow the route.", "fa": "برای دنبال کردن مسیر، شروع ناوبری را بزنید.", "ps": "د لارې تعقیب لپاره نیویګیشن پیل کړئ."},
    "samePickupLocation": {"en": "You and the passenger are at the same pickup location.", "fa": "شما و مسافر در یک محل سوار شدن هستید.", "ps": "تاسو او مسافر په یوه ځای کې یاست."},
    "tripStartedFollowRoute": {"en": "Trip started. Follow the route to the destination.", "fa": "سفر شروع شد. مسیر را تا مقصد دنبال کنید.", "ps": "سفر پیل شو. لاره تر منزل تعقیب کړئ."},
    "completeThisTrip": {"en": "Complete this trip?", "fa": "این سفر تکمیل شود؟", "ps": "دا سفر بشپړ شي؟"},
    "onlyCompleteAfterDestination": {"en": "Only complete after the passenger has reached the destination.", "fa": "فقط پس از رسیدن مسافر به مقصد تکمیل کنید.", "ps": "یوازې وروسته له دې چې مسافر منزل ته ورسیږي بشپړ یې کړئ."},
    "keepDriving": {"en": "Keep driving", "fa": "به رانندگی ادامه دهید", "ps": "چلولو ته دوام ورکړئ"},
    "completeTrip": {"en": "Complete trip", "fa": "تکمیل سفر", "ps": "سفر بشپړ کړئ"},
    "onlyCancelIfCannotContinue": {"en": "Only cancel if you cannot safely continue. The passenger will be notified.", "fa": "فقط اگر ادامه ایمن ممکن نیست لغو کنید. مسافر مطلع می‌شود.", "ps": "یوازې که خوندي دوام نشئ کولی لغوه کړئ. مسافر به خبر شي."},
    "waitingForPassenger": {"en": "Waiting for passenger", "fa": "منتظر مسافر", "ps": "مسافر ته انتظار"},
    "dropoffWithAddress": {"en": "Drop-off: {address}", "fa": "پیاده شدن: {address}", "ps": "کوزېدل: {address}"},
    "atPickupStartWhenOnboard": {"en": "At pickup — start trip when passenger is onboard", "fa": "در سوار شدن — پس از سوار شدن مسافر سفر را شروع کنید", "ps": "په پورته کېدو کې — کله چې مسافر کېني سفر پیل کړئ"},
    "yourCurrentLocation": {"en": "Your current location", "fa": "موقعیت فعلی شما", "ps": "ستاسو اوسنی موقعیت"},
    "mayCancelWithoutFeeNoShow": {"en": "You may cancel without fee if the passenger did not show.", "fa": "اگر مسافر نیامد می‌توانید بدون هزینه لغو کنید.", "ps": "که مسافر رانغی کولای شئ پرته له فیس لغوه کړئ."},
    "startTripOnceOnboard": {"en": "Start the trip once the passenger is in your car.", "fa": "وقتی مسافر سوار شد سفر را شروع کنید.", "ps": "کله چې مسافر په موټر کې شي سفر پیل کړئ."},
    "navigateToDropoff": {"en": "Navigate to drop-off", "fa": "مسیریابی تا پیاده شدن", "ps": "کوزېدو ته لارښوونه"},
    "cancelRideNoFee": {"en": "Cancel ride (no fee)", "fa": "لغو سفر (بدون هزینه)", "ps": "سفر لغوه کړئ (بې فیس)"},
    "goToPickup": {"en": "Go to pickup", "fa": "رفتن به سوار شدن", "ps": "پورته کېدو ته لاړ شئ"},
    "startTrip": {"en": "Start trip", "fa": "شروع سفر", "ps": "سفر پیل کړئ"},
    "tripStartedKeepDriving": {"en": "Trip started - keep driving", "fa": "سفر شروع شد — ادامه دهید", "ps": "سفر پیل شو — چلولو ته دوام ورکړئ"},
    "statusLabel": {"en": "Status: {status}", "fa": "وضعیت: {status}", "ps": "حالت: {status}"},

    # Fare / earnings / wallet
    "tagPolite": {"en": "Polite", "fa": "مؤدب", "ps": "مؤدب"},
    "tagOnTimeAtPickup": {"en": "On time at pickup", "fa": "به‌موقع در سوار شدن", "ps": "په پورته کېدو پر وخت"},
    "tagClearDirections": {"en": "Clear directions", "fa": "آدرس واضح", "ps": "روښانه لارښوونه"},
    "tagRespectful": {"en": "Respectful", "fa": "محترم", "ps": "درناوی"},
    "tagEasyPickup": {"en": "Easy pickup", "fa": "سوار شدن آسان", "ps": "اسانه پورته کېدل"},
    "couldNotUpdateAvailability": {"en": "Could not update availability", "fa": "وضعیت در دسترس بودن به‌روز نشد", "ps": "شتون تازه نه شو"},
    "greatJob": {"en": "Great job!", "fa": "عالی بود!", "ps": "ډېر ښه!"},
    "tripCompletedFareBreakdown": {"en": "Trip completed. Here's your fare breakdown.", "fa": "سفر تکمیل شد. جزئیات کرایه این است.", "ps": "سفر بشپړ شو. دا ستاسو د کرایې جزئیات دي."},
    "rateYourPassenger": {"en": "Rate your passenger", "fa": "به مسافر امتیاز دهید", "ps": "خپل مسافر درجه کړئ"},
    "feedbackKeepsRawanaSafe": {"en": "Your feedback helps keep Rawana safe and reliable.", "fa": "بازخورد شما روانا را ایمن و قابل اعتماد نگه می‌دارد.", "ps": "ستاسو نظر روانا خوندي او باوري ساتي."},
    "openToNewRequests": {"en": "You are open to new ride requests", "fa": "برای درخواست‌های جدید آماده‌اید", "ps": "تاسو د نویو سفرونو لپاره خلاص یاست"},
    "goOnlineToReceiveRequests": {"en": "Go online to receive new requests", "fa": "برای دریافت درخواست جدید آنلاین شوید", "ps": "د نویو غوښتنو لپاره آنلاین شئ"},
    "youEarned": {"en": "YOU EARNED", "fa": "درآمد شما", "ps": "ستاسو عاید"},
    "grossFare": {"en": "Gross fare", "fa": "کرایه ناخالص", "ps": "ټول کرایه"},
    "rawanaFeePercent": {"en": "Rawana fee ({percent}%)", "fa": "کارمزد روانا ({percent}٪)", "ps": "د روانا فیس ({percent}٪)"},
    "yourEarnings": {"en": "Your earnings", "fa": "درآمد شما", "ps": "ستاسو عاید"},
    "today": {"en": "Today", "fa": "امروز", "ps": "نن"},
    "thisWeek": {"en": "This week", "fa": "این هفته", "ps": "دا اونۍ"},
    "thisMonth": {"en": "This month", "fa": "این ماه", "ps": "دا میاشت"},
    "couldNotLoadEarnings": {"en": "Could not load earnings", "fa": "درآمد بارگذاری نشد", "ps": "عاید پورته نه شو"},
    "platformFee": {"en": "Platform fee", "fa": "کارمزد پلتفرم", "ps": "د پلیټفارم فیس"},
    "avgPerTrip": {"en": "Avg / trip", "fa": "میانگین / سفر", "ps": "منځنی / سفر"},
    "netEarnings": {"en": "Net earnings", "fa": "درآمد خالص", "ps": "خالص عاید"},
    "noTripsYetPeriod": {"en": "No trips yet {period}", "fa": "هنوز سفری در {period} نیست", "ps": "په {period} کې تر اوسه سفر نشته"},
    "tripsCompletedOne": {"en": "{count} trip completed", "fa": "{count} سفر تکمیل شد", "ps": "{count} سفر بشپړ شو"},
    "tripsCompletedOther": {"en": "{count} trips completed", "fa": "{count} سفر تکمیل شد", "ps": "{count} سفرونه بشپړ شول"},
    "howEarningsWork": {"en": "How earnings work", "fa": "درآمد چگونه کار می‌کند", "ps": "عاید څنګه کار کوي"},
    "earningsExplainer": {"en": "Gross fares are what passengers paid. Platform fee is deducted automatically; net earnings are deposited to your wallet and become available for payout.", "fa": "کرایه ناخالص مبلغ پرداخت‌شده مسافر است. کارمزد خودکار کسر می‌شود و درآمد خالص به کیف پول واریز می‌گردد.", "ps": "ټول کرایه هغه دی چې مسافر ورکړی. د پلیټفارم فیس په خپل سر کمېږي او خالص عاید ستاسو بټوې ته ځي."},
    "activitySnapshot": {"en": "Activity snapshot", "fa": "نمای فعالیت", "ps": "د فعالیت انځور"},
    "completeTripsToSeeActivity": {"en": "Complete trips to see your activity pattern.", "fa": "برای دیدن الگوی فعالیت سفرها را تکمیل کنید.", "ps": "د فعالیت د لیدو لپاره سفرونه بشپړ کړئ."},
    "couldNotLoadWallet": {"en": "Could not load wallet", "fa": "کیف پول بارگذاری نشد", "ps": "بټوه پورته نه شوه"},
    "recentTransactions": {"en": "Recent transactions", "fa": "تراکنش‌های اخیر", "ps": "وروستي راکړې ورکړې"},
    "couldNotLoadTransactions": {"en": "Could not load transactions", "fa": "تراکنش‌ها بارگذاری نشد", "ps": "راکړې ورکړې پورته نه شوې"},
    "requestPayoutQuestion": {"en": "Request payout?", "fa": "درخواست برداشت؟", "ps": "تادیه وغواړئ؟"},
    "willTransferToPayoutAccount": {"en": "We will transfer {amount} from your wallet. Rawana processes payouts — no bank account is required in the app.", "fa": "{amount} از کیف پول منتقل می‌شود. روانا برداشت را پردازش می‌کند — نیازی به حساب بانکی در برنامه نیست.", "ps": "موږ به {amount} له بټوې ولېږدوو. روانا تادیه پروسس کوي — په اپ کې بانکي حساب اړین نه دی."},
    "payoutRequested": {"en": "Payout requested", "fa": "برداشت درخواست شد", "ps": "تادیه وغوښتل شوه"},
    "availableBalance": {"en": "Available balance", "fa": "موجودی قابل برداشت", "ps": "شته بیلانس"},
    "pendingAmount": {"en": "Pending {amount}", "fa": "در انتظار {amount}", "ps": "په انتظار {amount}"},
    "requestPayout": {"en": "Request payout", "fa": "درخواست برداشت", "ps": "تادیه وغواړئ"},
    "noFundsYet": {"en": "No funds yet", "fa": "هنوز موجودی نیست", "ps": "تر اوسه پیسې نشته"},
    "noTransactionsYet": {"en": "No transactions yet", "fa": "هنوز تراکنشی نیست", "ps": "تر اوسه راکړه ورکړه نشته"},
    "earningsPayoutsWillShowHere": {"en": "Earnings and payouts will show up here.", "fa": "درآمد و برداشت‌ها اینجا نمایش داده می‌شوند.", "ps": "عاید او تادیات به دلته ښکاره شي."},
    "transaction": {"en": "Transaction", "fa": "تراکنش", "ps": "راکړه ورکړه"},

    # Driver history / profile / support
    "tripHistory": {"en": "Trip history", "fa": "تاریخچه سفرها", "ps": "د سفرونو تاریخچه"},
    "couldNotLoadTripHistory": {"en": "Could not load trip history", "fa": "تاریخچه سفر بارگذاری نشد", "ps": "د سفر تاریخچه پورته نه شوه"},
    "totalEarned": {"en": "Total earned", "fa": "کل درآمد", "ps": "ټول عاید"},
    "allTrips": {"en": "All trips", "fa": "همه سفرها", "ps": "ټول سفرونه"},
    "unknownDestination": {"en": "Unknown destination", "fa": "مقصد نامعلوم", "ps": "نامعلوم منزل"},
    "unknownPickup": {"en": "Unknown pickup", "fa": "سوار شدن نامعلوم", "ps": "نامعلوم پورته کېدل"},
    "pickupUnknown": {"en": "Pickup unknown", "fa": "سوار شدن نامعلوم", "ps": "پورته کېدل نامعلوم"},
    "fromPickup": {"en": "From {pickup}", "fa": "از {pickup}", "ps": "له {pickup}"},
    "completedCancelledRidesAppearHere": {"en": "Your completed and cancelled rides will appear here.", "fa": "سفرهای تکمیل و لغوشده اینجا ظاهر می‌شوند.", "ps": "ستاسو بشپړ او لغوه سفرونه به دلته ښکاره شي."},
    "failedToLoadTrip": {"en": "Failed to load trip: {error}", "fa": "بارگذاری سفر ناموفق: {error}", "ps": "سفر پورته نه شو: {error}"},
    "durationMin": {"en": "{n} min", "fa": "{n} دقیقه", "ps": "{n} دقیقې"},
    "openRouteInMaps": {"en": "Open route in Maps", "fa": "باز کردن مسیر در نقشه", "ps": "لاره په نقشه کې پرانیزئ"},
    "profileUpdated": {"en": "Profile updated", "fa": "پروفایل به‌روز شد", "ps": "پروفایل تازه شو"},
    "signOutQuestion": {"en": "Sign out?", "fa": "خارج شوید؟", "ps": "ووزئ؟"},
    "signOutNeedSignBackIn": {"en": "You will need to sign back in to receive ride requests.", "fa": "برای دریافت درخواست باید دوباره وارد شوید.", "ps": "د سفر غوښتنو لپاره باید بیا ننوزئ."},
    "couldNotLoadProfile": {"en": "Could not load profile", "fa": "پروفایل بارگذاری نشد", "ps": "پروفایل پورته نه شو"},
    "driverFallbackName": {"en": "Driver", "fa": "راننده", "ps": "چلوونکی"},
    "vehicle": {"en": "Vehicle", "fa": "موتر", "ps": "موټر"},
    "makeAndModel": {"en": "Make & model", "fa": "نوع و مدل", "ps": "جوړونکی او ماډل"},
    "quickActions": {"en": "Quick actions", "fa": "اقدامات سریع", "ps": "چټک کړنې"},
    "myDocuments": {"en": "My documents", "fa": "مدارک من", "ps": "زما اسناد"},
    "viewUploadedPapers": {"en": "View uploaded verification papers", "fa": "مشاهده مدارک بارگذاری‌شده", "ps": "پورته شوي اسناد وګورئ"},
    "privacyAndSecurity": {"en": "Privacy & security", "fa": "حریم خصوصی و امنیت", "ps": "محرمیت او امنیت"},
    "manageAccountSafety": {"en": "Manage your account safety", "fa": "امنیت حساب را مدیریت کنید", "ps": "د حساب خوندیتوب اداره کړئ"},
    "personalDetails": {"en": "Personal details", "fa": "اطلاعات شخصی", "ps": "شخصي معلومات"},
    "vehicleMake": {"en": "Vehicle make", "fa": "نوع موتر", "ps": "د موټر جوړونکی"},
    "vehicleModel": {"en": "Vehicle model", "fa": "مدل موتر", "ps": "د موټر ماډل"},
    "saveChanges": {"en": "Save changes", "fa": "ذخیره تغییرات", "ps": "بدلونونه وساتئ"},
    "couldNotLoadDocuments": {"en": "Could not load documents", "fa": "مدارک بارگذاری نشد", "ps": "اسناد پورته نه شول"},
    "documentsVerified": {"en": "Your documents are verified.", "fa": "مدارک شما تأیید شده است.", "ps": "ستاسو اسناد تایید شوي دي."},
    "documentsAwaitingReview": {"en": "Documents submitted — awaiting admin review.", "fa": "مدارک ارسال شد — در انتظار بررسی ادمین.", "ps": "اسناد ولېږل شول — د ادمین کتنې ته انتظار."},
    "uploadDocsToStartEarning": {"en": "Upload your documents to start earning.", "fa": "برای شروع درآمد مدارک را بارگذاری کنید.", "ps": "د عاید پیل لپاره اسناد پورته کړئ."},
    "noDocumentsYet": {"en": "No documents yet", "fa": "هنوز مدرکی نیست", "ps": "تر اوسه سند نشته"},
    "uploadLicenceRegId": {"en": "Upload your licence, registration, and ID to get approved.", "fa": "جواز، ثبت و تذکره را برای تأیید بارگذاری کنید.", "ps": "د تایید لپاره جواز، ثبت او تذکره پورته کړئ."},
    "uploadDocuments": {"en": "Upload documents", "fa": "بارگذاری مدارک", "ps": "اسناد پورته کړئ"},
    "submittedFiles": {"en": "Submitted files", "fa": "فایل‌های ارسال‌شده", "ps": "لېږل شوي فایلونه"},
    "updateDocuments": {"en": "Update documents", "fa": "به‌روزرسانی مدارک", "ps": "اسناد تازه کړئ"},
    "documentNotUploaded": {"en": "{label} — not uploaded", "fa": "{label} — بارگذاری نشده", "ps": "{label} — نه دی پورته شوی"},
    "passwordMinEightChars": {"en": "Password must be at least 8 characters", "fa": "رمز باید حداقل ۸ حرف باشد", "ps": "پاسورډ باید لږ تر لږه ۸ توري وي"},
    "passwordsDoNotMatch": {"en": "Passwords do not match", "fa": "رمزها یکسان نیستند", "ps": "پاسورډونه سره نه دي"},
    "passwordUpdated": {"en": "Password updated", "fa": "رمز به‌روز شد", "ps": "پاسورډ تازه شو"},
    "requestAccountDeletion": {"en": "Request account deletion", "fa": "درخواست حذف حساب", "ps": "د حساب حذف غوښتنه"},
    "accountProtectedNeverSharePassword": {"en": "Your account is protected with secure sign-in. Never share your password with anyone.", "fa": "حساب شما با ورود امن محافظت می‌شود. رمز را با کسی شریک نکنید.", "ps": "ستاسو حساب په خوندي ننوتلو ساتل کېږي. پاسورډ له چا سره مه شریکوه."},
    "signInSection": {"en": "Sign-in", "fa": "ورود", "ps": "ننوتل"},
    "notLinked": {"en": "Not linked", "fa": "متصل نیست", "ps": "نه دی تړل شوی"},
    "verified": {"en": "Verified", "fa": "تأییدشده", "ps": "تایید شوی"},
    "unverified": {"en": "Unverified", "fa": "تأییدنشده", "ps": "نه تایید شوی"},
    "changePassword": {"en": "Change password", "fa": "تغییر رمز", "ps": "پاسورډ بدل کړئ"},
    "newPassword": {"en": "New password", "fa": "رمز جدید", "ps": "نوی پاسورډ"},
    "confirmPassword": {"en": "Confirm password", "fa": "تأیید رمز", "ps": "پاسورډ تایید کړئ"},
    "updatePassword": {"en": "Update password", "fa": "به‌روزرسانی رمز", "ps": "پاسورډ تازه کړئ"},
    "policies": {"en": "Policies", "fa": "سیاست‌ها", "ps": "تګلارې"},
    "termsAndPolicies": {"en": "Terms & policies", "fa": "شرایط و سیاست‌ها", "ps": "شرایط او تګلارې"},
    "howRawanaOperates": {"en": "How Rawana operates", "fa": "روانا چگونه کار می‌کند", "ps": "روانا څنګه کار کوي"},
    "driverGuidelines": {"en": "Driver guidelines", "fa": "راهنمای راننده", "ps": "د چلوونکي لارښوونې"},
    "bestPracticesOnPlatform": {"en": "Best practices on the platform", "fa": "بهترین روش‌ها در پلتفرم", "ps": "په پلیټفارم کې غوره کړنې"},
    "teamWillProcessRequest": {"en": "Our team will process your request", "fa": "تیم ما درخواست شما را پردازش می‌کند", "ps": "زموږ ډله به ستاسو غوښتنه پروسس کړي"},
    "supportEmailFallback": {"en": "Email: support@rawana.af", "fa": "ایمیل: support@rawana.af", "ps": "ایمیل: support@rawana.af"},
    "support": {"en": "Support", "fa": "پشتیبانی", "ps": "ملاتړ"},
    "getHelp": {"en": "Get help", "fa": "دریافت کمک", "ps": "مرسته واخلئ"},
    "reportATripIssue": {"en": "Report a trip issue", "fa": "گزارش مشکل سفر", "ps": "د سفر ستونزه راپور کړئ"},
    "lostItemWrongFareRoute": {"en": "Lost item, wrong fare, route problem", "fa": "شیء گم‌شده، کرایه نادرست، مشکل مسیر", "ps": "ورک شی، ناسم کرایه، د لارې ستونزه"},
    "reportASafetyConcern": {"en": "Report a safety concern", "fa": "گزارش نگرانی ایمنی", "ps": "د خوندیتوب اندیښنه راپور کړئ"},
    "tellUsUnsafeBehaviour": {"en": "Tell us about unsafe behaviour", "fa": "درباره رفتار ناایمن بگویید", "ps": "د ناامن چلند په اړه ووایاست"},
    "contactAdmin": {"en": "Contact admin", "fa": "تماس با ادمین", "ps": "له ادمین سره اړیکه"},
    "emailOurSupportTeam": {"en": "Email our support team", "fa": "ایمیل به تیم پشتیبانی", "ps": "زموږ ملاتړ ټیم ته ایمیل"},
    "resources": {"en": "Resources", "fa": "منابع", "ps": "سرچینې"},
    "bestPracticesKeepRatingHigh": {"en": "Best practices to keep your rating high", "fa": "روش‌هایی برای حفظ امتیاز بالا", "ps": "د لوړې درجې ساتلو غوره لارې"},
    "myReports": {"en": "My reports", "fa": "گزارش‌های من", "ps": "زما راپورونه"},
    "couldNotLoadReports": {"en": "Could not load your reports: {error}", "fa": "گزارش‌ها بارگذاری نشد: {error}", "ps": "راپورونه پورته نه شول: {error}"},
    "noSupportReportsYet": {"en": "No support reports yet. Use the options above if you need help.", "fa": "هنوز گزارشی نیست. در صورت نیاز از گزینه‌های بالا استفاده کنید.", "ps": "تر اوسه راپور نشته. که مرستې ته اړتیا لرئ پورتنۍ اختیارونه وکاروئ."},
    "supportTicket": {"en": "Support ticket", "fa": "تیکت پشتیبانی", "ps": "د ملاتړ ټکټ"},
    "ticketStatusOpen": {"en": "open", "fa": "باز", "ps": "خلاص"},
    "weHaveYourBack": {"en": "We have your back", "fa": "ما پشتیبان شما هستیم", "ps": "موږ ستاسو مل یو"},
    "getHelp247": {"en": "Get help from our team, 24/7.", "fa": "شبانه‌روز از تیم ما کمک بگیرید.", "ps": "شپه او ورځ له زموږ ډلې مرسته واخلئ."},
    "couldNotLoadTrips": {"en": "Could not load trips", "fa": "سفرها بارگذاری نشد", "ps": "سفرونه پورته نه شول"},
    "completeRideThenReport": {"en": "Complete a ride first, then you can report an issue here.", "fa": "ابتدا یک سفر را تکمیل کنید، سپس اینجا گزارش دهید.", "ps": "لومړی یو سفر بشپړ کړئ، بیا دلته راپور ورکړئ."},
    "selectTripNeedHelp": {"en": "Select the trip you need help with", "fa": "سفری را که نیاز به کمک دارد انتخاب کنید", "ps": "هغه سفر وټاکئ چې مرستې ته اړتیا لري"},
    "generalIssueNoTrip": {"en": "General issue (no trip)", "fa": "مشکل عمومی (بدون سفر)", "ps": "عمومي ستونزه (بې سفر)"},
    "notificationsEmptyMessage": {"en": "Ride requests, payout updates, and announcements\nwill appear here.", "fa": "درخواست سفر، به‌روزرسانی برداشت و اطلاعیه‌ها\nاینجا ظاهر می‌شوند.", "ps": "د سفر غوښتنې، د تادیې تازه معلومات او خبرتیاوې\nبه دلته ښکاره شي."},
    "performance": {"en": "Performance", "fa": "عملکرد", "ps": "فعالیت"},
    "couldNotLoadPerformance": {"en": "Could not load performance", "fa": "عملکرد بارگذاری نشد", "ps": "فعالیت پورته نه شوه"},
    "serviceMetrics": {"en": "Service metrics", "fa": "شاخص‌های خدمات", "ps": "د خدمت شاخصونه"},
    "acceptanceRate": {"en": "Acceptance rate", "fa": "نرخ قبول", "ps": "د منلو کچه"},
    "cancellationRate": {"en": "Cancellation rate", "fa": "نرخ لغو", "ps": "د لغوه کچه"},
    "totalTrips": {"en": "Total trips", "fa": "کل سفرها", "ps": "ټول سفرونه"},
    "onlineTime": {"en": "Online time", "fa": "زمان آنلاین", "ps": "آنلاین وخت"},
    "hoursShort": {"en": "{h}h", "fa": "{h} ساعت", "ps": "{h} ساعت"},
    "hoursMinutesShort": {"en": "{h}h {m}m", "fa": "{h}س {m}د", "ps": "{h}س {m}د"},
    "averageRiderRating": {"en": "Average rider rating", "fa": "میانگین امتیاز مسافر", "ps": "د مسافر منځنۍ درجه"},
    "higherAcceptanceLowerCancelTip": {"en": "Higher acceptance and lower cancellation rates help you get more ride requests.", "fa": "قبول بیشتر و لغو کمتر باعث درخواست‌های بیشتر می‌شود.", "ps": "لوړه منل او کمه لغوه تاسو ته نورې غوښتنې درکوي."},

    # Driver cancel / wait
    "cancelReasonNotAtPickup": {"en": "Passenger not at pickup", "fa": "مسافر در محل سوار شدن نیست", "ps": "مسافر په پورته کېدو کې نه دی"},
    "cancelReasonWrongPickup": {"en": "Wrong pickup location", "fa": "محل سوار شدن اشتباه", "ps": "ناسم د پورته کېدو ځای"},
    "cancelReasonSafety": {"en": "Safety concern", "fa": "نگرانی ایمنی", "ps": "د خوندیتوب اندیښنه"},
    "cancelReasonVehicle": {"en": "Vehicle issue", "fa": "مشکل موتر", "ps": "د موټر ستونزه"},
    "cancelReasonEmergency": {"en": "Personal emergency", "fa": "اضطرار شخصی", "ps": "شخصي بیړنی حالت"},
    "cancelReasonNoShow": {"en": "Passenger no-show", "fa": "مسافر حاضر نشد", "ps": "مسافر رانغی"},
    "noFeePassengerNoShow": {"en": "No cancellation fee — passenger did not show up after the waiting period.", "fa": "بدون هزینه لغو — مسافر پس از زمان انتظار نیامد.", "ps": "بې فیس لغوه — مسافر د انتظار وروسته رانغی."},
    "cancellationFeeMayApply": {"en": "A cancellation fee may apply if you cancel now.", "fa": "اگر الان لغو کنید ممکن است هزینه اعمال شود.", "ps": "که اوس لغوه کړئ کېدای شي فیس ولګېږي."},
    "reason": {"en": "REASON", "fa": "دلیل", "ps": "لامل"},
    "waitingPeriodEndedNoFee": {"en": "Waiting period ended. You may cancel without a fee if the passenger did not show.", "fa": "زمان انتظار تمام شد. اگر مسافر نیامد بدون هزینه لغو کنید.", "ps": "د انتظار وخت پای ته ورسېد. که مسافر رانغی پرته له فیس لغوه کولی شئ."},
    "freeWaitRemaining": {"en": "Free wait: {time} remaining", "fa": "انتظار رایگان: {time} باقی", "ps": "وړیا انتظار: {time} پاتې"},
    "passengerNoShowWindow": {"en": "Passenger no-show window", "fa": "بازه عدم حضور مسافر", "ps": "د مسافر د نه راتګ موده"},
    "cancelWithoutFeeIn": {"en": "Cancel without fee in {time}", "fa": "لغو بدون هزینه تا {time}", "ps": "په {time} کې پرته له فیس لغوه کړئ"},
    "arrived": {"en": "Arrived", "fa": "رسید", "ps": "ورسېد"},
    "trip": {"en": "Trip", "fa": "سفر", "ps": "سفر"},
    "done": {"en": "Done", "fa": "تمام", "ps": "تمام"},

    # Driver routing errors
    "accountNotRegisteredAsDriver": {"en": "This account is not registered as a driver. Sign in with your driver account.", "fa": "این حساب به عنوان راننده ثبت نشده. با حساب راننده وارد شوید.", "ps": "دا حساب د چلوونکي په توګه نه دی ثبت. په چلوونکي حساب ننوزئ."},
    "sessionExpiredSignInAgain": {"en": "Session expired. Sign out and sign in again.", "fa": "نشست منقضی شد. خارج شوید و دوباره وارد شوید.", "ps": "ناسته پای ته ورسېده. ووزئ او بیا ننوزئ."},
    "driverProfileNotFound": {"en": "Driver profile not found. Complete document upload first.", "fa": "پروفایل راننده یافت نشد. ابتدا مدارک را بارگذاری کنید.", "ps": "د چلوونکي پروفایل ونه موندل شو. لومړی اسناد پورته کړئ."},
    "cannotReachRawanaServer": {"en": "Cannot reach the Rawana server. Check your connection and try again.", "fa": "سرور روانا در دسترس نیست. اتصال را بررسی کنید و دوباره تلاش کنید.", "ps": "د روانا سرور ته لاسرسی نشته. اتصال وګورئ او بیا هڅه وکړئ."},
    "couldNotLoadDriverProfile": {"en": "Could not load driver profile.", "fa": "پروفایل راننده بارگذاری نشد.", "ps": "د چلوونکي پروفایل پورته نه شو."},

    # Driver content titles (guidelines / terms)
    "driverGuideProfessionalTitle": {"en": "Stay professional", "fa": "حرفه‌ای بمانید", "ps": "مسلکي اوسئ"},
    "driverGuideProfessionalBody": {"en": "Greet passengers politely, keep your vehicle clean, and follow local traffic laws. A calm, respectful attitude is the fastest way to earn five-star ratings.", "fa": "با مسافران مؤدب سلام کنید، موتر را تمیز نگه دارید و قوانین ترافیک را رعایت کنید. رفتار آرام و محترمانه سریع‌ترین راه برای امتیاز پنج‌ستاره است.", "ps": "له مسافرو سره په ادب سلام وکړئ، موټر پاک وساتئ او د ترافیک قوانین مراعات کړئ. ارامه او درناوی چلند د پنځه ستورو چټکه لار ده."},
    "driverGuideAcceptTitle": {"en": "Accept rides promptly", "fa": "سفرها را سریع قبول کنید", "ps": "سفرونه ژر ومنئ"},
    "driverGuideAcceptBody": {"en": "High acceptance rates help you receive more requests. Only go online when you are ready to drive. If you must decline, do it quickly so the passenger can find another driver.", "fa": "نرخ قبول بالا درخواست‌های بیشتری می‌آورد. فقط وقتی آماده‌اید آنلاین شوید. اگر رد می‌کنید سریع باشید تا مسافر راننده دیگری پیدا کند.", "ps": "لوړه منل نورې غوښتنې درکوي. یوازې کله چې چمتو یاست آنلاین شئ. که ردوي یې نو ژر یې وکړئ ترڅو مسافر بل چلوونکی ومومي."},
    "driverGuideNavigateTitle": {"en": "Navigate accurately", "fa": "دقیق مسیریابی کنید", "ps": "سمه لارښوونه وکړئ"},
    "driverGuideNavigateBody": {"en": "Use the in-app route to pickup and drop-off. Confirm the destination with the passenger before starting the trip. If the address is unclear, call or message through the app.", "fa": "از مسیر داخل برنامه برای سوار و پیاده شدن استفاده کنید. قبل از شروع، مقصد را با مسافر تأیید کنید. اگر آدرس مبهم است از برنامه تماس یا پیام دهید.", "ps": "په اپ کې لاره د پورته او کوزېدو لپاره وکاروئ. مخکې له پیل منزل له مسافر سره تایید کړئ. که پته مبهمه وي له اپ څخه زنګ یا پیغام وکړئ."},
    "driverGuideSafetyTitle": {"en": "Safety first", "fa": "ایمنی اول", "ps": "خوندیتوب لومړی"},
    "driverGuideSafetyBody": {"en": "Do not drive tired or under the influence. Report safety concerns immediately through Support. In an emergency, contact local authorities first, then notify Rawana.", "fa": "خسته یا تحت تأثیر مواد رانندگی نکنید. نگرانی ایمنی را فوراً از پشتیبانی گزارش دهید. در اضطرار ابتدا با مقامات محلی تماس بگیرید سپس روانا را خبر کنید.", "ps": "ستړی یا د نشې په حال کې مه چلوئ. د خوندیتوب اندیښنې سمدستي له ملاتړ راپور کړئ. په بیړني حالت کې لومړی له سیمه‌ییزو چارواکو سره اړیکه ونیسئ بیا روانا خبر کړئ."},
    "driverGuideFaresTitle": {"en": "Fares & payments", "fa": "کرایه و پرداخت", "ps": "کرایه او تادیه"},
    "driverGuideFaresBody": {"en": "Fares are calculated automatically from distance, time, and zone pricing. Do not ask passengers for extra cash unless agreed in the app. Earnings appear in your wallet after each completed trip.", "fa": "کرایه از فاصله، زمان و قیمت‌گذاری منطقه خودکار محاسبه می‌شود. پول اضافه نخواهید مگر در برنامه توافق شده باشد. درآمد پس از هر سفر تکمیل‌شده در کیف پول ظاهر می‌شود.", "ps": "کرایه له واټن، وخت او زون نرخ څخه په خپل سر حسابېږي. له مسافر اضافي پیسې مه غواړئ مگر په اپ کې توافق شوی وي. عاید د هر بشپړ سفر وروسته په بټوه کې ښکاره کېږي."},
    "driverGuideCancellationsTitle": {"en": "Cancellations", "fa": "لغوها", "ps": "لغوه کول"},
    "driverGuideCancellationsBody": {"en": "Avoid cancelling after accepting a ride. Frequent cancellations lower your performance score and may reduce future requests. Cancel only when necessary and add a clear reason.", "fa": "پس از قبول سفر از لغو خودداری کنید. لغو مکرر امتیاز عملکرد را پایین می‌آورد و درخواست‌های آینده را کم می‌کند. فقط در ضرورت لغو کنید و دلیل واضح بنویسید.", "ps": "له منلو وروسته له لغوه ډډه وکړئ. پرله‌پسې لغوه ستاسو درجه ښکته کوي او راتلونکې غوښتنې کمولی شي. یوازې اړتیا کې لغوه کړئ او روښانه لامل ولیکئ."},
    "termsDriverAgreement": {"en": "Driver agreement", "fa": "توافق‌نامه راننده", "ps": "د چلوونکي تړون"},
    "termsDriverAgreementBody": {"en": "By using Rawana Driver you agree to provide ride-hailing services in line with platform rules, local regulations, and the documents you submitted during onboarding.", "fa": "با استفاده از روانا راننده موافقت می‌کنید خدمات را مطابق قوانین پلتفرم، مقررات محلی و مدارک ثبت‌نام ارائه دهید.", "ps": "د روانا چلوونکي په کارولو تاسو منئ چې خدمات د پلیټفارم قوانینو، سیمه‌ییزو مقرراتو او د نوم لیکنې اسنادو سره سم وړاندې کړئ."},
    "termsAccountVerification": {"en": "Account & verification", "fa": "حساب و تأیید", "ps": "حساب او تایید"},
    "termsAccountVerificationBody": {"en": "You must keep your licence, vehicle registration, and identity documents valid and up to date. Rawana may suspend accounts with expired or fraudulent documents.", "fa": "جواز، ثبت موتر و مدارک هویتی باید معتبر و به‌روز باشد. روانا ممکن حساب‌های با مدارک منقضی یا جعلی را تعلیق کند.", "ps": "باید جواز، د موټر ثبت او پېژندپاڼه باوري او تازه وساتئ. روانا کېدای شي هغه حسابونه وځنډوي چې اسناد یې ختم یا جعلي وي."},
    "termsEarningsPayouts": {"en": "Earnings & payouts", "fa": "درآمد و برداشت", "ps": "عاید او تادیات"},
    "termsEarningsPayoutsBody": {"en": "Trip fares are credited to your wallet minus Rawana's commission. Payout requests are processed according to finance team schedules. Fraudulent activity may result in withheld balances.", "fa": "کرایه پس از کسر کارمزد روانا به کیف پول واریز می‌شود. برداشت‌ها طبق برنامه تیم مالی پردازش می‌شود. فعالیت متقلبانه ممکن است موجودی را نگه دارد.", "ps": "کرایه د روانا کمیشن وروسته ستاسو بټوې ته ځي. د تادیې غوښتنې د مالي ټیم د مهالویش سره پروسس کېږي. درغلي کېدای شي بیلانس وځنډوي."},
    "termsPrivacy": {"en": "Privacy", "fa": "حریم خصوصی", "ps": "محرمیت"},
    "termsPrivacyBody": {"en": "We collect location while you are online, trip history, and contact details to operate the service. Passenger phone numbers may be masked during active trips. See Privacy & security in your profile for account controls.", "fa": "موقعیت هنگام آنلاین بودن، تاریخچه سفر و اطلاعات تماس را برای ارائه خدمت جمع می‌کنیم. شماره مسافر در سفر فعال ممکن است مخفی شود. کنترل‌ها را در حریم خصوصی و امنیت پروفایل ببینید.", "ps": "موږ موقعیت په آنلاین وخت، د سفر تاریخچه او اړیکې د خدمت لپاره راټولوو. د مسافر شمېره په فعال سفر کې کېدای شي پټه شي. کنټرولونه په پروفایل کې د محرمیت او امنیت برخه کې وګورئ."},
    "termsConductSuspension": {"en": "Conduct & suspension", "fa": "رفتار و تعلیق", "ps": "چلند او ځنډول"},
    "termsConductSuspensionBody": {"en": "Harassment, discrimination, unsafe driving, or repeated complaints can lead to temporary suspension or permanent removal from the platform.", "fa": "آزار، تبعیض، رانندگی ناایمن یا شکایت مکرر می‌تواند به تعلیق موقت یا حذف دائمی منجر شود.", "ps": "ځورونه، توپیر، ناامن چلول یا پرله‌پسې شکایتونه کېدای شي لنډمهاله ځنډ یا دایمي لرې کېدو لامل شي."},
    "termsSupport": {"en": "Support", "fa": "پشتیبانی", "ps": "ملاتړ"},
    "termsSupportBody": {"en": "For disputes, safety reports, or account help, use in-app Support or email support@rawana.af. We aim to respond to urgent safety issues as quickly as possible.", "fa": "برای اختلاف، گزارش ایمنی یا کمک حساب از پشتیبانی داخل برنامه یا support@rawana.af استفاده کنید. به مسائل ایمنی فوری سریع پاسخ می‌دهیم.", "ps": "د شخړو، د خوندیتوب راپورونو یا د حساب مرستې لپاره په اپ کې ملاتړ یا support@rawana.af وکاروئ. موږ هڅه کوو بیړنیو خوندیتوب مسلو ته ژر ځواب ورکړو."},
    "noCancellationFee": {"en": "No cancellation fee", "fa": "بدون هزینه لغو", "ps": "د لغوه فیس نشته"},
    "cancellationFeeAmount": {"en": "Cancellation fee: {amount}", "fa": "هزینه لغو: {amount}", "ps": "د لغوه فیس: {amount}"},
    "cancelSearchTitle": {"en": "Cancel this request?", "fa": "این درخواست لغو شود؟", "ps": "دا غوښتنه لغوه شي؟"},
    "cancelSearchBody": {"en": "You can request another ride right away. There is no fee while we are still finding a driver.", "fa": "می‌توانید فوراً سفر دیگری درخواست کنید. تا وقتی راننده پیدا نشده هزینه‌ای نیست.", "ps": "سمدستي بل سفر غوښتلی شئ. تر هغه چې چلوونکی نه وي موندل شوی فیس نشته."},
    "collectCashAmount": {"en": "Collect {amount} cash", "fa": "{amount} نقد بگیرید", "ps": "{amount} نغدي واخلئ"},
    "cashCollected": {"en": "Cash collected", "fa": "نقد دریافت شد", "ps": "نغدي واخیستل شول"},
    "openInGoogleMaps": {"en": "Open in Google Maps", "fa": "باز کردن در گوگل‌مپ", "ps": "په ګوګل نقشو کې پرانیزئ"},
    "tooFarContinueAnyway": {"en": "You are {distance} m from the pin. Continue anyway?", "fa": "شما {distance} متر از پین فاصله دارید. ادامه می‌دهید؟", "ps": "تاسو د پین څخه {distance} متره لرې یاست. بیا هم دوام ورکړئ؟"},
    "continueAnyway": {"en": "Continue anyway", "fa": "ادامه بده", "ps": "بیا هم دوام"},
    "payDriverCashAmount": {"en": "Pay your driver {amount} cash", "fa": "{amount} نقد به راننده بپردازید", "ps": "خپل چلوونکي ته {amount} نغدي ورکړئ"},
    "cashSelectedInfo": {"en": "Cash · AFN — pay your driver at drop-off", "fa": "نقدی · افغانی — در مقصد به راننده بپردازید", "ps": "نغدي · افغانۍ — په منزل کې چلوونکي ته ورکړئ"},
    "cashFare": {"en": "Cash fare", "fa": "کرایه نقدی", "ps": "نغدې کرایه"},
    "rideType": {"en": "Ride type", "fa": "نوع سفر", "ps": "د سفر ډول"},
    "selectRideType": {"en": "Which rides should you receive?", "fa": "کدام نوع سفر را می‌پذیرید؟", "ps": "کوم ډول سفرونه باید ترلاسه کړئ؟"},
    "fareBreakdown": {"en": "Fare breakdown", "fa": "جزئیات کرایه", "ps": "د کرایې جزئیات"},
    "baseFare": {"en": "Base fare", "fa": "کرایه پایه", "ps": "بنسټیزه کرایه"},
    "distanceFare": {"en": "Distance · {km} km", "fa": "فاصله · {km} کیلومتر", "ps": "واټن · {km} کیلومتره"},
    "timeFare": {"en": "Time · {minutes} min", "fa": "زمان · {minutes} دقیقه", "ps": "وخت · {minutes} دقیقې"},
    "taxLabel": {"en": "Tax", "fa": "مالیات", "ps": "مالیه"},
    "totalCash": {"en": "Total cash", "fa": "مجموع نقدی", "ps": "ټول نغدي"},
    "cancelGraceSeconds": {"en": "Free to cancel for the first {seconds} seconds after a driver accepts.", "fa": "تا {seconds} ثانیه پس از پذیرش راننده رایگان لغو می‌شود.", "ps": "د چلوونکي له منلو وروسته لومړۍ {seconds} ثانیې وړیا لغوه کېږي."},
    "maxEmergencyContacts": {"en": "You can save up to 3 emergency contacts.", "fa": "حداکثر ۳ مخاطب اضطراری می‌توانید ذخیره کنید.", "ps": "تر ۳ بیړنیو اړیکو پورې ساتلی شئ."},
    "maxContactsReached": {"en": "Maximum of 3 emergency contacts reached.", "fa": "حداکثر ۳ مخاطب اضطراری ثبت شده است.", "ps": "د ۳ بیړنیو اړیکو حد پوره شو."},
    "useThisLocation": {"en": "Use this location", "fa": "استفاده از این مکان", "ps": "دا ځای وکاروئ"},
    "chooseSavedPlace": {"en": "Choose location", "fa": "انتخاب مکان", "ps": "ځای وټاکئ"},
    "vehicleYear": {"en": "Vehicle year", "fa": "سال موتر", "ps": "د موټر کال"},
    "vehicleColour": {"en": "Vehicle colour", "fa": "رنگ موتر", "ps": "د موټر رنګ"},
    "openInWaze": {"en": "Open in Waze", "fa": "باز کردن در ویز", "ps": "په ویز کې پرانیزئ"},
    "chooseMapsApp": {"en": "Open in maps", "fa": "باز کردن در نقشه", "ps": "په نقشه کې پرانیزئ"},
    "findingAnotherDriver": {"en": "Your previous driver cancelled. We are finding you another driver.", "fa": "راننده قبلی لغو کرد. راننده دیگری پیدا می‌کنیم.", "ps": "پخوانی چلوونکی لغوه کړ. بل چلوونکی درته مومو."},
    "filterFrom": {"en": "From date", "fa": "از تاریخ", "ps": "له نېټې"},
    "filterTo": {"en": "To date", "fa": "تا تاریخ", "ps": "تر نېټې"},
    "clearFilters": {"en": "Clear filters", "fa": "پاک کردن فیلترها", "ps": "فلټرونه پاک کړئ"},
    "accountBlocked": {"en": "This account is blocked and cannot book rides.", "fa": "این حساب مسدود است و نمی‌تواند سفر رزرو کند.", "ps": "دا حساب بند دی او سفر نشی نیولی."},
    "editName": {"en": "Edit name", "fa": "ویرایش نام", "ps": "نوم سمول"},
    "promoCode": {"en": "Promo code", "fa": "کد تخفیف", "ps": "د تخفیف کوډ"},
    "applyPromo": {"en": "Apply", "fa": "اعمال", "ps": "پلي کړئ"},
    "promoApplied": {"en": "Promo applied", "fa": "تخفیف اعمال شد", "ps": "تخفیف وکارېد"},
    "promoInvalid": {"en": "This promo code is not valid.", "fa": "این کد تخفیف معتبر نیست.", "ps": "دا د تخفیف کوډ ناسم دی."},
    "promoExpired": {"en": "This promo code has expired.", "fa": "مهلت این کد تخفیف تمام شده است.", "ps": "د دې تخفیف کوډ موده پای ته رسېدلې."},
    "discount": {"en": "Discount", "fa": "تخفیف", "ps": "تخفیف"},
    "writeAReview": {"en": "Write a review (optional)", "fa": "نظر بنویسید (اختیاری)", "ps": "نظر ولیکئ (اختیاري)"},
    "ratingCommentHint": {"en": "How was the trip?", "fa": "سفر چطور بود؟", "ps": "سفر څنګه و؟"},
    "tripReceipt": {"en": "Trip receipt", "fa": "رسید سفر", "ps": "د سفر رسید"},
    "viewReceipt": {"en": "View receipt", "fa": "مشاهده رسید", "ps": "رسید وګورئ"},
    "maintenanceTitle": {"en": "We’ll be back shortly", "fa": "به‌زودی برمی‌گردیم", "ps": "ژر به بیرته راشو"},
    "forceUpdateTitle": {"en": "Update required", "fa": "به‌روزرسانی لازم است", "ps": "تازه کول اړین دي"},
    "forceUpdateBody": {"en": "Please update Rawana to continue.", "fa": "برای ادامه، روانا را به‌روزرسانی کنید.", "ps": "د دوام لپاره روانا تازه کړئ."},
    "updateApp": {"en": "Update app", "fa": "به‌روزرسانی برنامه", "ps": "اپ تازه کړئ"},
    "exportMyData": {"en": "Download my data", "fa": "دانلود داده‌های من", "ps": "زما معلومات ډاونلوډ کړئ"},
    "deleteAccount": {"en": "Delete account", "fa": "حذف حساب", "ps": "حساب ړنګ کړئ"},
    "deleteAccountConfirm": {"en": "Delete this account? This cannot be undone.", "fa": "این حساب حذف شود؟ این کار قابل بازگشت نیست.", "ps": "دا حساب ړنګ شي؟ دا کار نه شي بیرته کېدای."},
    "deleteAccountWarning": {"en": "Your profile and saved places will be removed. Trip records are kept for legal and safety reasons.", "fa": "پروفایل و مکان‌های ذخیره‌شده حذف می‌شوند. سوابق سفر برای دلایل قانونی نگه داشته می‌شود.", "ps": "ستاسو پروفایل او خوندي ځایونه به لرې شي. د سفر ریکارډونه د قانون لپاره پاتې کېږي."},
    "accountDeleted": {"en": "Your account has been deleted.", "fa": "حساب شما حذف شد.", "ps": "ستاسو حساب ړنګ شو."},
    "dataExported": {"en": "Your data file is ready.", "fa": "فایل داده‌های شما آماده است.", "ps": "ستاسو د معلوماتو فایل چمتو دی."},
    "sos": {"en": "SOS", "fa": "اضطراری", "ps": "بیړنی"},
    "sosConfirm": {"en": "Send your live location to emergency contacts?", "fa": "موقعیت فعلی به مخاطبان اضطراری ارسال شود؟", "ps": "ستاسو اوسنی ځای بیړنیو اړیکو ته واستول شي؟"},
    "sosSent": {"en": "Emergency alert sent.", "fa": "هشدار اضطراری ارسال شد.", "ps": "بیړنی خبرتیا ولېږل شوه."},
    "sosFailed": {"en": "Could not send SOS. Share your trip instead.", "fa": "ارسال اضطراری ممکن نشد. سفر را هم‌رسانی کنید.", "ps": "بیړنی پیغام ونه شو. خپل سفر شریک کړئ."},
    "sosNoContacts": {"en": "Add an emergency contact first.", "fa": "ابتدا یک مخاطب اضطراری اضافه کنید.", "ps": "لومړی یوه بیړنۍ اړیکه اضافه کړئ."},
    "sendSos": {"en": "Send SOS", "fa": "ارسال اضطراری", "ps": "بیړنی ولېږئ"},
    "yourTickets": {"en": "Your tickets", "fa": "درخواست‌های شما", "ps": "ستاسو ټکټونه"},
    "noTickets": {"en": "No support tickets yet", "fa": "هنوز درخواست پشتیبانی ندارید", "ps": "تر اوسه ملاتړ ټکټ نشته"},
    "reply": {"en": "Reply", "fa": "پاسخ", "ps": "ځواب"},
    "sendReply": {"en": "Send reply", "fa": "ارسال پاسخ", "ps": "ځواب ولېږئ"},
    "recentRatings": {"en": "Recent ratings", "fa": "امتیازهای اخیر", "ps": "وروستي امتیازونه"},
    "noRatingsYet": {"en": "No written ratings yet", "fa": "هنوز نظر کتبی ندارید", "ps": "تر اوسه لیکلي امتیاز نشته"},
    "lowRatingAlert": {"en": "Your rating is below the platform threshold. Focus on safe, on-time trips.", "fa": "امتیاز شما از حد آستانه کمتر است. روی سفرهای ایمن و به‌موقع تمرکز کنید.", "ps": "ستاسو امتیاز له حد څخه ښکته دی. پر خوندي او پر وخت سفرونو تمرکز وکړئ."},
    "highCancelAlert": {"en": "Your cancellation rate is high. Accepting more trips protects your account.", "fa": "نرخ لغو شما بالاست. قبول کردن سفرهای بیشتر از حساب شما محافظت می‌کند.", "ps": "ستاسو د لغوه کچه لوړه ده. ډېر سفرونه منل ستاسو حساب ساتي."},
    "typicalDriverRating": {"en": "Nearby drivers avg. {rating}", "fa": "میانگین رانندگان نزدیک {rating}", "ps": "نږدې چلوونکي منځنی {rating}"},
    "tooManyCancellations": {"en": "You have reached today’s cancellation limit. Try again tomorrow.", "fa": "به سقف لغو امروز رسیده‌اید. فردا دوباره تلاش کنید.", "ps": "د نن د لغوه حد ته رسېدلي یاست. سبا بیا هڅه وکړئ."},
    "markAllRead": {"en": "Mark read", "fa": "خوانده شد", "ps": "لوستل شوی"},
    "emergencyContactsCount": {"en": "{count} of {max} contacts", "fa": "{count} از {max} مخاطب", "ps": "{count} له {max} اړیکو"},
    "loadMore": {"en": "Load more", "fa": "بارگذاری بیشتر", "ps": "نور راوړئ"},
    "payoutMethod": {"en": "Payout method", "fa": "روش برداشت", "ps": "د تادیې لاره"},
    "payoutAccount": {"en": "Account number", "fa": "شماره حساب", "ps": "د حساب شمېره"},
    "savePayoutDetails": {"en": "Save payout details", "fa": "ذخیره جزئیات برداشت", "ps": "د تادیې جزئیات خوندي کړئ"},
    "payoutDetailsSaved": {"en": "Payout details saved", "fa": "جزئیات برداشت ذخیره شد", "ps": "د تادیې جزئیات خوندي شول"},
}

PLACEHOLDER_RE = re.compile(r"\{(\w+)\}")


def placeholders(text: str) -> dict[str, dict[str, str]]:
    names = PLACEHOLDER_RE.findall(text)
    return {name: {"type": "String"} for name in names}


def dart_literal(text: str) -> str:
    parts = PLACEHOLDER_RE.split(text)
    out: list[str] = []
    i = 0
    while i < len(parts):
        chunk = parts[i]
        escaped = (
            chunk.replace("\\", "\\\\")
            .replace("$", r"\$")
            .replace("'", r"\'")
            .replace("\n", r"\n")
            .replace("\r", r"\r")
        )
        out.append(escaped)
        if i + 1 < len(parts):
            out.append("${" + parts[i + 1] + "}")
            i += 2
        else:
            i += 1
    return "'" + "".join(out) + "'"


def method_name_and_params(key: str, en: str) -> tuple[str, list[str]]:
    params = PLACEHOLDER_RE.findall(en)
    # unique, preserve order
    seen: list[str] = []
    for p in params:
        if p not in seen:
            seen.append(p)
    return key, seen


def write_arb(path: Path, locale: str) -> None:
    data: dict = {"@@locale": locale}
    for key, langs in STRINGS.items():
        value = langs[locale]
        data[key] = value
        ph = placeholders(langs["en"])
        if ph:
            data[f"@{key}"] = {"placeholders": ph}
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_locale_impl(path: Path, locale: str, class_suffix: str) -> None:
    lines = [
        "// ignore: unused_import",
        "import 'package:intl/intl.dart' as intl;",
        "import 'app_localizations.dart';",
        "",
        "// ignore_for_file: type=lint",
        "",
        f"/// The translations for {locale} (`{locale}`).",
        f"class AppLocalizations{class_suffix} extends AppLocalizations {{",
        f"  AppLocalizations{class_suffix}([String locale = '{locale}']) : super(locale);",
        "",
    ]
    for key, langs in STRINGS.items():
        _, params = method_name_and_params(key, langs["en"])
        value = dart_literal(langs[locale])
        if params:
            sig = ", ".join(f"String {p}" for p in params)
            lines.append("  @override")
            lines.append(f"  String {key}({sig}) {{")
            lines.append(f"    return {value};")
            lines.append("  }")
            lines.append("")
        else:
            lines.append("  @override")
            lines.append(f"  String get {key} => {value};")
            lines.append("")
    lines.append("}")
    lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def write_abstract(path: Path) -> None:
    lines = [
        "import 'dart:async';",
        "",
        "import 'package:flutter/foundation.dart';",
        "import 'package:flutter/widgets.dart';",
        "import 'package:flutter_localizations/flutter_localizations.dart';",
        "import 'package:intl/intl.dart' as intl;",
        "",
        "import 'app_localizations_en.dart';",
        "import 'app_localizations_fa.dart';",
        "import 'app_localizations_ps.dart';",
        "",
        "// ignore_for_file: type=lint",
        "",
        "/// Callers can lookup localized strings with `AppLocalizations.of(context)`.",
        "abstract class AppLocalizations {",
        "  AppLocalizations(String locale)",
        "    : localeName = intl.Intl.canonicalizedLocale(locale.toString());",
        "",
        "  final String localeName;",
        "",
        "  static AppLocalizations of(BuildContext context) {",
        "    return Localizations.of<AppLocalizations>(context, AppLocalizations)",
        "        ?? lookupAppLocalizations(const Locale('en'));",
        "  }",
        "",
        "  static const LocalizationsDelegate<AppLocalizations> delegate =",
        "      _AppLocalizationsDelegate();",
        "",
        "  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =",
        "      <LocalizationsDelegate<dynamic>>[",
        "        delegate,",
        "        GlobalMaterialLocalizations.delegate,",
        "        GlobalCupertinoLocalizations.delegate,",
        "        GlobalWidgetsLocalizations.delegate,",
        "      ];",
        "",
        "  static const List<Locale> supportedLocales = <Locale>[",
        "    Locale('en'),",
        "    Locale('fa'),",
        "    Locale('ps'),",
        "  ];",
        "",
    ]
    for key, langs in STRINGS.items():
        _, params = method_name_and_params(key, langs["en"])
        if params:
            sig = ", ".join(f"String {p}" for p in params)
            lines.append(f"  String {key}({sig});")
            lines.append("")
        else:
            lines.append(f"  String get {key};")
            lines.append("")
    lines.extend(
        [
            "}",
            "",
            "class _AppLocalizationsDelegate",
            "    extends LocalizationsDelegate<AppLocalizations> {",
            "  const _AppLocalizationsDelegate();",
            "",
            "  @override",
            "  Future<AppLocalizations> load(Locale locale) {",
            "    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));",
            "  }",
            "",
            "  @override",
            "  bool isSupported(Locale locale) =>",
            "      <String>['en', 'fa', 'ps'].contains(locale.languageCode);",
            "",
            "  @override",
            "  bool shouldReload(_AppLocalizationsDelegate old) => false;",
            "}",
            "",
            "AppLocalizations lookupAppLocalizations(Locale locale) {",
            "  switch (locale.languageCode) {",
            "    case 'en':",
            "      return AppLocalizationsEn();",
            "    case 'fa':",
            "      return AppLocalizationsFa();",
            "    case 'ps':",
            "      return AppLocalizationsPs();",
            "  }",
            "",
            "  return AppLocalizationsEn();",
            "}",
            "",
        ]
    )
    path.write_text("\n".join(lines), encoding="utf-8")


def write_extension(path: Path) -> None:
    path.write_text(
        "import 'package:flutter/widgets.dart';\n"
        "import 'app_localizations.dart';\n"
        "\n"
        "extension RawanaL10nContext on BuildContext {\n"
        "  AppLocalizations get l10n => AppLocalizations.of(this);\n"
        "}\n"
        "\n"
        "extension RawanaL10nHelpers on AppLocalizations {\n"
        "  String tripStatusLabel(String apiValue) {\n"
        "    switch (apiValue) {\n"
        "      case 'searching':\n"
        "        return statusSearching;\n"
        "      case 'accepted':\n"
        "        return statusAccepted;\n"
        "      case 'driver_arriving':\n"
        "        return statusDriverArriving;\n"
        "      case 'trip_started':\n"
        "        return statusTripStarted;\n"
        "      case 'completed':\n"
        "        return statusCompleted;\n"
        "      case 'cancelled':\n"
        "        return statusCancelled;\n"
        "      default:\n"
        "        return apiValue.replaceAll('_', ' ');\n"
        "    }\n"
        "  }\n"
        "\n"
        "  String authError(String key, {String? detail}) {\n"
        "    switch (key) {\n"
        "      case 'supabase_not_configured':\n"
        "        return detail ?? authSupabaseNotConfigured;\n"
        "      case 'invalid_credentials':\n"
        "        return authInvalidCredentials;\n"
        "      case 'email_not_verified':\n"
        "        return authEmailNotVerified;\n"
        "      case 'email_already_exists':\n"
        "        return authEmailAlreadyExists;\n"
        "      case 'rate_limit':\n"
        "        return authRateLimit;\n"
        "      case 'database_signup_failed':\n"
        "        return authDatabaseSignupFailed;\n"
        "      case 'weak_password':\n"
        "        return authWeakPassword;\n"
        "      case 'invalid_email':\n"
        "        return authInvalidEmail;\n"
        "      case 'invalid_phone':\n"
        "        return authInvalidPhone;\n"
        "      case 'invalid_otp':\n"
        "        return authInvalidOtp;\n"
        "      case 'whatsapp_api_not_configured':\n"
        "        return authWhatsAppUnavailable;\n"
        "      default:\n"
        "        return detail ?? authGenericError;\n"
        "    }\n"
        "  }\n"
        "}\n",
        encoding="utf-8",
    )


def generate(out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    write_arb(out_dir / "app_en.arb", "en")
    write_arb(out_dir / "app_fa.arb", "fa")
    write_arb(out_dir / "app_ps.arb", "ps")
    write_abstract(out_dir / "app_localizations.dart")
    write_locale_impl(out_dir / "app_localizations_en.dart", "en", "En")
    write_locale_impl(out_dir / "app_localizations_fa.dart", "fa", "Fa")
    write_locale_impl(out_dir / "app_localizations_ps.dart", "ps", "Ps")
    write_extension(out_dir / "l10n_extensions.dart")
    print(f"Generated {len(STRINGS)} keys in {out_dir}")


def main() -> None:
    here = Path(__file__).resolve()
    # tool/ is inside passenger rawana_core
    passenger_l10n = here.parents[1] / "lib" / "l10n"
    generate(passenger_l10n)
    repo = here.parents[4]
    driver_l10n = repo / "driver_app" / "packages" / "rawana_core" / "lib" / "l10n"
    if driver_l10n.parent.exists():
        generate(driver_l10n)
        # also copy generator for the driver package
        driver_tool = repo / "driver_app" / "packages" / "rawana_core" / "tool"
        driver_tool.mkdir(exist_ok=True)
        target = driver_tool / "generate_l10n.py"
        if target.resolve() != here:
            target.write_text(here.read_text(encoding="utf-8"), encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main())
