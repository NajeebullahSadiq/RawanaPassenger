import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

/// Renders a branded map pin for Google Maps without the default flag shadow.
Future<gm.BitmapDescriptor> createRawanaMapMarkerIcon({
  required IconData icon,
  required Color color,
  double size = 40,
}) async {
  if (_isBikeIcon(icon)) {
    return _createBikeMarkerIcon(color: color, size: size);
  }
  if (_isVehicleIcon(icon)) {
    return _createTaxiMarkerIcon(
      color: color,
      size: size,
      premium: _isPremiumIcon(icon),
      xl: _isXlIcon(icon),
    );
  }
  if (_isCurrentLocationIcon(icon)) {
    return _createCurrentLocationIcon(size: size);
  }
  if (_isRiderIcon(icon)) {
    return _createRiderMarkerIcon(color: color, size: size);
  }
  if (_isFlagIcon(icon)) {
    return _createFlagMarkerIcon(color: color, size: size);
  }

  return _createBadgeMarkerIcon(icon: icon, color: color, size: size);
}

Future<gm.BitmapDescriptor> _createBadgeMarkerIcon({
  required IconData icon,
  required Color color,
  required double size,
}) async {
  final dpr = _devicePixelRatio();
  final pixelSize = (size * dpr).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(pixelSize / 2, pixelSize / 2);
  final radius = pixelSize / 2 - (2 * dpr);

  canvas.drawCircle(center, radius, Paint()..color = color);

  final ringPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5 * dpr;
  canvas.drawCircle(center, radius - (1.25 * dpr), ringPaint);

  _paintMaterialIcon(
    canvas: canvas,
    center: center,
    icon: icon,
    color: Colors.white,
    size: size * 0.52 * dpr,
  );

  return _descriptorFromPicture(recorder, pixelSize, pixelSize, dpr);
}

Future<gm.BitmapDescriptor> _createFlagMarkerIcon({
  required Color color,
  required double size,
}) async {
  final dpr = _devicePixelRatio();
  final pixelSize = (size * dpr).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(pixelSize / 2, pixelSize / 2);
  final radius = pixelSize / 2 - (2 * dpr);

  canvas.drawCircle(center, radius, Paint()..color = color);
  canvas.drawCircle(
    center,
    radius - (1.25 * dpr),
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * dpr,
  );

  final flagSize = size * 0.46 * dpr;
  final poleX = center.dx - flagSize * 0.28;
  final poleTop = center.dy - flagSize * 0.42;
  final poleBottom = center.dy + flagSize * 0.42;

  canvas.drawLine(
    Offset(poleX, poleTop),
    Offset(poleX, poleBottom),
    Paint()
      ..color = Colors.white
      ..strokeWidth = flagSize * 0.12
      ..strokeCap = StrokeCap.round,
  );

  final flagPath = Path()
    ..moveTo(poleX + flagSize * 0.08, poleTop + flagSize * 0.04)
    ..lineTo(poleX + flagSize * 0.72, poleTop + flagSize * 0.22)
    ..lineTo(poleX + flagSize * 0.08, poleTop + flagSize * 0.40)
    ..close();
  canvas.drawPath(flagPath, Paint()..color = Colors.white);

  return _descriptorFromPicture(recorder, pixelSize, pixelSize, dpr);
}

