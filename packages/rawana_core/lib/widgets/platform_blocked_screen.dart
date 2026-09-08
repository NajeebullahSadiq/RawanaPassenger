import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n_extensions.dart';
import '../models/platform_settings.dart';
import '../theme/rawana_theme.dart';
import 'rawana_primary_button.dart';

class PlatformBlockedScreen extends StatelessWidget {
  const PlatformBlockedScreen({super.key, required this.block});

  final PlatformBlock block;

  @override
  Widget build(BuildContext context) {
    final maintenance = block.kind == PlatformBlockKind.maintenance;
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                maintenance ? Icons.build_outlined : Icons.system_update_alt,
                size: 48,
                color: RawanaColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                maintenance
                    ? context.l10n.maintenanceTitle
                    : context.l10n.forceUpdateTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                maintenance ? block.message : context.l10n.forceUpdateBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  height: 1.5,
                ),
              ),
              if (!maintenance && (block.storeUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 24),
                RawanaPrimaryButton(
                  label: context.l10n.updateApp,
                  icon: Icons.open_in_new,
                  onPressed: () {
                    final url = Uri.tryParse(block.storeUrl!);
                    if (url != null) launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
