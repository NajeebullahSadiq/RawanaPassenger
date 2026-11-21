import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/rawana_theme.dart';

enum RawanaBannerTone { info, success, warning, error }

/// Inline message box for form errors, confirmations and notices.
class RawanaBanner extends StatelessWidget {
  const RawanaBanner({
    super.key,
    required this.message,
    this.tone = RawanaBannerTone.info,
    this.icon,
    this.action,
  });

  const RawanaBanner.error({super.key, required this.message, this.icon, this.action})
      : tone = RawanaBannerTone.error;

  final String message;
  final RawanaBannerTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData defaultIcon) = switch (tone) {
      RawanaBannerTone.info => (RawanaColors.primary, LucideIcons.info),
      RawanaBannerTone.success => (RawanaColors.success, LucideIcons.circleCheck),
      RawanaBannerTone.warning => (RawanaColors.warning, LucideIcons.triangleAlert),
      RawanaBannerTone.error => (RawanaColors.error, LucideIcons.circleAlert),
    };
    return Semantics(
      liveRegion: tone == RawanaBannerTone.error,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: context.text.caption.copyWith(
                  color: tone == RawanaBannerTone.info ? RawanaColors.onSurface : color,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
      ),
    );
  }
}
