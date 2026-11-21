import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Fixed pin whose tip sits on the centre of its box. It lifts while the map
/// is moving and drops back onto the chosen point when the camera settles.
class RawanaCenterPin extends StatelessWidget {
  const RawanaCenterPin({
    super.key,
    required this.lifted,
    this.color = RawanaColors.pickupPin,
    this.square = false,
  });

  final bool lifted;
  final Color color;

  /// Square head for destinations, round for pickups (DESIGN.md map pins).
  final bool square;

  static const _head = 22.0;
  static const _stem = 18.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: (_head + _stem) * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: RawanaMotion.fast,
            width: lifted ? 12 : 8,
            height: lifted ? 5 : 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: lifted ? 0.18 : 0.32),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          AnimatedSlide(
            duration: RawanaMotion.fast,
            curve: RawanaMotion.curve,
            offset: Offset(0, lifted ? -0.62 : -0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: _head,
                  height: _head,
                  decoration: BoxDecoration(
                    color: color,
                    shape: square ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: square ? BorderRadius.circular(4) : null,
                    boxShadow: RawanaShadows.floating,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: square ? BoxShape.rectangle : BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Container(width: 3, height: _stem, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
