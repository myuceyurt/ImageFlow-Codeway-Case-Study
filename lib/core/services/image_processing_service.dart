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

  Future<RecognizedText> detectText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();
    try {
      return await textRecognizer.processImage(inputImage);
    } finally {
      await textRecognizer.close();
    }
  }


  Future<File> processFaceFlow(
    File originalImage,
  ) async {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
      ),
    );

    try {
      final inputImage = InputImage.fromFile(originalImage);
      final faces = await faceDetector.processImage(inputImage);


      final allContours = <List<img.Point>>[];

      for (final face in faces) {
        final contour = face.contours[FaceContourType.face];
        if (contour != null) {
          final points = contour.points
              .map((p) => img.Point(p.x, p.y))
              .toList();
          
          if (points.isNotEmpty) {
            allContours.add(points);
          }
        }
      }

      final imageBytes = await originalImage.readAsBytes();

      final processedBytes = await compute(
        _isolateProcessFaces,
        _FaceProcessRequest(imageBytes, allContours),
      );

      return await _fileService.saveImageFile(processedBytes);
    } catch (e) {
      throw AppException('Failed to process face flow: $e');
    } finally {
      await faceDetector.close();
    }
  }


  Future<File> processDocumentFlow(
    File originalImage,
    RecognizedText detectedText,
  ) async {
    try {
      final imageBytes = await originalImage.readAsBytes();


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



class _FaceProcessRequest {
  _FaceProcessRequest(this.imageBytes, this.contours);
  final Uint8List imageBytes;
  final List<List<img.Point>> contours;
}

class _DocProcessRequest {
  _DocProcessRequest(this.imageBytes, this.cropRect);
  final Uint8List imageBytes;
  final Rect cropRect;
}



Future<Uint8List> _isolateProcessFaces(_FaceProcessRequest request) async {

  var image = img.decodeImage(request.imageBytes);
  if (image == null) throw Exception('Failed to decode image');


  image = img.bakeOrientation(image);


  if (request.contours.isEmpty) {

    return img.encodeJpg(image);
  }


  final grayscaleImage = img.grayscale(image.clone());


  final mask = img.Image(width: image.width, height: image.height);
  img.fill(mask, color: img.ColorRgb8(0, 0, 0));

  for (final contour in request.contours) {
     img.fillPolygon(
       mask,
       vertices: contour,
       color: img.ColorRgb8(255, 255, 255),
     );
  }
  
  for (final pixel in image) {
    final maskPixel = mask.getPixel(pixel.x, pixel.y);
    if (maskPixel.r > 0) {
      final grayPixel = grayscaleImage.getPixel(pixel.x, pixel.y);
      pixel
        ..r = grayPixel.r
        ..g = grayPixel.g
        ..b = grayPixel.b;
    }
  }


  return img.encodeJpg(image);
}

Future<Uint8List> _isolateProcessDocument(_DocProcessRequest request) async {

  final decodedImage = img.decodeImage(request.imageBytes);
  if (decodedImage == null) throw Exception('Failed to decode image');


  final orientedImage = img.bakeOrientation(decodedImage);


  var x = request.cropRect.left.toInt();
  var y = request.cropRect.top.toInt();
  var w = request.cropRect.width.toInt();
  var h = request.cropRect.height.toInt();


  const padding = 20;
  x = math.max(0, x - padding);
  y = math.max(0, y - padding);
  w = math.min(orientedImage.width - x, w + (padding * 2));
  h = math.min(orientedImage.height - y, h + (padding * 2));

  if (w <= 0 || h <= 0) throw Exception('Invalid crop dimensions');

  final docCrop = img.copyCrop(orientedImage, x: x, y: y, width: w, height: h);


  final enhancedDoc = img.adjustColor(
    docCrop,
    contrast: 1.2,
    brightness: 1.1,
  );


  return img.encodeJpg(enhancedDoc);
}
