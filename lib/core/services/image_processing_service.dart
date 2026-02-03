import 'dart:async';
import 'dart:io';
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

  Future<bool> hasFaces(File image) async {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
      ),
    );
    try {
      final inputImage = InputImage.fromFile(image);
      final faces = await faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Face check failed: $e');
      return false;
    } finally {
      await faceDetector.close();
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
  ) async {
    try {
      final imageBytes = await originalImage.readAsBytes();

      final processedBytes = await compute(
        _isolateProcessDocument,
        _DocProcessRequest(imageBytes),
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
  _DocProcessRequest(this.imageBytes);
  final Uint8List imageBytes;
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

  final enhancedDoc = img.adjustColor(
    orientedImage,
    contrast: 1.2,
    brightness: 1.1,
  );


  return img.encodeJpg(enhancedDoc);
}
