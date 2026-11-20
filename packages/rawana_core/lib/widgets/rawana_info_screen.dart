import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../content/rawana_driver_content.dart';
import '../l10n/app_ui_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'ui/rawana_scaffold.dart';

/// Scrollable policy / guidelines screen built from [RawanaInfoSection] blocks.
class RawanaInfoScreen extends StatelessWidget {
  const RawanaInfoScreen({
    super.key,
    required this.title,
    required this.sections,
    this.leading,
    this.showLegalFooter = false,
  });

  final String title;
  final List<RawanaInfoSection> sections;
  final Widget? leading;

  /// Adds "last updated" and the support contact under the sections.
  final bool showLegalFooter;

  @override
  Widget build(BuildContext context) {
    return RawanaScaffold(
      title: title,
      body: ListView(
        padding: RawanaScaffold.pagePadding,
        children: [
          if (leading != null) ...[leading!, const SizedBox(height: 20)],
          for (var i = 0; i < sections.length; i++) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                border: Border.all(color: RawanaColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}. ${sections[i].title}', style: context.text.subtitle),
                  const SizedBox(height: 8),
                  Text(
                    sections[i].body,
                    style: context.text.body.copyWith(color: RawanaColors.onSurfaceMuted, height: 1.55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (showLegalFooter) ...[
            const SizedBox(height: 8),
            Text(context.l10n.legalLastUpdated, textAlign: TextAlign.center, style: context.text.caption),
            const SizedBox(height: 4),
            Text(context.l10n.legalQuestions, textAlign: TextAlign.center, style: context.text.caption),
          ],
        ],
      ),
    );
  }
}

/// "By continuing you agree to the Terms of Service and Privacy Policy." with
/// both names tappable.
class RawanaLegalConsentText extends StatefulWidget {
  const RawanaLegalConsentText({super.key, required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  State<RawanaLegalConsentText> createState() => _RawanaLegalConsentTextState();
}

class _RawanaLegalConsentTextState extends State<RawanaLegalConsentText> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()..onTap = widget.onTerms;
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()..onTap = widget.onPrivacy;

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = context.text.caption.copyWith(color: RawanaColors.onSurfaceFaint, height: 1.5);
    final link = base.copyWith(
      color: RawanaColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: RawanaColors.primary.withValues(alpha: 0.4),
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: l10n.byContinuingYouAgree),
          TextSpan(text: l10n.termsOfService, style: link, recognizer: _terms),
          TextSpan(text: l10n.andConnector),
          TextSpan(text: l10n.privacyPolicy, style: link, recognizer: _privacy),
          TextSpan(text: l10n.agreeSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
