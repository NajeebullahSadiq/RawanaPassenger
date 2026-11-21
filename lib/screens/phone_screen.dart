import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/auth_provider.dart';

class PhoneScreen extends ConsumerWidget {
  const PhoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RawanaPhoneSignInView(
      title: context.l10n.enterYourPhone,
      subtitle: context.l10n.phoneVerifyHint,
      onBack: () => context.canPop() ? context.pop() : context.go('/auth'),
      onForgotPassword: () => context.push('/forgot-password?channel=sms'),
      onSendCode: (phone, channel) async {
        final router = GoRouter.of(context);
        await ref.read(authServiceProvider).sendPhoneOtp(phoneE164: phone, channel: channel);
        ref.read(pendingOtpProvider.notifier).state = (phone: phone, channel: channel);
        router.push('/otp');
      },
    );
  }
}
