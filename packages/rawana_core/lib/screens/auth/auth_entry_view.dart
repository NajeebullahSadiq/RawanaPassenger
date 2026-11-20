import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../config/app_config.dart';
import '../../l10n/l10n_extensions.dart';
import '../../theme/rawana_theme.dart';
import '../../widgets/demo_login_button.dart';
import '../../widgets/rawana_brand_mark.dart';
import '../../widgets/rawana_info_screen.dart';
import '../../widgets/rawana_primary_button.dart';
import '../../widgets/ui/rawana_banner.dart';
import 'auth_failure.dart';

class RawanaValueProp {
  const RawanaValueProp({required this.icon, required this.title, required this.body, this.tone});
  final IconData icon;
  final String title;
  final String body;
  final Color? tone;
}

/// Welcome screen for both apps. The app supplies its copy, value props and
/// navigation; the layout, legal consent and demo access are shared.
class RawanaAuthEntryView extends StatefulWidget {
  const RawanaAuthEntryView({
    super.key,
    required this.badge,
    required this.headline,
    required this.subtitle,
    required this.valueProps,
    required this.onPhone,
    required this.onEmail,
    required this.onForgotPassword,
    required this.onTerms,
    required this.onPrivacy,
    this.badgeGradient,
    this.badgeTextColor = Colors.white,
    this.onDemoLogin,
  });

  final String badge;
  final Gradient? badgeGradient;
  final Color badgeTextColor;
  final String headline;
  final String subtitle;
  final List<RawanaValueProp> valueProps;
  final VoidCallback onPhone;
  final VoidCallback onEmail;
  final VoidCallback onForgotPassword;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  /// Only wired up in debug / dev builds; throws to report a failure.
  final Future<void> Function()? onDemoLogin;

  @override
  State<RawanaAuthEntryView> createState() => _RawanaAuthEntryViewState();
}

class _RawanaAuthEntryViewState extends State<RawanaAuthEntryView> {
  bool _demoLoading = false;
  String? _error;

  Future<void> _demo() async {
    setState(() {
      _demoLoading = true;
      _error = null;
    });
    try {
      await widget.onDemoLogin!();
    } catch (e) {
      if (mounted) setState(() => _error = rawanaAuthFailure(context, e));
    } finally {
      if (mounted) setState(() => _demoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final emailFirst = AppConfig.useEmailAuthForTesting;
    final showDemo = widget.onDemoLogin != null && AppConfig.enableDemoLogin;
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          RawanaBrandMark.appIcon(size: 76),
                          PositionedDirectional(
                            bottom: -4,
                            end: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.badgeGradient == null ? RawanaColors.primary : null,
                                gradient: widget.badgeGradient,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Text(
                                widget.badge,
                                style: context.text.label.copyWith(
                                  color: widget.badgeTextColor,
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(widget.headline, style: context.text.display),
                    const SizedBox(height: 10),
                    Text(
                      emailFirst ? l10n.signInEmailToTest : widget.subtitle,
                      style: context.text.body.copyWith(color: RawanaColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 32),
                    for (final p in widget.valueProps) ...[
                      _ValuePropRow(prop: p),
                      const SizedBox(height: 14),
                    ],
                    const Spacer(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      RawanaBanner.error(message: _error!),
                    ],
                    const SizedBox(height: 16),
                    if (emailFirst) ...[
                      RawanaPrimaryButton(label: l10n.continueWithEmail, icon: LucideIcons.mail, onPressed: widget.onEmail),
                      const SizedBox(height: 12),
                      if (AppConfig.enablePhoneOtp)
                        OutlinedButton.icon(
                          onPressed: widget.onPhone,
                          icon: const Icon(LucideIcons.phone, size: 20),
                          label: Text(l10n.continueWithPhone),
                        )
                      else
                        Text(
                          l10n.phoneOtpComingSoon,
                          textAlign: TextAlign.center,
                          style: context.text.caption.copyWith(color: RawanaColors.onSurfaceFaint),
                        ),
                    ] else ...[
                      RawanaPrimaryButton(label: l10n.continueWithPhone, icon: LucideIcons.phone, onPressed: widget.onPhone),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: widget.onEmail,
                        icon: const Icon(LucideIcons.mail, size: 20),
                        label: Text(l10n.continueWithEmail),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(onPressed: widget.onForgotPassword, child: Text(l10n.forgotPassword)),
                    ),
                    if (showDemo) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.orDivider,
                              style: context.text.label.copyWith(color: RawanaColors.onSurfaceFaint, letterSpacing: 1.5),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DemoLoginButton(
                        loading: _demoLoading,
                        label: l10n.quickDemoAccess,
                        onPressed: _demoLoading ? null : _demo,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RawanaLegalConsentText(onTerms: widget.onTerms, onPrivacy: widget.onPrivacy),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValuePropRow extends StatelessWidget {
  const _ValuePropRow({required this.prop});
  final RawanaValueProp prop;

  @override
  Widget build(BuildContext context) {
    final tone = prop.tone ?? RawanaColors.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
          ),
          child: Icon(prop.icon, color: tone, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prop.title, style: context.text.bodyStrong),
              const SizedBox(height: 2),
              Text(prop.body, style: context.text.caption.copyWith(color: RawanaColors.onSurfaceMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
