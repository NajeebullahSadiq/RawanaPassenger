import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';

/// Pickup + destination address rows (Uber-style route summary).
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
    final originLabel = currentLabel ?? pickupAddress;
    final originTitle = currentLabel != null ? l10n.currentLabel : l10n.pickupLabel;
    final originColor = currentLabel != null ? RawanaColors.primary : RawanaColors.pickupPin;
    final originIcon = currentLabel != null ? Icons.my_location : Icons.trip_origin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddressRow(
          title: originTitle,
          address: originLabel,
          icon: originIcon,
          color: originColor,
          dense: dense,
        ),
        Padding(
          padding: EdgeInsets.only(left: dense ? 11 : 13, top: dense ? 2 : 4, bottom: dense ? 2 : 4),
          child: Container(
            width: 2,
            height: dense ? 14 : 18,
            color: RawanaColors.divider,
          ),
        ),
        _AddressRow(
          title: l10n.destinationLabel,
          address: dropoffAddress,
          icon: Icons.flag,
          color: RawanaColors.dropoffPin,
          dense: dense,
        ),
        if (etaMinutes != null || distanceKm != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (etaMinutes != null) ...[
                const Icon(Icons.schedule, size: 15, color: RawanaColors.primary),
                const SizedBox(width: 4),
                Text(
                  l10n.etaMinutes('$etaMinutes'),
                  style: const TextStyle(
                    color: RawanaColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
              if (etaMinutes != null && distanceKm != null)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('·', style: TextStyle(color: RawanaColors.onSurfaceMuted)),
                ),
              if (distanceKm != null)
                Text(
                  l10n.distanceKm(distanceKm!.toStringAsFixed(1)),
                  style: const TextStyle(
                    color: RawanaColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.title,
    required this.address,
    required this.icon,
    required this.color,
    required this.dense,
  });

  final String title;
  final String address;
  final IconData icon;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: dense ? 24 : 28,
          height: dense ? 24 : 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: dense ? 13 : 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: dense ? 9 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: dense ? 14 : 15,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
