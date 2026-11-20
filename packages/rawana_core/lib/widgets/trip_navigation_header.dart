import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/booking_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/navigation_guidance.dart';
import 'trip_turn_banner.dart';

/// Top of the screen during in-app navigation: next maneuver, plus a slim
/// row with exit and voice controls. Shows a "Recalculating" strip while the
/// route is being rebuilt after leaving it.
class TripNavigationHeader extends StatelessWidget {
  const TripNavigationHeader({
    super.key,
    required this.destinationLabel,
    required this.onEndNavigation,
    this.etaMinutes,
    this.distanceKm,
    this.guidance,
    this.voiceMuted = false,
    this.onToggleVoice,
    this.recalculating = false,
  });

  final String destinationLabel;
  final VoidCallback onEndNavigation;
  final int? etaMinutes;
  final double? distanceKm;
  final NavigationGuidance? guidance;
  final bool voiceMuted;
  final VoidCallback? onToggleVoice;
  final bool recalculating;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: RawanaMotion.fast,
              child: recalculating
                  ? _RecalculatingBanner(key: const ValueKey('recalc'), label: l10n.recalculatingRoute)
                  : guidance != null
                      ? TripTurnBanner(key: const ValueKey('turn'), guidance: guidance!)
                      : const SizedBox.shrink(key: ValueKey('none')),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _RoundControl(
                  icon: LucideIcons.x,
                  tooltip: l10n.endNavigation,
                  onPressed: onEndNavigation,
                ),
                const Spacer(),
                if (onToggleVoice != null)
                  _RoundControl(
                    icon: voiceMuted ? LucideIcons.volumeOff : LucideIcons.volume2,
                    tooltip: voiceMuted ? l10n.unmuteVoice : l10n.muteVoice,
                    onPressed: onToggleVoice!,
                    active: !voiceMuted,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: RawanaShadows.floating),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 52,
              child: Icon(
                icon,
                size: 22,
                color: active ? RawanaColors.primary : RawanaColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecalculatingBanner extends StatelessWidget {
  const _RecalculatingBanner({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RawanaColors.warning,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: context.text.title.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
