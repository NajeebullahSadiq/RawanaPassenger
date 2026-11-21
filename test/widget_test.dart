import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/screens/auth_entry_screen.dart';
import 'package:passenger_app/screens/onboarding_screen.dart';
import 'package:rawana_core/rawana_core.dart';

Future<void> _pumpLocalized(WidgetTester tester, Widget screen, Locale locale) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      locale: locale,
      theme: RawanaTheme.light(isRtl: LocaleStorage.isRtl(locale)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: RawanaLocale.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: Directionality(
          textDirection: RawanaLocale.textDirectionOf(locale),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: screen,
    ),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  test('AFN fare display', () {
    expect(AfnFormatter.format(120), '120 AFN');
  });

  for (final locale in const [Locale('fa'), Locale('ps'), Locale('en')]) {
    testWidgets('onboarding lays out in ${locale.languageCode} at large text', (tester) async {
      await _pumpLocalized(tester, const OnboardingScreen(), locale);
      final l10n = lookupAppLocalizations(locale);
      expect(find.text(l10n.onboardingSlide1Title), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text(l10n.onboardingSlide1Title))),
        RawanaLocale.textDirectionOf(locale),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('auth entry lays out in ${locale.languageCode} at large text', (tester) async {
      await _pumpLocalized(tester, const AuthEntryScreen(), locale);
      expect(find.text(lookupAppLocalizations(locale).authEntryHeadline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
