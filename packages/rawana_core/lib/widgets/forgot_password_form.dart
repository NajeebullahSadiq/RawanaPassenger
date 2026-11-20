import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../auth/auth_error_messages.dart';
import '../auth/auth_exception.dart';
import '../auth/auth_service.dart';
import '../auth/otp_channel.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/profile_registration.dart';
import 'rawana_primary_button.dart';
import 'show_rawana_error.dart';
import 'ui/rawana_banner.dart';
import 'ui/rawana_icons.dart';
import 'ui/rawana_scaffold.dart';
import 'ui/rawana_text_field.dart';

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

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
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

  Future<void> _send() => _run(() async {
        if (_channel == _ResetChannel.email) {
          final needsCode = await widget.auth.sendEmailPasswordReset(_identityController.text.trim());
          if (!mounted) return;
          setState(() => _step = needsCode ? _ResetStep.code : _ResetStep.emailSent);
        } else {
          await widget.auth.sendPhonePasswordReset(normalizeAfPhoneInput(_identityController.text));
          if (!mounted) return;
          setState(() => _step = _ResetStep.code);
        }
      });

  Future<void> _verifyCode() => _run(() async {
        if (_channel == _ResetChannel.email) {
          await widget.auth.verifyEmailRecoveryCode(
            email: _identityController.text.trim(),
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
      });

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
    await _run(() async {
      await widget.auth.updatePassword(password);
      if (!mounted) return;
      showRawanaMessage(context, context.l10n.passwordResetSignIn);
      await widget.onSignedIn();
    });
  }

  void _setChannel(_ResetChannel channel) {
    setState(() {
      _channel = channel;
      _identityController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEmail = _channel == _ResetChannel.email;
    final identityReady = isEmail
        ? _identityController.text.contains('@')
        : isRegistrationPhoneValid(normalizeAfPhoneInput(_identityController.text));

    return RawanaScaffold(
      title: l10n.resetPasswordTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          RawanaPageHeader(
            icon: LucideIcons.keyRound,
            title: l10n.resetPasswordTitle,
            subtitle: l10n.resetPasswordHint,
          ),
          const SizedBox(height: 20),
          SegmentedButton<_ResetChannel>(
            segments: [
              ButtonSegment(
                value: _ResetChannel.email,
                label: Text(l10n.resetByEmail),
                icon: const Icon(LucideIcons.mail, size: 16),
              ),
              ButtonSegment(
                value: _ResetChannel.sms,
                label: Text(l10n.resetBySms),
                icon: const Icon(LucideIcons.messageSquare, size: 16),
              ),
            ],
            selected: {_channel},
            onSelectionChanged:
                _loading || _step != _ResetStep.identify ? null : (value) => _setChannel(value.first),
          ),
          const SizedBox(height: 20),
          if (_step == _ResetStep.identify) ...[
            if (isEmail)
              RawanaTextField(
                controller: _identityController,
                label: l10n.emailLabel,
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                textDirection: TextDirection.ltr,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => identityReady && !_loading ? _send() : null,
              )
            else
              RawanaPhoneField(
                controller: _identityController,
                label: l10n.phoneNumberRequired,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => identityReady && !_loading ? _send() : null,
              ),
            const SizedBox(height: 24),
            RawanaPrimaryButton(
              label: isEmail ? l10n.sendResetLink : l10n.sendResetCode,
              icon: RawanaIcons.forward,
              loading: _loading,
              onPressed: _loading || !identityReady ? null : _send,
            ),
          ],
          if (_step == _ResetStep.emailSent)
            RawanaBanner(
              tone: RawanaBannerTone.success,
              icon: LucideIcons.mailCheck,
              message: l10n.resetLinkSent,
            ),
          if (_step == _ResetStep.code) ...[
            RawanaTextField(
              controller: _codeController,
              label: l10n.enterTheCode,
              prefixIcon: LucideIcons.shieldCheck,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              textDirection: TextDirection.ltr,
              maxLength: 8,
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
            Text(l10n.setNewPassword, style: context.text.title),
            const SizedBox(height: 16),
            RawanaTextField(
              controller: _passwordController,
              label: l10n.newPassword,
              prefixIcon: LucideIcons.lock,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            RawanaTextField(
              controller: _confirmController,
              label: l10n.confirmPassword,
              prefixIcon: LucideIcons.lock,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _loading ? null : _savePassword(),
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
            RawanaBanner.error(message: _error!),
          ],
        ],
      ),
    );
  }
}
