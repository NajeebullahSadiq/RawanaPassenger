import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_providers.dart';
import '../utils/auth_routing.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  bool _error = false;
  bool _loading = false;
  int _countdown = 60;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown = (_countdown - 1).clamp(0, 60));
      return _countdown > 0;
    });
  }

  Future<void> _verify(String code) async {
    final pending = ref.read(pendingOtpProvider);
    if (pending == null) {
      setState(() => _errorMessage = context.l10n.otpSessionExpired);
      return;
    }
    setState(() {
      _loading = true;
      _error = false;
      _errorMessage = null;
    });
    try {
      await ref.read(authServiceProvider).verifyPhoneOtp(
            phoneE164: pending.phone,
            code: code,
            channel: pending.channel,
          );
      final route = await passengerRouteAfterAuth(
        ref.read(passengerServiceProvider),
        ref.read(apiClientProvider),
      );
      if (mounted) context.go(route);
    } on RawanaAuthException catch (e) {
      setState(() {
        _error = true;
        _errorMessage = authErrorMessage(e.messageKey, detail: e.message, l10n: context.l10n);
      });
    } catch (e) {
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final pending = ref.read(pendingOtpProvider);
    if (pending == null) return;
    setState(() => _countdown = 60);
    _startCountdown();
    await ref.read(authServiceProvider).sendPhoneOtp(
          phoneE164: pending.phone,
          channel: pending.channel,
        );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingOtpProvider);
    final channelLabel = pending?.channel == RawanaOtpChannel.whatsapp
        ? context.l10n.otpChannelWhatsApp
        : context.l10n.otpChannelSms;
    final maskedPhone = pending?.phone ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: RawanaColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(LucideIcons.shieldCheck, color: RawanaColors.primary, size: 28),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.verificationCode,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                maskedPhone.isNotEmpty
                    ? context.l10n.otpEnterCodeViaTo(channelLabel, maskedPhone)
                    : context.l10n.otpEnterCodeVia(channelLabel),
                style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 15, height: 1.5),
              ),
              if (AppConfig.devModeHint) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RawanaColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 14, color: RawanaColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pending?.channel == RawanaOtpChannel.whatsapp
                              ? 'Dev WhatsApp code: 123456'
                              : 'Check Supabase SMS / inbox',
                          style: const TextStyle(fontSize: 12, color: RawanaColors.onSurfaceMuted, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                OtpInput(hasError: _error, onCompleted: _verify),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(LucideIcons.triangleAlert, color: RawanaColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: RawanaColors.error, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Center(
                child: _countdown > 0
                    ? Text(
                        context.l10n.resendCodeInSeconds('$_countdown'),
                        style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontWeight: FontWeight.w500),
                      )
                    : TextButton.icon(
                        onPressed: _resend,
                        icon: const Icon(LucideIcons.refreshCcw, size: 16),
                        label: Text(context.l10n.resendCode),
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
