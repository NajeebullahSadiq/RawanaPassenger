import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Branded location row for search results, saved and recent places.
class PlaceRow extends StatelessWidget {
  const PlaceRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Blue icon chip for primary rows ("Current location", "Set on map").
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlight
                      ? RawanaColors.primary.withValues(alpha: 0.1)
                      : RawanaColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: highlight ? RawanaColors.primary : RawanaColors.onSurface,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.subtitle.copyWith(
                        color: highlight ? RawanaColors.primary : RawanaColors.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Indented divider that lines up with [PlaceRow] text.
class PlaceRowDivider extends StatelessWidget {
  const PlaceRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 58),
      child: Divider(height: 1),
    );
  }
}
