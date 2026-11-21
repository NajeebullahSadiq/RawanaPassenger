import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_providers.dart';
import '../utils/auth_routing.dart';

class OtpScreen extends ConsumerWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingOtpProvider);
    return RawanaOtpVerifyView(
      phone: pending?.phone,
      channel: pending?.channel ?? RawanaOtpChannel.sms,
      onBack: () => context.canPop() ? context.pop() : context.go('/phone'),
      onVerify: (code) async {
        final router = GoRouter.of(context);
        await ref.read(authServiceProvider).verifyPhoneOtp(
              phoneE164: pending!.phone,
              code: code,
              channel: pending.channel,
            );
        final route = await passengerRouteAfterAuth(
          ref.read(passengerServiceProvider),
          ref.read(apiClientProvider),
        );
        router.go(route);
      },
      onResend: () async {
        if (pending == null) return;
        await ref.read(authServiceProvider).sendPhoneOtp(phoneE164: pending.phone, channel: pending.channel);
      },
    );
  }
}
