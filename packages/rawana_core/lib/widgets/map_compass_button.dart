import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Google Maps-style compass whose needle tracks the map bearing (degrees).
class MapCompassButton extends StatelessWidget {
  const MapCompassButton({
    super.key,
    required this.bearing,
    required this.onPressed,
    this.size = 46,
  });

  final ValueListenable<double> bearing;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: const Color(0x33000000),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFFD0D5DD)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Padding(
            padding: EdgeInsets.all(size * 0.18),
            child: ValueListenableBuilder<double>(
              valueListenable: bearing,
              builder: (context, value, child) => Transform.rotate(
                angle: -value * math.pi / 180,
                child: child,
              ),
              child: const CustomPaint(painter: _NeedlePainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = size.width * 0.22;

    final north = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + half, cy)
      ..lineTo(cx - half, cy)
      ..close();
    final south = Path()
      ..moveTo(cx, size.height)
      ..lineTo(cx + half, cy)
      ..lineTo(cx - half, cy)
      ..close();

    canvas.drawPath(north, Paint()..color = const Color(0xFFE53935));
    canvas.drawPath(south, Paint()..color = const Color(0xFFB0B6BE));
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.07,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter oldDelegate) => false;
}
