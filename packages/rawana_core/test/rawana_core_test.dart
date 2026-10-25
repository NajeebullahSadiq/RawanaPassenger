import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawana_core/rawana_core.dart';

void main() {
  test('AfnFormatter formats English locale', () {
    expect(AfnFormatter.format(1250), '1,250 AFN');
  });

  test('AfnFormatter never uses USD symbol', () {
    final formatted = AfnFormatter.format(100);
    expect(formatted.contains('\$'), false);
    expect(formatted.contains('USD'), false);
  });

  test('RawanaConstants uses AFN', () {
    expect(RawanaConstants.currencyCode, 'AFN');
    expect(RawanaConstants.defaultCountryCode, '+93');
  });

  test('Dari and Pashto themes use Bahij Zar', () {
    const bahij = 'packages/rawana_core/Bahij Zar';
    final rtl = RawanaTheme.light(isRtl: true);
    expect(rtl.textTheme.bodyLarge?.fontFamily, bahij);
    expect(rtl.textTheme.titleLarge?.fontFamily, bahij);
    expect(rtl.appBarTheme.titleTextStyle?.fontFamily, bahij);
    expect(rtl.snackBarTheme.contentTextStyle?.fontFamily, bahij);

    final ltr = RawanaTheme.light(isRtl: false);
    expect(ltr.textTheme.bodyLarge?.fontFamily, isNot(bahij));
    expect(ltr.textTheme.bodyLarge?.fontFamilyFallback, contains(bahij));
  });

  test('Dari and Pashto locales are RTL', () {
    expect(LocaleStorage.isRtl(const Locale('fa')), isTrue);
    expect(LocaleStorage.isRtl(const Locale('ps')), isTrue);
    expect(LocaleStorage.isRtl(const Locale('en')), isFalse);
    expect(RawanaLocale.textDirectionOf(const Locale('fa')), TextDirection.rtl);
    expect(RawanaLocale.textDirectionOf(const Locale('ps')), TextDirection.rtl);
    expect(RawanaLocale.textDirectionOf(const Locale('en')), TextDirection.ltr);
    expect(
      RawanaLocale.resolutionCallback(
        const Locale('ps'),
        const Locale('en', 'US'),
        AppLocalizations.supportedLocales,
      ),
      const Locale('ps'),
    );
  });

  testWidgets('Dari MaterialApp resolves RTL and Dari strings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: RawanaLocale.delegates,
        localeResolutionCallback: (device, supported) =>
            RawanaLocale.resolutionCallback(const Locale('fa'), device, supported),
        builder: (context, child) => Directionality(
          textDirection: RawanaLocale.textDirectionOf(const Locale('fa')),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) => Text(context.l10n.chooseYourLanguage),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('زبان خود را انتخاب کنید'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('زبان خود را انتخاب کنید'))),
      TextDirection.rtl,
    );
  });

  testWidgets('Pashto MaterialApp resolves RTL and Pashto strings', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ps'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: RawanaLocale.delegates,
        localeResolutionCallback: (device, supported) =>
            RawanaLocale.resolutionCallback(const Locale('ps'), device, supported),
        builder: (context, child) => Directionality(
          textDirection: RawanaLocale.textDirectionOf(const Locale('ps')),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) => Text(context.l10n.chooseYourLanguage),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('خپله ژبه وټاکئ'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('خپله ژبه وټاکئ'))),
      TextDirection.rtl,
    );
  });

  test('Dari and Pashto UI strings differ from English', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fa = lookupAppLocalizations(const Locale('fa'));
    final ps = lookupAppLocalizations(const Locale('ps'));
    expect(fa.whereTo, isNot(en.whereTo));
    expect(ps.whereTo, isNot(en.whereTo));
    expect(fa.chooseYourLanguage, isNot(en.chooseYourLanguage));
    expect(ps.chooseYourLanguage, isNot(en.chooseYourLanguage));
    expect(en.languageName('fa'), 'دری');
  });

  test('map marker geometry ignores localized labels', () {
    const en = RawanaMapMarker(
      lat: 34.5553,
      lng: 69.2075,
      id: 'pickup',
      label: 'Pickup',
    );
    const fa = RawanaMapMarker(
      lat: 34.5553,
      lng: 69.2075,
      id: 'pickup',
      label: 'سوار شدن',
    );
    expect(en.sameGeometry(fa), isTrue);
    expect(RawanaMapMarker.sameGeometryList([en], [fa]), isTrue);
    expect(
      en.sameGeometry(const RawanaMapMarker(
        lat: 34.56,
        lng: 69.2075,
        id: 'pickup',
        label: 'Pickup',
      )),
      isFalse,
    );
  });

  testWidgets('LtrMapSurface keeps maps LTR under an RTL app', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: LtrMapSurface(
          child: SizedBox(key: Key('map-host')),
        ),
      ),
    );
    final nearest = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.byKey(const Key('map-host')),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(nearest.textDirection, TextDirection.ltr);
  });

  test('whatsappPhoneDigits normalizes Afghan numbers', () {
    expect(whatsappPhoneDigits('+93 70 123 4567'), '93701234567');
    expect(whatsappPhoneDigits('0701234567'), '93701234567');
    expect(whatsappPhoneDigits('701234567'), '93701234567');
    expect(whatsappPhoneDigits('0093701234567'), '93701234567');
    expect(whatsappPhoneDigits(null), isNull);
    expect(whatsappPhoneDigits(''), isNull);
  });
}
