import 'package:flutter/material.dart';
import '../theme/rawana_theme.dart';

/// Floating circular icon button — used for map overlays (back, locate me),
/// modal close buttons, and avatar-style triggers. Provides consistent
/// shadow + tap area across the app.
class RawanaCircleIconButton extends StatelessWidget {
  const RawanaCircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background = Colors.white,
    this.iconColor = RawanaColors.onSurface,
    this.size = 44,
    this.elevated = true,
    this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color iconColor;
  final double size;
  final bool elevated;
  final String? tooltip;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: elevated ? RawanaShadows.floating : null,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(child: Icon(icon, color: iconColor, size: size * 0.46)),
        ),
      ),
    );

    final wrapped = badge == null
        ? btn
        : Stack(
            clipBehavior: Clip.none,
            children: [
              btn,
              Positioned(top: -2, right: -2, child: badge!),
            ],
          );

    if (tooltip == null) return wrapped;
    return Tooltip(message: tooltip!, child: wrapped);
  }
}
