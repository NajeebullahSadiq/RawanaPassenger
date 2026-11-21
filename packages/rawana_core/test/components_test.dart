import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rawana_core/rawana_core.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    theme: RawanaTheme.light(isRtl: LocaleStorage.isRtl(locale)),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: RawanaLocale.delegates,
    builder: (context, child) => Directionality(
      textDirection: RawanaLocale.textDirectionOf(locale),
      child: child ?? const SizedBox.shrink(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('RawanaAsyncBody', () {
    Widget body({List<String>? data, Object? error, VoidCallback? onRetry}) {
      return _app(RawanaAsyncBody<List<String>>(
        data: data,
        error: error,
        onRetry: onRetry,
        isEmpty: (d) => d.isEmpty,
        empty: const Text('nothing here'),
        skeleton: const Text('loading'),
        builder: (context, d) => ListView(children: [for (final s in d) Text(s)]),
      ));
    }

    testWidgets('shows the skeleton while loading', (tester) async {
      await tester.pumpWidget(body());
      expect(find.text('loading'), findsOneWidget);
    });

    testWidgets('shows a retry on error and calls onRetry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(body(error: Exception('boom'), onRetry: () => retried++));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
    });

    testWidgets('shows the empty state for empty data', (tester) async {
      await tester.pumpWidget(body(data: const []));
      await tester.pumpAndSettle();
      expect(find.text('nothing here'), findsOneWidget);
    });

    testWidgets('keeps stale data visible when a refresh fails', (tester) async {
      await tester.pumpWidget(body(data: const ['Kabul'], error: Exception('offline')));
      await tester.pumpAndSettle();
      expect(find.text('Kabul'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });
  });

  group('RawanaSettingsTile', () {
    testWidgets('shows a chevron only when tappable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(RawanaSettingsSection(children: [
        RawanaSettingsTile(icon: Icons.person, title: 'Profile', value: 'Najib', onTap: () => taps++),
        const RawanaSettingsTile(icon: Icons.info, title: 'Version'),
      ])));
      expect(find.byIcon(RawanaIcons.chevronForward), findsOneWidget);
      expect(find.text('Najib'), findsOneWidget);
      await tester.tap(find.text('Profile'));
      expect(taps, 1);
    });

    testWidgets('mirrors the chevron in Dari', (tester) async {
      await tester.pumpWidget(_app(
        RawanaSettingsTile(icon: Icons.person, title: 'پروفایل', onTap: () {}),
        locale: const Locale('fa'),
      ));
      await tester.pumpAndSettle();
      final chevron = find.byIcon(RawanaIcons.chevronForward);
      expect(Directionality.of(tester.element(chevron)), TextDirection.rtl);
      expect(RawanaIcons.chevronForward.matchTextDirection, isTrue);
      final title = tester.getCenter(find.text('پروفایل'));
      expect(tester.getCenter(chevron).dx, lessThan(title.dx));
    });
  });

  group('OtpInput', () {
    testWidgets('spreads a pasted code and completes', (tester) async {
      String? completed;
      await tester.pumpWidget(_app(OtpInput(onCompleted: (c) => completed = c, autofocus: false)));
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.pump();
      expect(completed, '123456');
    });

    testWidgets('stays left-to-right under an RTL locale', (tester) async {
      await tester.pumpWidget(_app(
        OtpInput(onCompleted: (_) {}, autofocus: false),
        locale: const Locale('ps'),
      ));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      expect(Directionality.of(tester.element(fields.first)), TextDirection.ltr);
      expect(tester.getCenter(fields.first).dx, lessThan(tester.getCenter(fields.last).dx));
    });
  });

  testWidgets('StarRating reports the tapped star', (tester) async {
    int? picked;
    await tester.pumpWidget(_app(StarRating(value: 0, onChanged: (v) => picked = v)));
    await tester.tap(find.byType(StarIcon).at(3));
    expect(picked, 4);
  });
}
