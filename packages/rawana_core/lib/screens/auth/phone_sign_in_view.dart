import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../auth/otp_channel.dart';
import '../../l10n/l10n_extensions.dart';
import '../../theme/rawana_theme.dart';
import '../../widgets/rawana_primary_button.dart';
import '../../widgets/ui/rawana_banner.dart';
import '../../widgets/ui/rawana_icons.dart';
import '../../widgets/ui/rawana_scaffold.dart';
import '../../widgets/ui/rawana_text_field.dart';
import 'auth_failure.dart';

/// Phone number entry with SMS / WhatsApp choice. [onSendCode] throws on failure.
class RawanaPhoneSignInView extends StatefulWidget {
  const RawanaPhoneSignInView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSendCode,
    required this.onForgotPassword,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Future<void> Function(String phone, RawanaOtpChannel channel) onSendCode;
  final VoidCallback onForgotPassword;
  final VoidCallback? onBack;

  @override
  State<RawanaPhoneSignInView> createState() => _RawanaPhoneSignInViewState();
}

class _RawanaPhoneSignInViewState extends State<RawanaPhoneSignInView> {
  final _controller = TextEditingController();
  RawanaOtpChannel _channel = RawanaOtpChannel.sms;
  bool _loading = false;
  String? _error;

  bool get _valid {
    var digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.length == 9 && digits.startsWith('7');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_valid || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSendCode(_controller.text, _channel);
    } catch (e) {
      if (mounted) setState(() => _error = rawanaAuthFailure(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RawanaScaffold(
      onBack: widget.onBack,
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: _loading ? null : widget.onForgotPassword, child: Text(l10n.forgotPassword)),
          ),
          RawanaPrimaryButton(
            label: l10n.sendCode,
            icon: RawanaIcons.forward,
            loading: _loading,
            onPressed: _valid ? _send : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          RawanaPageHeader(icon: LucideIcons.phone, title: widget.title, subtitle: widget.subtitle),
          const SizedBox(height: 28),
          _ChannelSwitcher(channel: _channel, onChanged: (c) => setState(() => _channel = c)),
          const SizedBox(height: 20),
          RawanaPhoneField(
            controller: _controller,
            label: l10n.phoneNumberRequired,
            hint: l10n.phoneHint,
            autofocus: true,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _send(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            RawanaBanner.error(message: _error!),
          ],
        ],
      ),
    );
  }
}

class _ChannelSwitcher extends StatelessWidget {
  const _ChannelSwitcher({required this.channel, required this.onChanged});
  final RawanaOtpChannel channel;
  final ValueChanged<RawanaOtpChannel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: RawanaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
      ),
      child: Row(
        children: RawanaOtpChannel.values.map((c) {
          final selected = c == channel;
          final color = selected ? RawanaColors.primary : RawanaColors.onSurfaceMuted;
          final label = c == RawanaOtpChannel.sms ? context.l10n.otpChannelSms : context.l10n.otpChannelWhatsApp;
          return Expanded(
            child: Semantics(
              selected: selected,
              button: true,
              label: label,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(c),
                child: AnimatedContainer(
                  duration: RawanaMotion.fast,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
                    boxShadow: selected ? RawanaShadows.low : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        c == RawanaOtpChannel.sms ? LucideIcons.messageSquare : LucideIcons.messageCircle,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      ExcludeSemantics(child: Text(label, style: context.text.label.copyWith(color: color))),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
