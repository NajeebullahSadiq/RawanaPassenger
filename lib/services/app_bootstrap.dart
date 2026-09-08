import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_providers.dart';
import '../router.dart';
import 'connectivity_service.dart';
import 'push_setup.dart';

class AppBootstrap extends ConsumerStatefulWidget {
  final Widget child;
  const AppBootstrap({super.key, required this.child});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    ConnectivityService.init((connected) {
      ref.read(connectivityProvider.notifier).state = connected;
    });
    if (AppConfig.hasSupabase) {
      // Supabase is initialized in main() before runApp so splash can see
      // the restored session. Here we only wire API tokens + listeners.
      await ref.read(authServiceProvider).ensureValidSession();
      final session = Supabase.instance.client.auth.currentSession;
      ref.read(apiClientProvider.notifier).state = ApiClient(
        baseUrl: AppConfig.apiBaseUrl,
        token: session?.accessToken,
      );
      Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        ref.read(apiClientProvider).setToken(event.session?.accessToken);
        if (event.session != null) {
          syncBackendProfile(ref.read(apiClientProvider));
        }
      });
    } else {
      ref.read(apiClientProvider.notifier).state = ApiClient(
        baseUrl: AppConfig.apiBaseUrl,
      );
    }
    if (ref.read(isAppLoggedInProvider)) {
      await syncBackendProfile(ref.read(apiClientProvider));
      await _setupPush();
    }
  }

  Future<void> _setupPush() async {
    await setupPushNotifications(
      ref: ref,
      router: appRouter,
      registerToken: (token) => ref.read(passengerServiceProvider).registerFcmToken(token),
      onTripEvent: () => ref.read(activeTripProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isAppLoggedInProvider, (prev, loggedIn) async {
      if (loggedIn == true && prev != true) {
        await syncBackendProfile(ref.read(apiClientProvider));
        await _setupPush();
      }
    });
    return widget.child;
  }
}
