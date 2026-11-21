import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';

import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_providers.dart';
import '../utils/auth_routing.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key, this.initialSms = false});

  final bool initialSms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ForgotPasswordForm(
      auth: ref.read(authServiceProvider),
      initialSms: initialSms,
      onSignedIn: () async {
        await syncBackendProfile(ref.read(apiClientProvider));
        final route = await passengerRouteAfterAuth(
          ref.read(passengerServiceProvider),
          ref.read(apiClientProvider),
        );
        if (context.mounted) context.go(route);
      },
    );
  }
}
