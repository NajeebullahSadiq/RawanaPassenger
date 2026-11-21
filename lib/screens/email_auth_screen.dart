import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/trip_providers.dart';
import '../utils/auth_routing.dart';
import '../utils/demo_login.dart';

class EmailAuthScreen extends ConsumerWidget {
  const EmailAuthScreen({super.key, this.startAsSignUp = false});

  final bool startAsSignUp;

  Future<void> _goAfterAuth(WidgetRef ref, GoRouter router) async {
    final route = await passengerRouteAfterAuth(
      ref.read(passengerServiceProvider),
      ref.read(apiClientProvider),
    );
    router.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RawanaEmailAuthView(
      startAsSignUp: startAsSignUp,
      copy: RawanaEmailAuthCopy(
        signInTitle: l10n.welcomeBack,
        signInSubtitle: l10n.signInSubtitle,
        signUpTitle: l10n.createAccount,
        signUpSubtitle: l10n.signUpSubtitle,
        signUpButton: l10n.createAccount,
        switchToSignIn: l10n.alreadyHaveAccount,
        switchToSignUp: l10n.newHereCreateAccount,
      ),
      languageCode: ref.watch(localeProvider).languageCode,
      onLanguageChanged: (code) => ref.read(localeProvider.notifier).setLocale(Locale(code)),
      onBack: () => context.canPop() ? context.pop() : context.go('/auth'),
      onForgotPassword: () => context.push('/forgot-password'),
      onDemoLogin: () => passengerDemoLogin(context, ref),
      onSignIn: (email, password) async {
        final router = GoRouter.of(context);
        try {
          await ref.read(authServiceProvider).signInWithEmail(email: email, password: password);
        } on RawanaAuthException catch (e) {
          if (e.messageKey != 'email_not_verified') rethrow;
          ref.read(pendingEmailProvider.notifier).state = (email: email, password: password);
          router.go('/email-verify');
          return;
        }
        await _goAfterAuth(ref, router);
      },
      onSignUp: ({required name, required phone, required email, required password}) async {
        final router = GoRouter.of(context);
        final auth = ref.read(authServiceProvider);
        final response = await auth.signUpWithEmail(
          email: email,
          password: password,
          role: 'passenger',
          name: name,
          phone: phone,
        );
        if (response.session == null) {
          // Supabase "Confirm email" is on: the account exists but must be verified first.
          ref.read(pendingEmailProvider.notifier).state = (email: email, password: password);
          router.go('/email-verify');
          return;
        }
        await syncBackendProfile(ref.read(apiClientProvider));
        await ref.read(passengerServiceProvider).updateProfile(
              name: name,
              phone: phone,
              email: email,
              language: ref.read(localeProvider).languageCode,
            );
        await _goAfterAuth(ref, router);
      },
    );
  }
}
