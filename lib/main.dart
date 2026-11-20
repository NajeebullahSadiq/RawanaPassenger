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
  AppConfig.assertReleaseConfig();
  LocationService.autoRequest = false;
  final savedLocale = await LocaleStorage.load();
  RawanaLocale.apply(savedLocale);
  await ensureGoogleMapsScriptLoaded(AppConfig.googleMapsWebApiKey);
  final firebaseReady = await initializeFirebaseApp(options: DefaultFirebaseOptions.currentPlatform);
  await CrashReporting.install(firebaseReady: firebaseReady);
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
        localizationsDelegates: RawanaLocale.delegates,
        localeResolutionCallback: (device, supported) =>
            RawanaLocale.resolutionCallback(locale, device, supported),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            // Large system fonts beyond 1.3x break fixed-height map sheets.
            data: media.copyWith(textScaler: media.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3)),
            child: Directionality(
              textDirection: RawanaLocale.textDirectionOf(locale),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        routerConfig: appRouter,
      ),
    );
  }
}