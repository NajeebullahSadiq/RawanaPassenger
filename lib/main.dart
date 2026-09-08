import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'providers/locale_provider.dart';
import 'services/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load runtime config from `.env` BEFORE Firebase / Supabase so the keys are
  // available to AppConfig getters during bootstrap.
  await RawanaEnv.load();
  final savedLocale = await LocaleStorage.load();
  await ensureGoogleMapsScriptLoaded(AppConfig.googleMapsWebApiKey);
  await initializeFirebaseApp(options: DefaultFirebaseOptions.currentPlatform);
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => LocaleController(savedLocale)),
    ],
    child: const PassengerApp(),
  ));
}

class PassengerApp extends ConsumerWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isRtl = LocaleStorage.isRtl(locale);
    final l10n = lookupAppLocalizations(locale);

    return AppBootstrap(
      child: MaterialApp.router(
        title: l10n.appTitlePassenger,
        debugShowCheckedModeBanner: false,
        theme: RawanaTheme.light(isRtl: isRtl),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}