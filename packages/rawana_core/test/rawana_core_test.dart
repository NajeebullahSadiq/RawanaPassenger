import 'package:flutter/widgets.dart';
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