Future<gm.BitmapDescriptor> _createTaxiMarkerIcon({
  required Color color,
  required double size,
  bool premium = false,
  bool xl = false,
}) async {
  final dpr = _devicePixelRatio();
  final width = (size * 1.7 * dpr).ceil();
  final height = (size * 1.7 * dpr).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(width / 2, height / 2);
  final teal = premium ? const Color(0xFF1F6F6A) : const Color(0xFF2A9B94);
  final tealDark = premium ? const Color(0xFF134844) : const Color(0xFF1A6F6A);
  final tealLight = premium ? const Color(0xFF3D8F89) : const Color(0xFF4EC4BB);

  canvas.save();
  canvas.translate(center.dx, center.dy);

  final carLength = size * (xl ? 1.12 : 1.0) * dpr;
  final carWidth = size * (xl ? 0.62 : 0.52) * dpr;

  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(0, carLength * 0.18),
      width: carWidth * 1.15,
      height: carLength * 0.42,
    ),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * dpr),
  );

  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: carWidth, height: carLength),
    Radius.circular(carWidth * 0.34),
  );
  canvas.drawRRect(
    body,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-carWidth / 2, -carLength / 2),
        Offset(carWidth / 2, carLength / 2),
        [tealLight, teal, tealDark],
        const [0, 0.45, 1],
      ),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(-carWidth * 0.48, -carLength * 0.42, carWidth * 0.14, carLength * 0.78),
      Radius.circular(8 * dpr),
    ),
    Paint()..color = Colors.white.withValues(alpha: 0.22),
  );

  final roof = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(0, carLength * 0.04),
      width: carWidth * 0.72,
      height: carLength * 0.42,
    ),
    Radius.circular(8 * dpr),
  );
  canvas.drawRRect(roof, Paint()..color = tealDark.withValues(alpha: 0.55));

  final glass = Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, -carLength * 0.36),
      Offset(0, carLength * 0.28),
      const [Color(0xFF1B2833), Color(0xFF3A4A55)],
    );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -carLength * 0.22),
        width: carWidth * 0.62,
        height: carLength * 0.18,
      ),
      Radius.circular(5 * dpr),
    ),
    glass,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, carLength * 0.20),
        width: carWidth * 0.56,
        height: carLength * 0.14,
      ),
      Radius.circular(4 * dpr),
    ),
    glass,
  );

  final wheel = Paint()..color = const Color(0xFF1A1F24);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-carWidth * 0.46, -carLength * 0.16),
        width: carWidth * 0.14,
        height: carLength * 0.20,
      ),
      Radius.circular(3 * dpr),
    ),
    wheel,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(carWidth * 0.46, -carLength * 0.16),
        width: carWidth * 0.14,
        height: carLength * 0.20,
      ),
      Radius.circular(3 * dpr),
    ),
    wheel,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(-carWidth * 0.46, carLength * 0.20),
        width: carWidth * 0.14,
        height: carLength * 0.20,
      ),
      Radius.circular(3 * dpr),
    ),
    wheel,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(carWidth * 0.46, carLength * 0.20),
        width: carWidth * 0.14,
        height: carLength * 0.20,
      ),
      Radius.circular(3 * dpr),
    ),
    wheel,
  );

  canvas.drawCircle(
    Offset(-carWidth * 0.22, -carLength * 0.44),
    2.2 * dpr,
    Paint()..color = const Color(0xFFFFF3C4),
  );
  canvas.drawCircle(
    Offset(carWidth * 0.22, -carLength * 0.44),
    2.2 * dpr,
    Paint()..color = const Color(0xFFFFF3C4),
  );
  canvas.restore();

  return _descriptorFromPicture(recorder, width, height, dpr);
}

Future<gm.BitmapDescriptor> _createCurrentLocationIcon({
  required double size,
}) async {
  final dpr = _devicePixelRatio();
  final pixelSize = (size * 1.7 * dpr).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(pixelSize / 2, pixelSize / 2);
  const fill = Color(0xFF1A73E8);

  canvas.drawCircle(
    center,
    pixelSize * 0.42,
    Paint()..color = fill.withValues(alpha: 0.18),
  );
  canvas.drawCircle(
    center,
    pixelSize * 0.22,
    Paint()..color = Colors.white,
  );
  canvas.drawCircle(
    center,
    pixelSize * 0.155,
    Paint()..color = fill,
  );

  return _descriptorFromPicture(recorder, pixelSize, pixelSize, dpr);
}

Future<gm.BitmapDescriptor> _createRiderMarkerIcon({
  required Color color,
  required double size,
}) async {
  final dpr = _devicePixelRatio();
  final pixelSize = (size * dpr).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(pixelSize / 2, pixelSize / 2);
  final radius = pixelSize / 2 - 3 * dpr;

  canvas.drawCircle(center, radius, Paint()..color = Colors.white);
  canvas.drawCircle(
    center,
    radius - 1.2 * dpr,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * dpr,
  );

  canvas.drawCircle(center, radius * 0.62, Paint()..color = color);

  _paintMaterialIcon(
    canvas: canvas,
    center: center,
    icon: Icons.person,
    color: Colors.white,
    size: size * 0.38 * dpr,
  );

  return _descriptorFromPicture(recorder, pixelSize, pixelSize, dpr);
}

void _paintMaterialIcon({
  required Canvas canvas,
  required Offset center,
  required IconData icon,
  required Color color,
  required double size,
}) {
  final painter = TextPainter(textDirection: TextDirection.ltr);
  painter.text = TextSpan(
    text: String.fromCharCode(icon.codePoint),
    style: TextStyle(
      fontSize: size,
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: color,
      height: 1,
      fontWeight: FontWeight.normal,
    ),
  );
  painter.layout();
  painter.paint(
    canvas,
    center - Offset(painter.width / 2, painter.height / 2),
  );
}

