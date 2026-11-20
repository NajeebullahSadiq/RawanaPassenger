import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/app_config.dart';
import '../../l10n/l10n_extensions.dart';
import '../../theme/rawana_theme.dart';
import '../../utils/profile_registration.dart';
import '../../widgets/demo_login_button.dart';
import '../../widgets/rawana_primary_button.dart';
import '../../widgets/ui/rawana_banner.dart';
import '../../widgets/ui/rawana_icons.dart';
import '../../widgets/ui/rawana_scaffold.dart';
import '../../widgets/ui/rawana_text_field.dart';
import 'auth_failure.dart';

/// Copy that differs between the rider and driver apps.
class RawanaEmailAuthCopy {
  const RawanaEmailAuthCopy({
    required this.signInTitle,
    required this.signInSubtitle,
    required this.signUpTitle,
    required this.signUpSubtitle,
    required this.signUpButton,
    required this.switchToSignIn,
    required this.switchToSignUp,
  });

  final String signInTitle;
  final String signInSubtitle;
  final String signUpTitle;
  final String signUpSubtitle;
  final String signUpButton;
  final String switchToSignIn;
  final String switchToSignUp;
}

/// Email sign-in and sign-up. The callbacks throw on failure and navigate on success.
class RawanaEmailAuthView extends StatefulWidget {
  const RawanaEmailAuthView({
    super.key,
    required this.copy,
    required this.onSignIn,
    required this.onSignUp,
    required this.onForgotPassword,
    required this.languageCode,
    required this.onLanguageChanged,
    this.startAsSignUp = false,
    this.onDemoLogin,
    this.onBack,
  });

  final RawanaEmailAuthCopy copy;
  final Future<void> Function(String email, String password) onSignIn;
  final Future<void> Function({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) onSignUp;
  final VoidCallback onForgotPassword;
  final String languageCode;
  final ValueChanged<String> onLanguageChanged;
  final bool startAsSignUp;
  final Future<void> Function()? onDemoLogin;
  final VoidCallback? onBack;

  @override
  State<RawanaEmailAuthView> createState() => _RawanaEmailAuthViewState();
}

class _RawanaEmailAuthViewState extends State<RawanaEmailAuthView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  late bool _isSignUp = widget.startAsSignUp;
  bool _loading = false;
  bool _demoLoading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {bool demo = false}) async {
    setState(() {
      demo ? _demoLoading = true : _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = rawanaAuthFailure(context, e));
    } finally {
      if (mounted) {
        setState(() => demo ? _demoLoading = false : _loading = false);
      }
    }
  }

  void _submit() {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    _run(() {
      if (!_isSignUp) return widget.onSignIn(_email.text.trim(), _password.text);
      return widget.onSignUp(
        name: _name.text.trim(),
        phone: normalizeAfPhoneInput(_phone.text),
        email: _email.text.trim(),
        password: _password.text,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final copy = widget.copy;
    final showDemo = widget.onDemoLogin != null && AppConfig.enableDemoLogin;
    return RawanaScaffold(
      onBack: widget.onBack,
      body: Form(
        key: _formKey,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              RawanaPageHeader(
                icon: _isSignUp ? LucideIcons.userPlus : LucideIcons.mail,
                title: _isSignUp ? copy.signUpTitle : copy.signInTitle,
                subtitle: _isSignUp ? copy.signUpSubtitle : copy.signInSubtitle,
              ),
              const SizedBox(height: 24),
              if (!AppConfig.hasSupabase) ...[
                RawanaBanner(tone: RawanaBannerTone.warning, message: l10n.authSupabaseNotConfigured),
                const SizedBox(height: 16),
              ],
              if (_isSignUp) ...[
                RawanaTextField(
                  controller: _name,
                  label: l10n.fullNameRequired,
                  prefixIcon: LucideIcons.user,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => isRegistrationNameValid(v) ? null : l10n.fullNameRequired,
                ),
                const SizedBox(height: 16),
                RawanaPhoneField(
                  controller: _phone,
                  label: l10n.phoneNumberRequired,
                  hint: l10n.phoneHint,
                  textInputAction: TextInputAction.next,
                  validator: (v) => isRegistrationPhoneValid(normalizeAfPhoneInput(v ?? ''))
                      ? null
                      : l10n.authError('invalid_phone'),
                ),
                const SizedBox(height: 16),
              ],
              RawanaTextField(
                controller: _email,
                label: l10n.emailLabel,
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                autofillHints: const [AutofillHints.email],
                validator: (v) => isRegistrationEmailValid(v) ? null : l10n.authError('invalid_email'),
              ),
              const SizedBox(height: 16),
              RawanaTextField(
                controller: _password,
                label: l10n.passwordLabel,
                prefixIcon: LucideIcons.lock,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
                onSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.passwordLabel;
                  if (_isSignUp && v.length < 8) return l10n.authError('weak_password');
                  return null;
                },
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 20),
                Text(l10n.registrationLanguage, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in [
                      ('en', l10n.languageEnglish),
                      ('fa', l10n.languageDari),
                      ('ps', l10n.languagePashto),
                    ])
                      ChoiceChip(
                        label: Text(option.$2),
                        selected: widget.languageCode == option.$1,
                        onSelected: (_) => widget.onLanguageChanged(option.$1),
                      ),
                  ],
                ),
              ] else
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _loading ? null : widget.onForgotPassword,
                    child: Text(l10n.forgotPassword),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                RawanaBanner.error(message: _error!),
              ],
              const SizedBox(height: 24),
              RawanaPrimaryButton(
                label: _isSignUp ? copy.signUpButton : l10n.signIn,
                icon: RawanaIcons.forward,
                loading: _loading,
                onPressed: _loading || _demoLoading ? null : _submit,
              ),
              if (showDemo) ...[
                const SizedBox(height: 12),
                DemoLoginButton(
                  loading: _demoLoading,
                  label: l10n.quickDemoAccess,
                  onPressed: _loading || _demoLoading ? null : () => _run(widget.onDemoLogin!, demo: true),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _error = null;
                }),
                child: Text(_isSignUp ? copy.switchToSignIn : copy.switchToSignUp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
