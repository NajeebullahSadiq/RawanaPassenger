import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Small metric tile: icon, label and a bold value.
class RawanaKpiCard extends StatelessWidget {
  const RawanaKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = RawanaColors.primary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final VoidCallback? onTap;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RawanaSpacing.radiusSm),
                ),
                child: Icon(icon, size: 17, color: tone),
              ),
              const SizedBox(height: 12),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.title),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark summary card for the headline number of a page (earnings, balance).
class RawanaHeroCard extends StatelessWidget {
  const RawanaHeroCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.gradient = RawanaColors.inkGradient,
    this.valueColor = Colors.white,
    this.trailing,
    this.footer,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Gradient gradient;
  final Color valueColor;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
        boxShadow: RawanaShadows.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: context.text.label.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: context.text.priceLarge.copyWith(color: valueColor)),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: context.text.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
          ],
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}
