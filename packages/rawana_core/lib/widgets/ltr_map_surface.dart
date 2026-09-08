import 'package:flutter/material.dart';

/// Keeps Google Maps / platform views in LTR even when the app is Dari/Pashto.
///
/// Flutter mirrors platform views under [TextDirection.rtl], which flips
/// gestures, tiles, and polylines. Map chrome must stay geographic LTR.
class LtrMapSurface extends StatelessWidget {
  const LtrMapSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }
}
