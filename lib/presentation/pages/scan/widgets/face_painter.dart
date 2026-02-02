import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_flow/core/theme/app_theme.dart';

class FacePainter extends CustomPainter {
  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  final List<Face> faces;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppTheme.tawnyOwl;

    var imageWidth = imageSize.width;
    var imageHeight = imageSize.height;

    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      imageWidth = imageSize.height;
      imageHeight = imageSize.width;
    }

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;
    final scale = scaleX > scaleY ? scaleX : scaleY;

    final offsetX = (size.width - imageWidth * scale) / 2;
    final offsetY = (size.height - imageHeight * scale) / 2;

    for (final face in faces) {
      final contour = face.contours[FaceContourType.face];
      if (contour == null) continue;

      final path = Path();
      final points = contour.points;

      if (points.isEmpty) continue;

      final firstPoint = points.first;
      final (mappedX, mappedY) = _mapPoint(
        firstPoint.x.toDouble(),
        firstPoint.y.toDouble(),
        size,
        scale,
        offsetX,
        offsetY,
        imageWidth,
      );
      path.moveTo(mappedX, mappedY);

      for (var i = 1; i < points.length; i++) {
        final p = points[i];
        final (x, y) = _mapPoint(
          p.x.toDouble(),
          p.y.toDouble(),
          size,
          scale,
          offsetX,
          offsetY,
          imageWidth,
        );
        path.lineTo(x, y);
      }

      path.close();

      canvas.drawPath(path, paint);
    }
  }

  (double, double) _mapPoint(
    double x,
    double y,
    Size size,
    double scale,
    double offsetX,
    double offsetY,
    double imageWidth,
  ) {
    var mappedX = x * scale + offsetX;
    final mappedY = y * scale + offsetY;

    if (cameraLensDirection == CameraLensDirection.front) {
      final centerX = size.width / 2;
      mappedX = centerX + (centerX - mappedX);
    }

    return (mappedX, mappedY);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.cameraLensDirection != cameraLensDirection;
  }
}
