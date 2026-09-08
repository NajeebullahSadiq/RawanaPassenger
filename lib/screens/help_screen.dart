import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/trip_providers.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(title: Text(context.l10n.helpCentre)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SupportTicketsPanel(supportService: ref.read(supportServiceProvider)),
          const SizedBox(height: 24),
          RawanaSectionLabel(context.l10n.commonQuestions, padding: const EdgeInsets.only(left: 4, bottom: 10)),
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
              side: const BorderSide(color: RawanaColors.divider),
            ),
            child: Column(
              children: [
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(LucideIcons.car, color: RawanaColors.primary),
                    title: Text(context.l10n.faqBookTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                        child: Text(
                          context.l10n.faqBookBody,
                          style: const TextStyle(color: RawanaColors.onSurfaceMuted, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.only(left: 56), child: Container(height: 1, color: RawanaColors.divider)),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(LucideIcons.banknote, color: RawanaColors.success),
                    title: Text(context.l10n.faqPayTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                        child: Text(
                          context.l10n.faqPayBody,
                          style: const TextStyle(color: RawanaColors.onSurfaceMuted, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
