import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/rawana_theme.dart';
import 'rawana_skeleton.dart';
import 'ride_vehicle_art.dart';

/// One ride product in the ride options sheet: vehicle art, name, seats,
/// pickup ETA / arrival time and the price. Selected = 2px primary stroke.
class RideOptionTile extends StatelessWidget {
  const RideOptionTile({
    super.key,
    required this.imageKey,
    required this.name,
    required this.selected,
    required this.onTap,
    this.seats,
    this.etaLabel,
    this.description,
    this.price,
    this.originalPrice,
    this.badge,
    this.priceLoading = false,
  });

  final String? imageKey;
  final String name;
  final int? seats;

  /// e.g. "3 min away · 3:42 PM".
  final String? etaLabel;
  final String? description;
  final String? price;

  /// Shown struck-through when a promo lowers the price.
  final String? originalPrice;
  final String? badge;
  final bool selected;
  final bool priceLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final radius = BorderRadius.circular(RawanaSpacing.radiusMd);
    return AnimatedContainer(
      duration: RawanaMotion.fast,
      decoration: BoxDecoration(
        color: selected ? RawanaColors.primary.withValues(alpha: 0.04) : Colors.white,
        borderRadius: radius,
        border: Border.all(
          color: selected ? RawanaColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 10, 14, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: AnimatedScale(
                    duration: RawanaMotion.medium,
                    curve: RawanaMotion.curve,
                    scale: selected ? 1.06 : 1,
                    child: RideVehicleArt(imageKey: imageKey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.title,
                            ),
                          ),
                          if (seats != null) ...[
                            const SizedBox(width: 8),
                            const Icon(LucideIcons.user, size: 14, color: RawanaColors.onSurfaceMuted),
                            const SizedBox(width: 2),
                            Text('$seats', style: text.caption),
                          ],
                        ],
                      ),
                      if (etaLabel != null && etaLabel!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          etaLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.caption.copyWith(color: RawanaColors.onSurface),
                        ),
                      ],
                      if (selected && description != null && description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.caption,
                        ),
                      ],
                      if (badge != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: RawanaColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(RawanaSpacing.radiusPill),
                          ),
                          child: Text(
                            badge!,
                            style: text.label.copyWith(color: RawanaColors.primary, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (priceLoading)
                      const RawanaSkeleton(width: 64, height: 18)
                    else if (price != null)
                      Text(price!, style: text.price),
                    if (!priceLoading && originalPrice != null)
                      Text(
                        originalPrice!,
                        style: text.caption.copyWith(decoration: TextDecoration.lineThrough),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching [RideOptionTile] while ride types load.
class RideOptionTileSkeleton extends StatelessWidget {
  const RideOptionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Row(
        children: [
          RawanaSkeleton(width: 72, height: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RawanaSkeleton(width: 110, height: 15),
                SizedBox(height: 8),
                RawanaSkeleton(width: 150, height: 11),
              ],
            ),
          ),
          RawanaSkeleton(width: 60, height: 18),
        ],
      ),
    );
  }
}
