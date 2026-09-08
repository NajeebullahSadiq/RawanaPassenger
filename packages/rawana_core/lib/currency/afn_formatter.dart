import 'package:intl/intl.dart';

/// Formats amounts in Afghan Afghani (AFN) — never USD.
class AfnFormatter {
  AfnFormatter._();

  static String format(num amount, {String locale = 'en'}) {
    final digits = amount == amount.roundToDouble() ? 0 : 2;
    if (locale == 'fa' || locale == 'ps') {
      return NumberFormat.currency(
        locale: 'fa_AF',
        symbol: '؋',
        decimalDigits: digits,
      ).format(amount);
    }
    return '${NumberFormat('#,##0${digits > 0 ? '.##' : ''}', 'en').format(amount)} AFN';
  }

  static String formatWithLabel(num amount, String locale) {
    return format(amount, locale: locale);
  }
}
