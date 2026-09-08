import 'package:flutter_test/flutter_test.dart';
import 'package:rawana_core/utils/polyline_decoder.dart';

void main() {
  test('decodes Kabul route polyline', () {
    const encoded =
        '}ziqEsgydLs@MAEV}ADc@u@SiA_A{AQAcIS@Nq@Di@Co@c@}BYk@cAkIgKfBm@QFvCr@pOb@pHJ`CDpB';
    final points = decodePolyline(encoded);
    expect(points.length, greaterThan(2));
    for (final p in points) {
      expect(p.latitude, inInclusiveRange(34.0, 35.0));
      expect(p.longitude, inInclusiveRange(69.0, 70.0));
    }
  });

  test('decodes straight fallback line', () {
    const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
    final points = decodePolyline(encoded);
    expect(points.length, greaterThanOrEqualTo(2));
  });
}
