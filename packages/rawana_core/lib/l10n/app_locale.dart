import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' show Intl;

import 'app_localizations.dart';
import 'html_direction.dart';
import 'locale_storage.dart';

/// Shared locale wiring for passenger and driver apps.
class RawanaLocale {
  static TextDirection textDirectionOf(Locale locale) =>
      LocaleStorage.isRtl(locale) ? TextDirection.rtl : TextDirection.ltr;

  /// Apply locale side effects that Flutter does not do on its own:
  /// [Intl] defaults and the web document `dir`/`lang`.
  static void apply(Locale locale) {
    final resolved = LocaleStorage.resolve(locale.languageCode);
    Intl.defaultLocale = resolved.languageCode;
    syncDocumentDirection(
      languageCode: resolved.languageCode,
      rtl: LocaleStorage.isRtl(resolved),
    );
  }

  /// Always honor the in-app language, not the device locale.
  static Locale resolutionCallback(
    Locale selected,
    Locale? device,
    Iterable<Locale> supported,
  ) {
    return LocaleStorage.resolve(selected.languageCode);
  }

  /// Cupertino has no Pashto bundle; fall back to Persian so `ps` still loads.
  static const List<LocalizationsDelegate<dynamic>> delegates =
      <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        _PashtoCupertinoLocalizationsDelegate(),
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];
}

class _PashtoCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _PashtoCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ps';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale('fa'));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) =>
      false;
}