Future<gm.BitmapDescriptor> _descriptorFromPicture(
  ui.PictureRecorder recorder,
  int width,
  int height,
  double dpr,
) async {
  final image = await recorder.endRecording().toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return gm.BitmapDescriptor.bytes(
    byteData!.buffer.asUint8List(),
    imagePixelRatio: dpr,
  );
}

double _devicePixelRatio() {
  final views = ui.PlatformDispatcher.instance.views;
  return views.isNotEmpty ? views.first.devicePixelRatio : 2.0;
}

Future<gm.BitmapDescriptor> _createBikeMarkerIcon({
  required Color color,
  required double size,
}) async {
  final dpr = _devicePixelRatio();
  final width = (size * 1.7 * dpr).ceil();
  final height = (size * 1.7 * dpr).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(width / 2, height / 2);
  const teal = Color(0xFF2A9B94);
  const tealDark = Color(0xFF1A6F6A);

  canvas.save();
  canvas.translate(center.dx, center.dy);

  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, 8 * dpr), width: 22 * dpr, height: 12 * dpr),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * dpr),
  );

  final wheel = Paint()
    ..color = const Color(0xFF1A1F24)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.2 * dpr;
  canvas.drawCircle(Offset(0, -14 * dpr), 7.2 * dpr, wheel);
  canvas.drawCircle(Offset(0, 14 * dpr), 8.2 * dpr, wheel);
  canvas.drawCircle(Offset(0, -14 * dpr), 2.4 * dpr, Paint()..color = teal);
  canvas.drawCircle(Offset(0, 14 * dpr), 2.6 * dpr, Paint()..color = teal);

  final body = Path()
    ..moveTo(-3 * dpr, -10 * dpr)
    ..quadraticBezierTo(8 * dpr, -4 * dpr, 4 * dpr, 8 * dpr)
    ..quadraticBezierTo(-2 * dpr, 12 * dpr, -5 * dpr, 6 * dpr)
    ..quadraticBezierTo(-8 * dpr, 0, -3 * dpr, -10 * dpr)
    ..close();
  canvas.drawPath(
    body,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(-8 * dpr, -12 * dpr),
        Offset(8 * dpr, 12 * dpr),
        const [Color(0xFF4EC4BB), teal, tealDark],
        const [0, 0.5, 1],
      ),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -11 * dpr), width: 12 * dpr, height: 3.2 * dpr),
      Radius.circular(2 * dpr),
    ),
    Paint()..color = const Color(0xFF1A1F24),
  );
  canvas.drawCircle(Offset(-5 * dpr, -12 * dpr), 1.6 * dpr, Paint()..color = tealDark);
  canvas.drawCircle(Offset(5 * dpr, -12 * dpr), 1.6 * dpr, Paint()..color = tealDark);
  canvas.restore();

  return _descriptorFromPicture(recorder, width, height, dpr);
}

bool _isVehicleIcon(IconData icon) =>
    icon.codePoint == Icons.local_taxi.codePoint ||
    icon.codePoint == Icons.directions_car.codePoint ||
    icon.codePoint == Icons.airport_shuttle.codePoint;

bool _isBikeIcon(IconData icon) =>
    icon.codePoint == Icons.two_wheeler.codePoint ||
    icon.codePoint == Icons.motorcycle.codePoint;

bool _isPremiumIcon(IconData icon) =>
    icon.codePoint == Icons.directions_car.codePoint;

bool _isXlIcon(IconData icon) =>
    icon.codePoint == Icons.airport_shuttle.codePoint;

bool _isCurrentLocationIcon(IconData icon) =>
    icon.codePoint == Icons.my_location.codePoint ||
    icon.codePoint == Icons.my_location_outlined.codePoint;

bool _isRiderIcon(IconData icon) =>
    icon.codePoint == Icons.person.codePoint ||
    icon.codePoint == Icons.person_pin_circle.codePoint;

bool _isFlagIcon(IconData icon) =>
    icon.codePoint == Icons.flag.codePoint ||
    icon.codePoint == Icons.outlined_flag.codePoint ||
    icon.codePoint == Icons.flag_rounded.codePoint;

String rawanaMapMarkerIconKey(IconData icon, Color color, double size) =>
    '${icon.codePoint}_${icon.fontFamily}_${icon.fontPackage}_${color.toARGB32()}_$size';
