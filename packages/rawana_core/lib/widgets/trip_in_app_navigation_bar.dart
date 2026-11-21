import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/booking_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import 'ui/rawana_map_sheet.dart';

/// Bottom bar during in-app navigation: remaining time, arrival clock,
/// distance, and the trip's next action (e.g. "Slide when arrived") so the
/// driver never has to leave navigation to progress the trip.
class TripInAppNavigationBar extends StatelessWidget {
  const TripInAppNavigationBar({
    super.key,
    required this.destinationLabel,
    required this.onExit,
    this.onShowRoutes,
    this.etaMinutes,
    this.distanceKm,
    this.subtitle,
    this.action,
  });

  final String destinationLabel;
  final VoidCallback onExit;

  /// Returns to trip overview where route alternatives can be picked.
  final VoidCallback? onShowRoutes;
  final int? etaMinutes;
  final double? distanceKm;
  final String? subtitle;

  /// Primary trip action shown under the summary (usually a slide-to-confirm).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.text;
    final showRoutes = onShowRoutes ?? onExit;
    final eta = etaMinutes;
    final arrival = eta == null ? null : l10n.clockTime(DateTime.now().add(Duration(minutes: eta)));
    final meta = [
      ?arrival,
      if (distanceKm != null) l10n.distanceKm(distanceKm!.toStringAsFixed(1)),
    ].join('  ·  ');

    return RawanaSheetPanel(
      showGrabber: false,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eta != null)
                      Text(
                        l10n.etaMinutes('$eta'),
                        style: text.headline.copyWith(color: RawanaColors.success),
                      ),
                    Text(
                      meta.isEmpty ? (subtitle ?? l10n.followingSelectedRoute) : meta,
                      style: text.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destinationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.subtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: l10n.tripOverview,
                child: Material(
                  color: RawanaColors.surfaceAlt,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: showRoutes,
                    child: const SizedBox.square(
                      dimension: 52,
                      child: Icon(LucideIcons.route, color: RawanaColors.primaryDeep),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
