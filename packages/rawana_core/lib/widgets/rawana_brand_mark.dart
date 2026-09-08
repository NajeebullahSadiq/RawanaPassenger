import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/rawana_theme.dart';

/// Official Rawana application logo used on splash, auth, and empty states.
///
/// Renders the bundled SVG from `rawana_core` so every app shows the same
/// brand mark without duplicating assets.
class RawanaBrandMark extends StatelessWidget {
  const RawanaBrandMark({
    super.key,
    this.size = 96,
    this.padding = 0,
    this.backgroundColor,
    this.borderRadius,
    this.shadows,
  });

  /// Edge length of the logo square.
  final double size;

  /// Optional inner padding around the SVG.
  final double padding;

  /// Optional background behind the logo (e.g. white card on auth screens).
  final Color? backgroundColor;

  /// Corner radius when [backgroundColor] is set.
  final BorderRadius? borderRadius;

  /// Optional elevation shadows.
  final List<BoxShadow>? shadows;

  /// White rounded badge — matches the installed app icon on splash screens.
  factory RawanaBrandMark.appIcon({double size = 96}) => RawanaBrandMark(
        size: size,
        padding: size * 0.16,
        backgroundColor: Colors.white,
        shadows: RawanaShadows.ctaGlow,
      );

  static const _assetPath = 'assets/logo.svg';
  static const _package = 'rawana_core';

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      _assetPath,
      package: _package,
      width: size - padding * 2,
      height: size - padding * 2,
      fit: BoxFit.contain,
    );

    if (backgroundColor == null && shadows == null && padding == 0) {
      return SizedBox(width: size, height: size, child: logo);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(size * 0.22),
        boxShadow: shadows,
      ),
      child: logo,
    );
  }
}

/// Compact logo row: icon + "Rawana" wordmark — useful in app bars / drawers.
class RawanaLogoRow extends StatelessWidget {
  const RawanaLogoRow({
    super.key,
    this.iconSize = 36,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.onDark = false,
  });

  final double iconSize;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : RawanaColors.onSurface;
    final subColor = onDark ? Colors.white70 : RawanaColors.onSurfaceMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RawanaBrandMark(
          size: iconSize,
          padding: iconSize * 0.08,
          backgroundColor: onDark ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(iconSize * 0.24),
          shadows: onDark ? null : RawanaShadows.low,
        ),
        SizedBox(width: iconSize * 0.35),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rawana',
                style: titleStyle ??
                    TextStyle(
                      fontSize: iconSize * 0.55,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: titleColor,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: subtitleStyle ??
                      TextStyle(
                        fontSize: iconSize * 0.28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: subColor,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
