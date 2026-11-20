import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';

/// “Re-center” pill for live maps.
class MapRecenterButton extends StatelessWidget {
  const MapRecenterButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RawanaSpacing.radiusPill);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: RawanaShadows.floating),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 16, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.navigation, size: 18, color: RawanaColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.recenter,
                    style: context.text.subtitle.copyWith(color: RawanaColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
