import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/l10n_extensions.dart';
import '../../models/trip.dart';
import '../../theme/rawana_theme.dart';
import 'rawana_icons.dart';
import 'status_pill.dart';

/// History / reservation row: route, when, status and amount.
class RawanaTripRow extends StatelessWidget {
  const RawanaTripRow({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.when,
    this.amount,
    this.status,
    this.leading,
    this.onTap,
    this.footer,
  });

  final String pickup;
  final String dropoff;
  final String? when;
  final String? amount;
  final Widget? status;
  final Widget? leading;
  final VoidCallback? onTap;

  /// Extra content under the row (e.g. reservation actions).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RawanaSpacing.radiusLg);
    return Material(
      color: Colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: RawanaColors.divider)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading ??
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: RawanaColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
                        ),
                        child: const Icon(LucideIcons.mapPin, size: 18, color: RawanaColors.primary),
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dropoff, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyStrong),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.fromAddress(pickup),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption,
                        ),
                        if (when != null || status != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ?status,
                              if (when != null) Text(when!, style: context.text.caption),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (amount != null) Text(amount!, style: context.text.price),
                      if (onTap != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(RawanaIcons.chevronForward, size: 18, color: RawanaColors.onSurfaceFaint),
                        ),
                    ],
                  ),
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 12), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Localised status pill for a trip, with one colour per state across both apps.
class TripStatusPill extends StatelessWidget {
  const TripStatusPill({super.key, required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      TripStatus.completed => (RawanaColors.success, LucideIcons.circleCheck),
      TripStatus.cancelled => (RawanaColors.error, LucideIcons.circleX),
      TripStatus.scheduled => (RawanaColors.primary, LucideIcons.calendarClock),
      TripStatus.searching => (RawanaColors.warning, LucideIcons.search),
      _ => (RawanaColors.primary, LucideIcons.car),
    };
    return StatusPill(label: context.l10n.tripStatusLabel(status.apiValue), color: color, icon: icon);
  }
}
