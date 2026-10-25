import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';

class LocaleController extends StateNotifier<Locale> {
  LocaleController(super.state);

  Future<void> setLocale(Locale locale) async {
    state = LocaleStorage.resolve(locale.languageCode);
    RawanaLocale.apply(state);
    await LocaleStorage.save(state);
  }

  Future<void> applyFromProfile(String? language) async {
    if (language == null || language == state.languageCode) return;
    await setLocale(Locale(language));
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>(
  (ref) => LocaleController(const Locale('en')),
);
