import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

import '../utils/auth_routing.dart';

import '../providers/trip_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  PlatformBlock? _block;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future<void> resolve() async {
      // Let the splash animation show briefly, then restore session.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      try {
        final settings = await PlatformSettingsService(ref.read(apiClientProvider)).fetch();
        final info = await PackageInfo.fromPlatform();
        final block = evaluatePlatformGate(
          settings: settings,
          appVersion: info.version,
          ios: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
          driverApp: false,
        );
        if (block != null && mounted) {
          setState(() => _block = block);
          return;
        }
      } catch (_) {}
      if (!mounted) return;
      final loggedIn = await ref.read(authServiceProvider).ensureValidSession();
      if (!loggedIn && !ref.read(isAppLoggedInProvider)) {
        if (mounted) context.go('/onboarding');
        return;
      }
      final token = ref.read(authServiceProvider).session?.accessToken;
      if (token != null) {
        ref.read(apiClientProvider).setToken(token);
      }
      try {
        final profile = await ref.read(passengerServiceProvider).getProfile();
        await ref.read(localeProvider.notifier).applyFromProfile(
              profile['language'] as String?,
            );
      } catch (_) {}
      await ref.read(activeTripProvider.notifier).refresh();
      if (!mounted) return;
      final trip = ref.read(activeTripProvider).valueOrNull;
      if (trip != null) {
        switch (trip.status) {
          case TripStatus.searching:
            context.go('/searching');
          case TripStatus.accepted:
          case TripStatus.driverArriving:
          case TripStatus.tripStarted:
            context.go('/active-trip');
          case TripStatus.completed:
            context.go('/trip-complete');
          case TripStatus.cancelled:
          case TripStatus.scheduled:
            context.go('/home');
        }
      } else {
        final route = await passengerRouteAfterAuth(
          ref.read(passengerServiceProvider),
          ref.read(apiClientProvider),
        );
        if (mounted) context.go(route);
      }
    }

    unawaited(resolve());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_block != null) return PlatformBlockedScreen(block: _block!);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: RawanaColors.inkGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative glow
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RawanaColors.primaryBright.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                bottom: -160,
                left: -60,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: RawanaColors.accent.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RawanaBrandMark.appIcon(size: 112),
                        const SizedBox(height: 28),
                        Text(
                          context.l10n.appName,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.splashTagline,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.splashLoading,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
