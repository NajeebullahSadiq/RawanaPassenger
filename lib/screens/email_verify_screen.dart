import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_providers.dart';
import '../utils/auth_routing.dart';

class EmailVerifyScreen extends ConsumerStatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  bool _loading = false;
  String? _message;
  bool _messageIsError = false;

  Future<void> _resend() async {
    final email = ref.read(pendingEmailProvider);
    if (email == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).resendEmailVerification(email);
      setState(() {
        _message = context.l10n.verificationEmailSent;
        _messageIsError = false;
      });
    } catch (e) {
      final message = context.l10n.friendlyApiError(e);
      setState(() {
        _message = message;
        _messageIsError = true;
      });
      if (mounted) showRawanaMessage(context, message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _continueAfterVerify() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.refreshSession();
      if (!mounted) return;
      final route = await passengerRouteAfterAuth(
        ref.read(passengerServiceProvider),
        ref.read(apiClientProvider),
      );
      if (!mounted) return;
      context.go(route);
    } catch (_) {
      setState(() {
        _message = context.l10n.emailNotVerifiedYet;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(pendingEmailProvider) ?? '';
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: RawanaCircleIconButton(
            icon: LucideIcons.arrowLeft,
            onPressed: () => context.go('/email-auth'),
            tooltip: context.l10n.back,
          ),
        ),
        leadingWidth: 56,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: RawanaColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: RawanaShadows.ctaGlow,
                  ),
                  child: const Icon(
                    LucideIcons.mailCheck,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.l10n.checkYourInbox,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: RawanaColors.onSurfaceMuted,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: context.l10n.weSentVerificationLinkTo),
                    TextSpan(
                      text: email.isEmpty ? context.l10n.yourEmailFallback : email,
                      style: const TextStyle(
                        color: RawanaColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: context.l10n.tapLinkThenContinue,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              if (_message != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (_messageIsError
                            ? RawanaColors.error
                            : RawanaColors.success)
                        .withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(RawanaSpacing.radiusMd),
                    border: Border.all(
                      color: (_messageIsError
                              ? RawanaColors.error
                              : RawanaColors.success)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _messageIsError
                            ? LucideIcons.triangleAlert
                            : LucideIcons.check,
                        size: 18,
                        color: _messageIsError
                            ? RawanaColors.error
                            : RawanaColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _messageIsError
                                ? RawanaColors.error
                                : RawanaColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              RawanaSurfaceCard(
                padding: const EdgeInsets.all(14),
                shadows: const [],
                border: Border.all(color: RawanaColors.divider),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: RawanaColors.warningSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.lightbulb,
                        color: RawanaColors.warning,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.checkSpamTip,
                        style: const TextStyle(
                          color: RawanaColors.onSurfaceMuted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RawanaPrimaryButton(
                label: context.l10n.iHaveVerifiedContinue,
                icon: LucideIcons.check,
                loading: _loading,
                onPressed: _continueAfterVerify,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _resend,
                icon: const Icon(LucideIcons.send, size: 18),
                label: Text(context.l10n.resendVerificationEmail),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/email-auth'),
                child: Text(context.l10n.backToSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
