import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../widgets/rawana_primary_button.dart';
import '../widgets/ui/rawana_icons.dart';
import '../widgets/ui/rawana_scaffold.dart';

/// Language picker shared by both apps. Each language shows its own script
/// instead of a flag, since Dari and Pashto share a country.
class RawanaLanguageView extends StatelessWidget {
  const RawanaLanguageView({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onContinue,
  });

  final String current;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      ('en', l10n.languageEnglish, l10n.languageEnglishMeta, 'En'),
      ('fa', l10n.languageDari, l10n.languageDariMeta, 'د'),
      ('ps', l10n.languagePashto, l10n.languagePashtoMeta, 'پ'),
    ];
    return RawanaScaffold(
      bottomBar: RawanaPrimaryButton(label: l10n.continueAction, onPressed: onContinue),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          RawanaPageHeader(icon: LucideIcons.languages, title: l10n.chooseYourLanguage, subtitle: l10n.languageChangeHint),
          const SizedBox(height: 24),
          for (final o in options) ...[
            _LangTile(
              glyph: o.$4,
              label: o.$2,
              sub: o.$3,
              selected: o.$1 == current,
              onTap: () => onSelect(o.$1),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.glyph,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RawanaSpacing.radiusLg);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? RawanaColors.primary.withValues(alpha: 0.06) : Colors.white,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: RawanaMotion.fast,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? RawanaColors.primary : RawanaColors.divider,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? RawanaColors.primary : RawanaColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
                  ),
                  child: Text(
                    glyph,
                    style: context.text.title.copyWith(color: selected ? Colors.white : RawanaColors.onSurface),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.text.subtitle),
                      const SizedBox(height: 2),
                      Text(sub, style: context.text.caption),
                    ],
                  ),
                ),
                Icon(
                  selected ? LucideIcons.circleCheck : RawanaIcons.chevronForward,
                  color: selected ? RawanaColors.primary : RawanaColors.onSurfaceFaint,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
