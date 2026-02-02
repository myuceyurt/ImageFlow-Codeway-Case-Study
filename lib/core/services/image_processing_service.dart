import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_flow/core/errors/app_exception.dart';
import 'package:image_flow/core/services/file_service.dart';

class ImageProcessingService {
  ImageProcessingService(this._fileService);

  final FileService _fileService;

  /// Processes the image for the Face Flow:
  /// 1. Decodes image in isolate.
  /// 2. Crops faces (with padding).
  /// 3. Grayscales faces.
  /// 4. Composites them back.
  Future<File> processFaceFlow(
    File originalImage,
    List<Face> detectedFaces,
  ) async {
    try {
      final imageBytes = await originalImage.readAsBytes();

      // We pass a simple map or DTO to the isolate to avoid sending complex
      // objects if they aren't compatible, but Face and Rect are sendable.
      // However, ML Kit Face object might contain native handles,
      // so we extract Rects.
      final faceRects = detectedFaces.map((f) => f.boundingBox).toList();

      final processedBytes = await compute(
        _isolateProcessFaces,
        _FaceProcessRequest(imageBytes, faceRects),
      );

      return await _fileService.saveImageFile(processedBytes);
    } catch (e) {
      throw AppException('Failed to process face flow: $e');
    }
  }

  /// Processes the image for the Document Flow:
  /// 1. Decodes image in isolate.
  /// 2. Crops to bounding box of all text.
  /// 3. Enhances contrast/brightness.
  Future<File> processDocumentFlow(
    File originalImage,
    RecognizedText detectedText,
  ) async {
    try {
      final imageBytes = await originalImage.readAsBytes();

      // Calculate global bounding box for all text blocks
      Rect? globalRect;
      for (final block in detectedText.blocks) {
        if (globalRect == null) {
          globalRect = block.boundingBox;
        } else {
          globalRect = globalRect.expandToInclude(block.boundingBox);
        }
      }

      if (globalRect == null) {
        throw const AppException('No text detected to process.');
      }

      final processedBytes = await compute(
        _isolateProcessDocument,
        _DocProcessRequest(imageBytes, globalRect),
      );

      return await _fileService.saveImageFile(processedBytes);
    } catch (e) {
      throw AppException('Failed to process document flow: $e');
    }
  }
}

// --- Isolate Data Classes ---

class _FaceProcessRequest {
  _FaceProcessRequest(this.imageBytes, this.faceRects);
  final Uint8List imageBytes;
  final List<Rect> faceRects;
}

class _DocProcessRequest {
  _DocProcessRequest(this.imageBytes, this.cropRect);
  final Uint8List imageBytes;
  final Rect cropRect;
}

// --- Isolate Functions ---

Future<Uint8List> _isolateProcessFaces(_FaceProcessRequest request) async {
  // 1. Decode Image (Image v4)
  final decodedImage = img.decodeImage(request.imageBytes);
  if (decodedImage == null) throw Exception('Failed to decode image');

  // 2. Bake Orientation (CRITICAL for ML Kit coordinates)
  final orientedImage = img.bakeOrientation(decodedImage);

  for (final rect in request.faceRects) {
    // Convert Rect to integer coordinates
    var x = rect.left.toInt();
    var y = rect.top.toInt();
    var w = rect.width.toInt();
    var h = rect.height.toInt();

    // Add 10% padding
    final paddingW = (w * 0.1).toInt();
    final paddingH = (h * 0.1).toInt();

    x = math.max(0, x - paddingW);
    y = math.max(0, y - paddingH);
    w = math.min(orientedImage.width - x, w + (paddingW * 2));
    h = math.min(orientedImage.height - y, h + (paddingH * 2));

    // Ensure valid crop dimensions
    if (w <= 0 || h <= 0) continue;

    // 3. Crop Face
    final faceCrop = img.copyCrop(
      orientedImage,
      x: x,
      y: y,
      width: w,
      height: h,
    );

    // 4. Apply Grayscale
    final grayscaleFace = img.grayscale(faceCrop);

    // 5. Composite back
    img.compositeImage(orientedImage, grayscaleFace, dstX: x, dstY: y);
  }

  // 6. Encode as JPG
  return img.encodeJpg(orientedImage);
}

Future<Uint8List> _isolateProcessDocument(_DocProcessRequest request) async {
  // 1. Decode Image
  final decodedImage = img.decodeImage(request.imageBytes);
  if (decodedImage == null) throw Exception('Failed to decode image');

  // 2. Bake Orientation
  final orientedImage = img.bakeOrientation(decodedImage);

  // 3. Crop to Bounding Box (with some padding)
  var x = request.cropRect.left.toInt();
  var y = request.cropRect.top.toInt();
  var w = request.cropRect.width.toInt();
  var h = request.cropRect.height.toInt();

  // Add small padding for document
  const padding = 20;
  x = math.max(0, x - padding);
  y = math.max(0, y - padding);
  w = math.min(orientedImage.width - x, w + (padding * 2));
  h = math.min(orientedImage.height - y, h + (padding * 2));

  if (w <= 0 || h <= 0) throw Exception('Invalid crop dimensions');

  final docCrop = img.copyCrop(orientedImage, x: x, y: y, width: w, height: h);

  // 4. Adjust Color (Contrast/Brightness) - Mimic scan effect
  // Image v4 uses adjustColor
  final enhancedDoc = img.adjustColor(
    docCrop,
    contrast: 1.2, // Increase contrast
    brightness: 1.1, // Slight brightness increase
  );

  // 5. Encode
  return img.encodeJpg(enhancedDoc);
}
