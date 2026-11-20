import 'package:flutter/material.dart';

import '../../theme/rawana_theme.dart';

/// Side-view vehicle illustration for ride options, keyed by the ride type's
/// `image_key` (falls back to `icon_name`). Painted, so it stays sharp at
/// every density and matches the brand palette without image assets.
class RideVehicleArt extends StatelessWidget {
  const RideVehicleArt({super.key, required this.imageKey, this.width = 76});

  final String? imageKey;
  final double width;

  static RideArtKind kindFor(String? key) {
    switch (key?.trim().toLowerCase()) {
      case 'bike':
      case 'motorcycle':
      case 'moto':
      case 'scooter':
        return RideArtKind.bike;
      case 'comfort':
        return RideArtKind.comfort;
      case 'premium':
      case 'lux':
      case 'black':
        return RideArtKind.premium;
      case 'xl':
      case 'van':
      case 'suv':
        return RideArtKind.xl;
      default:
        return RideArtKind.economy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = kindFor(imageKey);
    final flip = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: flip,
      child: CustomPaint(
        size: Size(width, width * 0.52),
        painter: _VehiclePainter(kind),
      ),
    );
  }
}

enum RideArtKind { economy, comfort, premium, xl, bike }

class _VehiclePainter extends CustomPainter {
  const _VehiclePainter(this.kind);

  final RideArtKind kind;

  static const _wheel = Color(0xFF1A1F24);
  static const _hub = Color(0xFFCBD3E1);
  static const _glass = RawanaColors.vehicleGlass;
  static const _headlight = Color(0xFFFFE9A8);
  static const _taillight = Color(0xFFE5484D);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw in a 100 x 52 design space.
    canvas.save();
    canvas.scale(size.width / 100, size.height / 52);
    canvas.drawOval(
      const Rect.fromLTWH(8, 44, 84, 6),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    switch (kind) {
      case RideArtKind.bike:
        _bike(canvas);
      case RideArtKind.xl:
        _van(canvas);
      case RideArtKind.economy:
      case RideArtKind.comfort:
      case RideArtKind.premium:
        _sedan(canvas);
    }
    canvas.restore();
  }

  (Color, Color) get _body => switch (kind) {
        RideArtKind.premium => (RawanaColors.vehiclePremiumBody, const Color(0xFF0A1626)),
        RideArtKind.comfort => (const Color(0xFFD5DCE8), const Color(0xFFB4BFD1)),
        _ => (Colors.white, RawanaColors.vehicleBodyShade),
      };

