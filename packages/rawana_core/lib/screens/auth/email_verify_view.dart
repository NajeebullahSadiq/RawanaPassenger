import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n_extensions.dart';
import '../../theme/rawana_theme.dart';
import '../../widgets/rawana_primary_button.dart';
import '../../widgets/ui/rawana_banner.dart';
import '../../widgets/ui/rawana_scaffold.dart';
import 'auth_failure.dart';

/// "Check your inbox" step after an email sign-up that needs confirmation.
class RawanaEmailVerifyView extends StatefulWidget {
  const RawanaEmailVerifyView({
    super.key,
    required this.email,
    required this.instructions,
    required this.onContinue,
    required this.onResend,
    required this.onBackToSignIn,
  });

  final String? email;

  /// Text after the address, e.g. "Tap the link, then come back and continue."
  final String instructions;

  /// Throws when the address is still unverified.
  final Future<void> Function() onContinue;
  final Future<void> Function() onResend;
  final VoidCallback onBackToSignIn;

  @override
  State<RawanaEmailVerifyView> createState() => _RawanaEmailVerifyViewState();
}

class _RawanaEmailVerifyViewState extends State<RawanaEmailVerifyView> {
  bool _loading = false;
  bool _resending = false;
  String? _message;
  bool _isError = false;

  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await widget.onContinue();
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = context.l10n.emailNotVerifiedYet;
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await widget.onResend();
      if (mounted) {
        setState(() {
          _message = context.l10n.verificationEmailSent;
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = rawanaAuthFailure(context, e);
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = widget.email;
    return RawanaScaffold(
      onBack: widget.onBackToSignIn,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawanaPrimaryButton(
            label: l10n.iHaveVerifiedContinue,
            icon: LucideIcons.check,
            loading: _loading,
            onPressed: _resending ? null : _continue,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loading || _resending || email == null ? null : _resend,
            icon: _resending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.send, size: 18),
            label: Text(l10n.resendVerificationEmail),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: RawanaColors.primaryGradient,
                borderRadius: BorderRadius.circular(RawanaSpacing.radiusXl - 4),
                boxShadow: RawanaShadows.ctaGlow,
              ),
              child: const Icon(LucideIcons.mailCheck, color: Colors.white, size: 42),
            ),
          ),
          const SizedBox(height: 28),
          Text(l10n.checkYourInbox, textAlign: TextAlign.center, style: context.text.display),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: context.text.body.copyWith(color: RawanaColors.onSurfaceMuted),
              children: [
                TextSpan(text: l10n.weSentVerificationLinkTo),
                TextSpan(
                  text: email == null || email.isEmpty ? l10n.yourEmailFallback : '\u2066$email\u2069',
                  style: context.text.bodyStrong,
                ),
                TextSpan(text: widget.instructions),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          if (_message != null) ...[
            const SizedBox(height: 18),
            RawanaBanner(message: _message!, tone: _isError ? RawanaBannerTone.error : RawanaBannerTone.success),
          ],
          const SizedBox(height: 24),
          RawanaBanner(tone: RawanaBannerTone.warning, icon: LucideIcons.lightbulb, message: l10n.checkSpamTip),
        ],
      ),
    );
  }
}
