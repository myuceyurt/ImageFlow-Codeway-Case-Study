import 'package:flutter/material.dart';

class ScannerGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final width = size.width * 0.85;
    final height = width * 1.414;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: height,
    );

    const cornerLength = 20.0;

    canvas
      ..drawLine(
        rect.topLeft,
        rect.topLeft + const Offset(cornerLength, 0),
        paint,
      )
      ..drawLine(
        rect.topLeft,
        rect.topLeft + const Offset(0, cornerLength),
        paint,
      )
      ..drawLine(
        rect.topRight,
        rect.topRight - const Offset(cornerLength, 0),
        paint,
      )
      ..drawLine(
        rect.topRight,
        rect.topRight + const Offset(0, cornerLength),
        paint,
      )
      ..drawLine(
        rect.bottomLeft,
        rect.bottomLeft + const Offset(cornerLength, 0),
        paint,
      )
      ..drawLine(
        rect.bottomLeft,
        rect.bottomLeft - const Offset(0, cornerLength),
        paint,
      )
      ..drawLine(
        rect.bottomRight,
        rect.bottomRight - const Offset(cornerLength, 0),
        paint,
      )
      ..drawLine(
        rect.bottomRight,
        rect.bottomRight - const Offset(0, cornerLength),
        paint,
      );

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas
      ..saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint())
      ..drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        overlayPaint,
      )
      ..drawRect(rect, Paint()..blendMode = BlendMode.dstOut)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
