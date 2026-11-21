import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_providers.dart';
import '../utils/auth_routing.dart';

class EmailVerifyScreen extends ConsumerWidget {
  const EmailVerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingEmailProvider);
    return RawanaEmailVerifyView(
      email: pending?.email,
      instructions: context.l10n.tapLinkThenContinue,
      onBackToSignIn: () => context.go('/email-auth'),
      onResend: () => ref.read(authServiceProvider).resendEmailVerification(pending!.email),
      onContinue: () async {
        final router = GoRouter.of(context);
        await ref
            .read(authServiceProvider)
            .completeEmailVerification(email: pending?.email, password: pending?.password);
        ref.read(pendingEmailProvider.notifier).state = null;
        final route = await passengerRouteAfterAuth(
          ref.read(passengerServiceProvider),
          ref.read(apiClientProvider),
        );
        router.go(route);
      },
    );
  }
}
