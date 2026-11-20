import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/trip_providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  Future<void> _syncProfile(WidgetRef ref, String code) async {
    if (!ref.read(isAppLoggedInProvider)) return;
    try {
      await ref.read(passengerServiceProvider).updateProfile(language: code);
    } catch (_) {
      // The locale is already saved on the device; the server copy only drives push copy.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RawanaLanguageView(
      current: ref.watch(localeProvider).languageCode,
      onSelect: (code) async {
        await ref.read(localeProvider.notifier).setLocale(Locale(code));
        await _syncProfile(ref, code);
      },
      onContinue: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(ref.read(isAppLoggedInProvider) ? '/home' : '/auth');
      },
    );
  }
}