  Paint _bodyPaint(Rect r) {
    final (light, dark) = _body;
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [light, dark],
      ).createShader(r);
  }

  Paint get _outline => Paint()
    ..color = RawanaColors.vehicleTrim.withValues(alpha: kind == RideArtKind.premium ? 0.0 : 0.22)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  void _wheels(Canvas canvas, List<double> xs, double y, double r) {
    for (final x in xs) {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = _wheel);
      canvas.drawCircle(Offset(x, y), r * 0.45, Paint()..color = _hub);
    }
  }

  void _sedan(Canvas canvas) {
    final cabin = Path()
      ..moveTo(24, 24)
      ..lineTo(35, 11)
      ..quadraticBezierTo(37, 9, 41, 9)
      ..lineTo(62, 9)
      ..quadraticBezierTo(66, 9, 69, 12)
      ..lineTo(82, 24)
      ..close();
    final lower = RRect.fromLTRBR(4, 22, 97, 40, const Radius.circular(8));
    final bounds = const Rect.fromLTWH(4, 9, 93, 31);
    canvas.drawPath(cabin, _bodyPaint(bounds));
    canvas.drawRRect(lower, _bodyPaint(bounds));
    canvas.drawPath(cabin, _outline);
    canvas.drawRRect(lower, _outline);

    final glass = Paint()..color = _glass;
    canvas.drawPath(
      Path()
        ..moveTo(31, 23)
        ..lineTo(39, 13)
        ..lineTo(52, 13)
        ..lineTo(52, 23)
        ..close(),
      glass,
    );
    canvas.drawPath(
      Path()
        ..moveTo(55, 13)
        ..lineTo(65, 13)
        ..lineTo(75, 23)
        ..lineTo(55, 23)
        ..close(),
      glass,
    );
    canvas.drawLine(
      const Offset(53.5, 24),
      const Offset(53.5, 37),
      Paint()
        ..color = RawanaColors.vehicleTrim.withValues(alpha: 0.18)
        ..strokeWidth = 1,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(91, 26, 97, 30, const Radius.circular(2)),
      Paint()..color = _headlight,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(4, 26, 8, 30, const Radius.circular(2)),
      Paint()..color = _taillight,
    );
    if (kind == RideArtKind.economy) {
      canvas.drawRRect(
        RRect.fromLTRBR(46, 5, 58, 9, const Radius.circular(1.5)),
        Paint()..color = RawanaColors.primary,
      );
    }
    _wheels(canvas, const [25, 77], 40, 8.5);
  }

  void _van(Canvas canvas) {
    final body = Path()
      ..moveTo(6, 12)
      ..quadraticBezierTo(6, 6, 12, 6)
      ..lineTo(74, 6)
      ..quadraticBezierTo(80, 6, 84, 12)
      ..lineTo(94, 24)
      ..quadraticBezierTo(97, 27, 97, 31)
      ..lineTo(97, 36)
      ..quadraticBezierTo(97, 40, 93, 40)
      ..lineTo(10, 40)
      ..quadraticBezierTo(6, 40, 6, 36)
      ..close();
    canvas.drawPath(body, _bodyPaint(const Rect.fromLTWH(6, 6, 91, 34)));
    canvas.drawPath(body, _outline);
    final glass = Paint()..color = _glass;
    for (final (l, r) in const [(12.0, 30.0), (33.0, 51.0), (54.0, 72.0)]) {
      canvas.drawRRect(RRect.fromLTRBR(l, 11, r, 21, const Radius.circular(2.5)), glass);
    }
    canvas.drawPath(
      Path()
        ..moveTo(75, 11)
        ..lineTo(80, 11)
        ..lineTo(89, 22)
        ..lineTo(75, 22)
        ..close(),
      glass,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(92, 28, 97, 32, const Radius.circular(2)),
      Paint()..color = _headlight,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(6, 26, 10, 31, const Radius.circular(2)),
      Paint()..color = _taillight,
    );
    _wheels(canvas, const [24, 78], 40, 8.5);
  }

  void _bike(Canvas canvas) {
    final ring = Paint()
      ..color = _wheel
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(const Offset(22, 36), 10, ring);
    canvas.drawCircle(const Offset(78, 36), 10, ring);
    canvas.drawCircle(const Offset(22, 36), 2.5, Paint()..color = _hub);
    canvas.drawCircle(const Offset(78, 36), 2.5, Paint()..color = _hub);

    final frame = Path()
      ..moveTo(22, 36)
      ..lineTo(40, 26)
      ..lineTo(62, 26)
      ..lineTo(78, 36);
    canvas.drawPath(
      frame,
      Paint()
        ..color = RawanaColors.primaryDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round,
    );
    final tank = Path()
      ..moveTo(38, 27)
      ..quadraticBezierTo(44, 15, 58, 17)
      ..lineTo(66, 22)
      ..quadraticBezierTo(64, 29, 56, 29)
      ..lineTo(40, 29)
      ..close();
    canvas.drawPath(
      tank,
      Paint()
        ..shader = const LinearGradient(
          colors: [RawanaColors.primaryBright, RawanaColors.primary],
        ).createShader(const Rect.fromLTWH(38, 15, 28, 14)),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(26, 19, 44, 23, const Radius.circular(2)),
      Paint()..color = _wheel,
    );
    canvas.drawLine(
      const Offset(66, 22),
      const Offset(72, 12),
      Paint()
        ..color = _wheel
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(73, 18), 2.2, Paint()..color = _headlight);
  }

  @override
  bool shouldRepaint(_VehiclePainter old) => old.kind != kind;
}
