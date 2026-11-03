import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/auth_provider.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  RawanaOtpChannel _channel = RawanaOtpChannel.sms;
  bool _loading = false;
  String? _error;

  bool get _valid => _controller.text.replaceAll(RegExp(r'\D'), '').length >= 9;

  Future<void> _sendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = _controller.text;
      await ref.read(authServiceProvider).sendPhoneOtp(
            phoneE164: phone,
            channel: _channel,
          );
      ref.read(pendingOtpProvider.notifier).state = (phone: phone, channel: _channel);
      if (mounted) context.go('/otp');
    } on RawanaAuthException catch (e) {
      final message = authErrorMessage(e.messageKey, l10n: context.l10n);
      setState(() => _error = message);
      if (mounted) showRawanaMessage(context, message);
    } catch (e) {
      setState(() => _error = context.l10n.friendlyApiError(e));
      showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RawanaCircleIconButton(
            icon: LucideIcons.arrowLeft,
            background: RawanaColors.surfaceAlt,
            iconColor: RawanaColors.onSurface,
            elevated: false,
            size: 40,
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: RawanaColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: RawanaColors.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  LucideIcons.phone,
                  color: RawanaColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.enterYourPhone,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: RawanaColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.phoneVerifyHint,
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              _ChannelSwitcher(
                channel: _channel,
                onChanged: (c) => setState(() => _channel = c),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: RawanaColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                    ),
                    child: Text(context.l10n.afPhonePrefix, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: context.l10n.phoneHint,
                        errorText: _error,
                      ),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              RawanaPrimaryButton(
                label: context.l10n.sendCode,
                icon: LucideIcons.arrowRight,
                loading: _loading,
                onPressed: _valid ? _sendCode : null,
              ),
            ],
          ),
        ),
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
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                      color: selected ? RawanaColors.primary : RawanaColors.onSurfaceMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c == RawanaOtpChannel.sms
                          ? context.l10n.otpChannelSms
                          : context.l10n.otpChannelWhatsApp,
                      style: TextStyle(
                        color: selected ? RawanaColors.primary : RawanaColors.onSurfaceMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
