import 'package:flutter/material.dart';

import '../auth/auth_error_messages.dart';
import '../auth/auth_exception.dart';
import '../auth/auth_service.dart';
import '../auth/otp_channel.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/profile_registration.dart';
import '../widgets/rawana_primary_button.dart';
import '../widgets/show_rawana_error.dart';

/// Login recovery by email link/code or SMS code, then a new password.
class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({
    super.key,
    required this.auth,
    required this.onSignedIn,
    this.initialSms = false,
  });

  final AuthService auth;
  final bool initialSms;

  /// Called after a code reset creates a session and the new password is saved.
  final Future<void> Function() onSignedIn;

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

enum _ResetChannel { email, sms }

enum _ResetStep { identify, code, password, emailSent }

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _identityController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _ResetChannel _channel = _ResetChannel.email;
  _ResetStep _step = _ResetStep.identify;
  bool _loading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialSms) _channel = _ResetChannel.sms;
  }

  @override
  void dispose() {
    _identityController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_channel == _ResetChannel.email) {
        final needsCode = await widget.auth.sendEmailPasswordReset(_identityController.text);
        if (!mounted) return;
        setState(() => _step = needsCode ? _ResetStep.code : _ResetStep.emailSent);
      } else {
        await widget.auth.sendPhonePasswordReset(
          normalizeAfPhoneInput(_identityController.text),
        );
        if (!mounted) return;
        setState(() => _step = _ResetStep.code);
      }
    } on RawanaAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e.messageKey, l10n: context.l10n));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_channel == _ResetChannel.email) {
        await widget.auth.verifyEmailRecoveryCode(
          email: _identityController.text,
          code: _codeController.text.trim(),
        );
      } else {
        await widget.auth.verifyPhoneOtp(
          phoneE164: normalizeAfPhoneInput(_identityController.text),
          code: _codeController.text.trim(),
          channel: RawanaOtpChannel.sms,
        );
      }
      if (!mounted) return;
      setState(() => _step = _ResetStep.password);
    } on RawanaAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e.messageKey, l10n: context.l10n));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _error = context.l10n.passwordMinEightChars);
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = context.l10n.passwordsDoNotMatch);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.updatePassword(password);
      if (!mounted) return;
      showRawanaMessage(context, context.l10n.passwordResetSignIn);
      await widget.onSignedIn();
    } on RawanaAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e.messageKey, l10n: context.l10n));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.l10n.friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identityReady = _channel == _ResetChannel.email
        ? _identityController.text.contains('@')
        : isRegistrationPhoneValid(normalizeAfPhoneInput(_identityController.text));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              l10n.resetPasswordHint,
              style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),
            SegmentedButton<_ResetChannel>(
              segments: [
                ButtonSegment(value: _ResetChannel.email, label: Text(l10n.resetByEmail), icon: const Icon(Icons.mail_outline_rounded, size: 16)),
                ButtonSegment(value: _ResetChannel.sms, label: Text(l10n.resetBySms), icon: const Icon(Icons.sms_outlined, size: 16)),
              ],
              selected: {_channel},
              onSelectionChanged: _loading || _step != _ResetStep.identify
                  ? null
                  : (value) => setState(() {
                        _channel = value.first;
                        _error = null;
                      }),
            ),
            const SizedBox(height: 20),
            if (_step == _ResetStep.identify) ...[
              TextField(
                controller: _identityController,
                keyboardType: _channel == _ResetChannel.email
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _channel == _ResetChannel.email ? l10n.emailLabel : l10n.phoneNumberRequired,
                  prefixIcon: Icon(
                    _channel == _ResetChannel.email ? Icons.mail_outline_rounded : Icons.phone_outlined,
                    size: 18,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              RawanaPrimaryButton(
                label: _channel == _ResetChannel.email ? l10n.sendResetLink : l10n.sendResetCode,
                icon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: _loading || !identityReady ? null : _send,
              ),
            ],
            if (_step == _ResetStep.emailSent)
              Text(
                l10n.resetLinkSent,
                style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
              ),
            if (_step == _ResetStep.code) ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.enterTheCode,
                  prefixIcon: const Icon(Icons.verified_user_outlined, size: 18),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              RawanaPrimaryButton(
                label: l10n.continueAction,
                loading: _loading,
                onPressed: _loading || _codeController.text.trim().length < 6 ? null : _verifyCode,
              ),
            ],
            if (_step == _ResetStep.password) ...[
              Text(
                l10n.setNewPassword,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              RawanaPrimaryButton(
                label: l10n.updatePassword,
                loading: _loading,
                onPressed: _loading ? null : _savePassword,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: RawanaColors.error, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
