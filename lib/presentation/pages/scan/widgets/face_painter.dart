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

    double imageWidth = imageSize.width;
    double imageHeight = imageSize.height;

    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      imageWidth = imageSize.height;
      imageHeight = imageSize.width;
    }

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double offsetX = (size.width - imageWidth * scale) / 2;
    final double offsetY = (size.height - imageHeight * scale) / 2;

    for (final face in faces) {
      final rect = face.boundingBox;
      


      
      double left = rect.left * scale + offsetX;
      double top = rect.top * scale + offsetY;
      double right = rect.right * scale + offsetX;
      double bottom = rect.bottom * scale + offsetY;


      if (cameraLensDirection == CameraLensDirection.front) {

        final centerX = size.width / 2;
        left = centerX + (centerX - left);
        right = centerX + (centerX - right);
        

        final temp = left;
        left = right;
        right = temp;
      }

      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.cameraLensDirection != cameraLensDirection;
  }
}
