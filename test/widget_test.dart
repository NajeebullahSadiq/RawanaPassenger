import 'package:flutter_test/flutter_test.dart';
import 'package:rawana_core/rawana_core.dart';

void main() {
  test('OTP widget exists', () {
    expect(OtpInput, isNotNull);
  });

  test('AFN fare display', () {
    expect(AfnFormatter.format(120), '120 AFN');
  });
}
