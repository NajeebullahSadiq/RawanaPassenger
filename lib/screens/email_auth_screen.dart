import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_providers.dart';
import '../utils/auth_routing.dart';
import '../utils/demo_login.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  bool _demoLoading = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _signUpValid =>
      isRegistrationNameValid(_nameController.text) &&
      isRegistrationPhoneValid(normalizeAfPhoneInput(_phoneController.text)) &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _onFieldChanged() => setState(() {});

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      final phone = registrationPhoneForSubmit(phone: _phoneController.text);
      if (_isSignUp) {
        final response = await auth.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          role: 'passenger',
          name: _nameController.text.trim(),
          phone: phone,
        );
        // Skip /email-verify for launch testing. When Supabase "Confirm email"
        // is off, a session is usually returned; otherwise sign in immediately.
        if (response.session == null) {
          await auth.signInWithEmail(
            email: _emailController.text,
            password: _passwordController.text,
          );
        }
        // Persist phone/name to backend so profile-setup is not asked again.
        await syncBackendProfile(ref.read(apiClientProvider));
        await ref.read(passengerServiceProvider).updateProfile(
              name: _nameController.text.trim(),
              phone: phone,
              email: _emailController.text.trim(),
            );
      } else {
        await auth.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) {
        final route = await passengerRouteAfterAuth(
          ref.read(passengerServiceProvider),
          ref.read(apiClientProvider),
        );
        if (!mounted) return;
        context.go(route);
      }
    } on RawanaAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorMessage(e.messageKey, detail: e.message, l10n: context.l10n));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSignUp ? context.l10n.createAccount : context.l10n.welcomeBack,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp ? context.l10n.signUpSubtitle : context.l10n.signInSubtitle,
                  style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 24),
                if (!AppConfig.hasSupabase)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: RawanaColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                      border: Border.all(color: RawanaColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(children: [
                      const Icon(LucideIcons.triangleAlert, size: 18, color: RawanaColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.authSupabaseNotConfigured,
                          style: const TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.l10n.emailLabel,
                    prefixIcon: const Icon(LucideIcons.mail, size: 18),
                  ),
                  onChanged: (_) => _onFieldChanged(),
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: context.l10n.fullNameRequired,
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                    ),
                    onChanged: (_) => _onFieldChanged(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                        decoration: BoxDecoration(
                          color: RawanaColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                        ),
                        child: Text(context.l10n.afPhonePrefix, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: context.l10n.phoneNumberRequired,
                            hintText: context.l10n.phoneHint,
                          ),
                          onChanged: (_) => _onFieldChanged(),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: context.l10n.passwordLabel,
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 18,
                        color: RawanaColors.onSurfaceMuted,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  onChanged: (_) => _onFieldChanged(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(LucideIcons.triangleAlert, color: RawanaColors.error, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: RawanaColors.error, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                RawanaPrimaryButton(
                  label: _isSignUp ? context.l10n.createAccount : context.l10n.signIn,
                  icon: LucideIcons.arrowRight,
                  loading: _loading,
                  onPressed: _loading || (_isSignUp && !_signUpValid) ? null : _submit,
                ),
                if (AppConfig.enableDemoLogin) ...[
                  const SizedBox(height: 12),
                  DemoLoginButton(
                    loading: _demoLoading,
                    label: context.l10n.quickDemoAccess,
                    onPressed: _loading || _demoLoading
                        ? null
                        : () => performPassengerDemoLogin(
                              context: context,
                              ref: ref,
                              setLoading: (v) => setState(() => _demoLoading = v),
                              setError: (e) => setState(() => _error = e),
                            ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? context.l10n.alreadyHaveAccount : context.l10n.newHereCreateAccount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
