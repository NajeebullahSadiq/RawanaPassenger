import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/booking_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';

/// Pickup + destination rows joined by a connector (Uber-style route summary).
class TripRouteAddresses extends StatelessWidget {
  const TripRouteAddresses({
    super.key,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.currentLabel,
    this.etaMinutes,
    this.distanceKm,
    this.dense = false,
  });

  final String pickupAddress;
  final String dropoffAddress;

  /// When set (e.g. trip in progress), shown instead of pickup as the origin row.
  final String? currentLabel;
  final int? etaMinutes;
  final double? distanceKm;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.text;
    final originLabel = currentLabel ?? pickupAddress;
    final originTitle = currentLabel != null ? l10n.currentLabel : l10n.pickupTitle;
    final markerSize = dense ? 10.0 : 12.0;
    final rail = dense ? 24.0 : 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: rail,
                child: Column(
                  children: [
                    SizedBox(height: dense ? 5 : 6),
                    Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: RawanaColors.pickupPin, width: 3),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: RawanaColors.divider,
                      ),
                    ),
                    Container(
                      width: markerSize,
                      height: markerSize,
                      color: RawanaColors.dropoffPin,
                    ),
                    SizedBox(height: dense ? 5 : 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AddressText(title: originTitle, address: originLabel, dense: dense),
                    SizedBox(height: dense ? 10 : 14),
                    _AddressText(
                      title: l10n.destinationTitle,
                      address: dropoffAddress,
                      dense: dense,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (etaMinutes != null || distanceKm != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (etaMinutes != null) ...[
                const Icon(LucideIcons.clock, size: 15, color: RawanaColors.primary),
                const SizedBox(width: 4),
                Text(
                  l10n.etaMinutes('$etaMinutes'),
                  style: text.caption.copyWith(color: RawanaColors.primary, fontWeight: FontWeight.w700),
                ),
              ],
              if (etaMinutes != null && distanceKm != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('·', style: text.caption),
                ),
              if (distanceKm != null)
                Text(l10n.distanceKm(distanceKm!.toStringAsFixed(1)), style: text.caption),
            ],
          ),
        ],
      ],
    );
  }
}

class _AddressText extends StatelessWidget {
  const _AddressText({required this.title, required this.address, required this.dense});

  final String title;
  final String address;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.label.copyWith(fontSize: dense ? 11 : 12)),
        const SizedBox(height: 1),
        Text(
          address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: (dense ? text.bodyStrong.copyWith(fontSize: 14) : text.bodyStrong).copyWith(height: 1.3),
        ),
      ],
    );
  }
}
