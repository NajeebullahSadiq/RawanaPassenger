import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';

/// Premium primary CTA — gradient fill, subtle glow, optional leading icon.
/// Designed to be the most prominent button on a screen.
class RawanaGradientButton extends StatelessWidget {
  const RawanaGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient,
    this.height = RawanaSpacing.buttonHeight,
    this.expanded = true,
    this.foregroundColor = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Gradient? gradient;
  final double height;
  final bool expanded;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !loading;
    final radius = BorderRadius.circular(RawanaSpacing.radiusMd);

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: foregroundColor),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? RawanaColors.primaryGradient,
          borderRadius: radius,
          boxShadow: disabled ? null : RawanaShadows.ctaGlow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: loading || disabled ? null : onPressed,
            borderRadius: radius,
            child: SizedBox(
              height: height,
              width: expanded ? double.infinity : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
