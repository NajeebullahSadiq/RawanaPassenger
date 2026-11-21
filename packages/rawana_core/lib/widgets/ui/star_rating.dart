import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/rawana_theme.dart';

/// Five tappable stars. Read-only when [onChanged] is null.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 40,
    this.spacing = 6,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: EdgeInsetsDirectional.only(end: i == 5 ? 0 : spacing),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChanged == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChanged!(i);
                    },
              child: AnimatedScale(
                duration: RawanaMotion.fast,
                scale: i <= value ? 1.0 : 0.9,
                child: StarIcon(filled: i <= value, size: size),
              ),
            ),
          ),
      ],
    );
  }
}

/// Filled or outlined star, painted so it matches the stroke-style icon set.
class StarIcon extends StatelessWidget {
  const StarIcon({super.key, required this.filled, this.size = 16, this.color});

  final bool filled;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(
        filled: filled,
        color: color ?? (filled ? RawanaColors.accent : RawanaColors.outline),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + size.height * 0.03);
    final outer = size.width * 0.48;
    final inner = outer * 0.48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = size.width * 0.07
        ..strokeJoin = StrokeJoin.round,
    );
    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.07
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.filled != filled || old.color != color;
}

/// "4.9 ★" inline rating.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.dense = false});

  final double rating;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = (dense ? context.text.caption : context.text.subtitle)
        .copyWith(color: RawanaColors.onSurface, fontWeight: FontWeight.w700);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarIcon(filled: true, size: dense ? 13 : 15),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: style),
      ],
    );
  }
}
