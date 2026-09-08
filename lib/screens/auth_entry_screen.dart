import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../utils/demo_login.dart';

class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen> {
  bool _demoLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        RawanaBrandMark.appIcon(size: 76),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: RawanaColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              context.l10n.riderBadge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.authEntryHeadline,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppConfig.useEmailAuthForTesting
                          ? context.l10n.signInEmailToTest
                          : context.l10n.authEntrySubtitle,
                      style: const TextStyle(
                        color: RawanaColors.onSurfaceMuted,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _ValuePropRow(
                      icon: LucideIcons.timer,
                      title: context.l10n.authValueFastTitle,
                      body: context.l10n.authValueFastBody,
                    ),
                    const SizedBox(height: 12),
                    _ValuePropRow(
                      icon: LucideIcons.shield,
                      title: context.l10n.authValueTrustedTitle,
                      body: context.l10n.authValueTrustedBody,
                    ),
                    const SizedBox(height: 12),
                    _ValuePropRow(
                      icon: LucideIcons.banknote,
                      title: context.l10n.authValuePayTitle,
                      body: context.l10n.authValuePayBody,
                    ),
                    const Spacer(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _AuthErrorBanner(message: _error!),
                    ],
                    if (AppConfig.useEmailAuthForTesting) ...[
                      const SizedBox(height: 16),
                      RawanaPrimaryButton(
                        label: context.l10n.continueWithEmail,
                        icon: LucideIcons.mail,
                        onPressed: () => context.push('/email-auth'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (AppConfig.enablePhoneOtp)
                      OutlinedButton.icon(
                        onPressed: () => context.push('/phone'),
                        icon: const Icon(LucideIcons.phone, size: 20),
                        label: Text(context.l10n.continueWithPhone),
                      )
                    else if (AppConfig.useEmailAuthForTesting)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          context.l10n.phoneOtpComingSoon,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: RawanaColors.onSurfaceFaint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      RawanaPrimaryButton(
                        label: context.l10n.continueWithPhone,
                        icon: LucideIcons.phone,
                        onPressed: () => context.push('/phone'),
                      ),
                    if (AppConfig.enableDemoLogin) ...[
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: Container(height: 1, color: RawanaColors.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.l10n.orDivider,
                            style: TextStyle(
                              color: RawanaColors.onSurfaceFaint,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: RawanaColors.divider)),
                      ]),
                      const SizedBox(height: 16),
                      DemoLoginButton(
                        loading: _demoLoading,
                        label: context.l10n.quickDemoAccess,
                        onPressed: () => performPassengerDemoLogin(
                          context: context,
                          ref: ref,
                          setLoading: (v) => setState(() => _demoLoading = v),
                          setError: (msg) => setState(() => _error = msg),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        context.l10n.authTermsFooter,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: RawanaColors.onSurfaceFaint,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValuePropRow extends StatelessWidget {
  const _ValuePropRow({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: RawanaColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: RawanaColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RawanaColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RawanaColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.triangleAlert, color: RawanaColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: RawanaColors.error,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
