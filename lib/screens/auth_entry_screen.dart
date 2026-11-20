import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../utils/demo_login.dart';

class AuthEntryScreen extends ConsumerWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return RawanaAuthEntryView(
      badge: l10n.riderBadge,
      headline: l10n.authEntryHeadline,
      subtitle: l10n.authEntrySubtitle,
      valueProps: [
        RawanaValueProp(icon: LucideIcons.timer, title: l10n.authValueFastTitle, body: l10n.authValueFastBody),
        RawanaValueProp(icon: LucideIcons.shield, title: l10n.authValueTrustedTitle, body: l10n.authValueTrustedBody),
        RawanaValueProp(icon: LucideIcons.banknote, title: l10n.authValuePayTitle, body: l10n.authValuePayBody),
      ],
      onPhone: () => context.push('/phone'),
      onEmail: () => context.push('/email-auth'),
      onForgotPassword: () => context.push('/forgot-password'),
      onTerms: () => context.push('/terms'),
      onPrivacy: () => context.push('/privacy-policy'),
      onDemoLogin: () => passengerDemoLogin(context, ref),
    );
  }
}
