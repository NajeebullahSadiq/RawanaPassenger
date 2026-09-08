import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';

/// Soft, elevated surface used throughout the app for floating panels,
/// info cards, and bottom-sheet style modules. Wraps a [Material] for
/// proper ink response and provides consistent shadows + corner radii.
class RawanaSurfaceCard extends StatelessWidget {
  const RawanaSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.color,
    this.gradient,
    this.borderRadius,
    this.shadows,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Gradient? gradient;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? shadows;
  final BoxBorder? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(RawanaSpacing.radiusLg);
    final radiusBR = radius is BorderRadius ? radius : null;

    final padded = Padding(padding: padding, child: child);

    // For a gradient background, the color lives on an inner DecoratedBox
    // (Material can only render a solid color). For a solid background we
    // hand the color to Material itself — that way `ListTile` / `InkWell`
    // ink splashes paint on the same Material that draws the background and
    // are visible. (Previously the colored Container was a descendant of
    // Material, which hid splashes and triggered framework warnings.)
    final bodyForGradient = DecoratedBox(
      decoration: BoxDecoration(gradient: gradient, borderRadius: radius),
      child: padded,
    );

    final tappable = onTap == null
        ? (gradient != null ? bodyForGradient : padded)
        : InkWell(
            onTap: onTap,
            borderRadius: radiusBR,
            child: gradient != null ? bodyForGradient : padded,
          );

    final BorderSide side = (border is Border)
        ? (border as Border).top
        : BorderSide.none;

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadows ?? RawanaShadows.floating,
        ),
        child: Material(
          color: gradient == null ? (color ?? Colors.white) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radiusBR ?? BorderRadius.zero,
            side: side,
          ),
          clipBehavior: Clip.antiAlias,
          child: tappable,
        ),
      ),
    );
  }
}
