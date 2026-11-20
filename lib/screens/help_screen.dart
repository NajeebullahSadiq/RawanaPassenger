import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final faqs = [
      (LucideIcons.car, RawanaColors.primary, l10n.faqBookTitle, l10n.faqBookBody),
      (LucideIcons.banknote, RawanaColors.success, l10n.faqPayTitle, l10n.faqPayBody),
      (LucideIcons.circleX, RawanaColors.error, l10n.faqCancelTitle, l10n.faqCancelBody),
      (LucideIcons.calendarClock, RawanaColors.primary, l10n.faqScheduleTitle, l10n.faqScheduleBody),
      (LucideIcons.shieldAlert, RawanaColors.warning, l10n.faqSafetyTitle, l10n.faqSafetyBody),
      (LucideIcons.package, RawanaColors.primary, l10n.faqLostItemTitle, l10n.faqLostItemBody),
    ];
    return RawanaScaffold(
      title: l10n.helpCentre,
      body: ListView(
        padding: RawanaScaffold.pagePadding,
        children: [
          SupportTicketsPanel(supportService: ref.read(supportServiceProvider)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
            child: Text(l10n.commonQuestions, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
          ),
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
              side: const BorderSide(color: RawanaColors.divider),
            ),
            child: Column(
              children: [
                for (var i = 0; i < faqs.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 56),
                  _FaqTile(icon: faqs[i].$1, tone: faqs[i].$2, title: faqs[i].$3, body: faqs[i].$4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.icon, required this.tone, required this.title, required this.body});

  final IconData icon;
  final Color tone;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: tone, size: 20),
        title: Text(title, style: context.text.bodyStrong),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(56, 0, 16, 16),
        expandedAlignment: AlignmentDirectional.centerStart,
        children: [Text(body, style: context.text.body.copyWith(color: RawanaColors.onSurfaceMuted))],
      ),
    );
  }
}
