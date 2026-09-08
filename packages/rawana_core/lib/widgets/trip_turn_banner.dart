import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/navigation_guidance.dart';

/// Google Maps-style next-maneuver banner.
class TripTurnBanner extends StatelessWidget {
  const TripTurnBanner({
    super.key,
    required this.guidance,
  });

  final NavigationGuidance guidance;

  static IconData iconFor(String maneuver) {
    final value = maneuver.toLowerCase();
    if (value.contains('uturn') || value.contains('u-turn')) {
      return Icons.u_turn_left_rounded;
    }
    if (value.contains('roundabout') || value.contains('rotary')) {
      return Icons.roundabout_left_rounded;
    }
    if (value.contains('merge')) return Icons.merge_rounded;
    if (value.contains('arrive') || value.contains('destination')) {
      return Icons.flag_rounded;
    }
    if (value.contains('left')) return Icons.turn_left_rounded;
    if (value.contains('right')) return Icons.turn_right_rounded;
    if (value.contains('ramp')) return Icons.ramp_right_rounded;
    if (value.contains('fork')) return Icons.call_split_rounded;
    return Icons.straight_rounded;
  }

  static String formatDistance(double meters, AppLocalizations l10n) {
    if (meters >= 1000) {
      return l10n.distanceKm(
        (meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1),
      );
    }
    if (meters >= 80) {
      return l10n.distanceMeters('${(meters / 10).round() * 10}');
    }
    return l10n.distanceMeters('${meters.round()}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: const Color(0xFF1A73E8),
      elevation: 10,
      shadowColor: const Color(0x661A73E8),
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                iconFor(guidance.maneuver),
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatDistance(guidance.distanceToManeuverM, l10n),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guidance.localizedInstruction(l10n),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
