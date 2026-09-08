import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';

/// Slim bottom bar during in-app navigation — tap Routes to return to trip overview.
class TripInAppNavigationBar extends StatelessWidget {
  const TripInAppNavigationBar({
    super.key,
    required this.destinationLabel,
    required this.onExit,
    this.onShowRoutes,
    this.etaMinutes,
    this.distanceKm,
    this.subtitle,
  });

  final String destinationLabel;
  final VoidCallback onExit;
  /// Returns to trip overview where route alternatives can be picked.
  final VoidCallback? onShowRoutes;
  final int? etaMinutes;
  final double? distanceKm;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final showRoutes = onShowRoutes ?? onExit;

    return Material(
      elevation: 12,
      shadowColor: const Color(0x400A2540),
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtitle ?? context.l10n.followingSelectedRoute,
                    style: const TextStyle(
                      color: RawanaColors.onSurfaceMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destinationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: showRoutes,
              icon: const Icon(Icons.alt_route_rounded, size: 18),
              label: Text(context.l10n.routes),
              style: TextButton.styleFrom(
                foregroundColor: RawanaColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
