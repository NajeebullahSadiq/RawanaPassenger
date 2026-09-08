import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/navigation_guidance.dart';
import 'trip_turn_banner.dart';

/// Top bar shown during in-app navigation (Google Maps-style guidance + ETA).
class TripNavigationHeader extends StatelessWidget {
  const TripNavigationHeader({
    super.key,
    required this.destinationLabel,
    required this.onEndNavigation,
    this.etaMinutes,
    this.distanceKm,
    this.guidance,
  });

  final String destinationLabel;
  final VoidCallback onEndNavigation;
  final int? etaMinutes;
  final double? distanceKm;
  final NavigationGuidance? guidance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (guidance != null) ...[
              TripTurnBanner(guidance: guidance!),
              const SizedBox(height: 8),
            ],
            Material(
          elevation: 8,
          shadowColor: const Color(0x330A2540),
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 14, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: onEndNavigation,
                  tooltip: l10n.endNavigation,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  color: RawanaColors.onSurface,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destinationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (etaMinutes != null || distanceKm != null)
                        Text(
                          [
                            if (etaMinutes != null) l10n.etaMinutes('$etaMinutes'),
                            if (distanceKm != null)
                              l10n.distanceKm(distanceKm!.toStringAsFixed(1)),
                          ].join(' · '),
                          style: const TextStyle(
                            color: RawanaColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: RawanaColors.primary.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(RawanaSpacing.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.navigation_rounded,
                        size: 14,
                        color: RawanaColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.navigating,
                        style: const TextStyle(
                          color: RawanaColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
