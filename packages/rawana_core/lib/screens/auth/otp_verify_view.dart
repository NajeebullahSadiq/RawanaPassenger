import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../auth/otp_channel.dart';
import '../../config/app_config.dart';
import '../../l10n/app_ui_l10n.dart';
import '../../l10n/l10n_extensions.dart';
import '../../theme/rawana_theme.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/ui/rawana_banner.dart';
import '../../widgets/ui/rawana_scaffold.dart';
import 'auth_failure.dart';

/// Code entry after [RawanaPhoneSignInView]. [onVerify] and [onResend] throw on failure.
class RawanaOtpVerifyView extends StatefulWidget {
  const RawanaOtpVerifyView({
    super.key,
    required this.phone,
    required this.channel,
    required this.onVerify,
    required this.onResend,
    this.onBack,
  });

  /// Null when the pending sign-in was lost (e.g. app restarted).
  final String? phone;
  final RawanaOtpChannel channel;
  final Future<void> Function(String code) onVerify;
  final Future<void> Function() onResend;
  final VoidCallback? onBack;

  @override
  State<RawanaOtpVerifyView> createState() => _RawanaOtpVerifyViewState();
}

class _RawanaOtpVerifyViewState extends State<RawanaOtpVerifyView> {
  static const _resendSeconds = 60;
  final _otpKey = GlobalKey<OtpInputState>();
  bool _hasError = false;
  bool _loading = false;
  int _countdown = _resendSeconds;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _countdown = (_countdown - 1).clamp(0, _resendSeconds));
      if (_countdown == 0) t.cancel();
    });
  }

  Future<void> _verify(String code) async {
    if (_loading) return;
    if (widget.phone == null) {
      setState(() => _error = context.l10n.otpSessionExpired);
      return;
    }
    setState(() {
      _loading = true;
      _hasError = false;
      _error = null;
    });
    try {
      await widget.onVerify(code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _error = rawanaAuthFailure(context, e);
      });
      _otpKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    _startCountdown();
    try {
      await widget.onResend();
    } catch (e) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _countdown = 0;
        _error = rawanaAuthFailure(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channelLabel =
        widget.channel == RawanaOtpChannel.whatsapp ? l10n.otpChannelWhatsApp : l10n.otpChannelSms;
    final phone = widget.phone;
    return RawanaScaffold(
      onBack: widget.onBack,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          RawanaPageHeader(
            icon: LucideIcons.shieldCheck,
            title: l10n.verificationCode,
            subtitle: phone != null && phone.isNotEmpty
                ? l10n.otpEnterCodeViaTo(channelLabel, '\u2066$phone\u2069')
                : l10n.otpEnterCodeVia(channelLabel),
          ),
          if (kDebugMode && AppConfig.devModeHint) ...[
            const SizedBox(height: 12),
            RawanaBanner(
              tone: RawanaBannerTone.warning,
              message: widget.channel == RawanaOtpChannel.whatsapp ? l10n.devOtpHintWhatsApp : l10n.devOtpHintSms,
            ),
          ],
          const SizedBox(height: 32),
          AbsorbPointer(
            absorbing: _loading,
            child: AnimatedOpacity(
              duration: RawanaMotion.fast,
              opacity: _loading ? 0.5 : 1,
              child: OtpInput(key: _otpKey, hasError: _hasError, onCompleted: _verify),
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text(l10n.verifyingCode, style: context.text.caption),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            RawanaBanner.error(message: _error!),
          ],
          const SizedBox(height: 28),
          Center(
            child: _countdown > 0
                ? Text(l10n.resendCodeInSeconds('$_countdown'), style: context.text.caption)
                : TextButton.icon(
                    onPressed: _resend,
                    icon: const Icon(LucideIcons.refreshCcw, size: 16),
                    label: Text(l10n.resendCode),
                  ),
          ),
          if (widget.onBack != null)
            Center(child: TextButton(onPressed: widget.onBack, child: Text(l10n.changeNumber))),
        ],
      ),
    );
  }
}
