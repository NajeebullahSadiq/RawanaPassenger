import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's language across launches.
class LocaleStorage {
  static const prefsKey = 'rawana_locale';
  static const supportedCodes = ['en', 'fa', 'ps'];

  static bool isRtl(Locale locale) =>
      locale.languageCode == 'fa' || locale.languageCode == 'ps';

  static Locale resolve(String? code) {
    if (code != null && supportedCodes.contains(code)) {
      return Locale(code);
    }
    return const Locale('en');
  }

  static Future<Locale> load() async {
    final prefs = await SharedPreferences.getInstance();
    return resolve(prefs.getString(prefsKey));
  }

  static Future<void> save(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, locale.languageCode);
  }
}
