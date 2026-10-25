import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/trip_providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final options = [
      ('en', l10n.languageEnglish, l10n.languageEnglishMeta, 'ðŸ‡¬ðŸ‡§'),
      ('fa', l10n.languageDari, l10n.languageDariMeta, 'ðŸ‡¦ðŸ‡«'),
      ('ps', l10n.languagePashto, l10n.languagePashtoMeta, 'ðŸ‡¦ðŸ‡«'),
    ];

    final current = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chooseYourLanguage,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageChangeHint,
                style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = options[i];
                    final selected = o.$1 == current;
                    return _LangTile(
                      flag: o.$4,
                      label: o.$2,
                      sub: o.$3,
                      selected: selected,
                      onTap: () async {
                        await ref.read(localeProvider.notifier).setLocale(Locale(o.$1));
                        if (ref.read(isAppLoggedInProvider)) {
                          try {
                            await ref.read(passengerServiceProvider).updateProfile(language: o.$1);
                          } catch (_) {}
                          if (context.mounted) {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          }
                        } else if (context.mounted) {
                          context.go('/auth');
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.flag,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });
  final String flag;
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? RawanaColors.primary.withValues(alpha: 0.06) : Colors.white,
            border: Border.all(
              color: selected ? RawanaColors.primary : RawanaColors.divider,
              width: selected ? 1.8 : 1,
            ),
            borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(sub, style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (selected)
                const Icon(LucideIcons.checkCircle2, color: RawanaColors.primary, size: 22)
              else
                const Icon(LucideIcons.chevronRightDir, color: RawanaColors.onSurfaceFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
