import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_flow/core/errors/app_exception.dart';
import 'package:image_flow/core/utils/camera_utils.dart';
import 'package:image_flow/data/models/scan_model.dart';

class DetectionResult {
  const DetectionResult({
    required this.scanType,
    this.faces = const [],
    this.text,
  });

  final ScanType scanType;
  final List<Face> faces;
  final RecognizedText? text;

  bool get hasFaces => faces.isNotEmpty;
  bool get hasText => text != null && text!.blocks.isNotEmpty;
}

class DetectionService {
  DetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    _textRecognizer = TextRecognizer();
  }

  late final FaceDetector _faceDetector;
  late final TextRecognizer _textRecognizer;

  Future<DetectionResult> detectFromCameraImage(
    CameraImage image,
    CameraDescription camera, {
    bool documentOnly = false,
  }) async {
    try {
      final inputImage = CameraUtils.convertCameraImageToInputImage(
        image,
        camera,
      );

      if (documentOnly) {
        final text = await _textRecognizer.processImage(inputImage);
        return DetectionResult(
          scanType: ScanType.document,
          text: text.blocks.isNotEmpty ? text : null,
        );
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isNotEmpty) {
        return DetectionResult(
          scanType: ScanType.face,
          faces: faces,
        );
      }

      final text = await _textRecognizer.processImage(inputImage);
      if (text.blocks.isNotEmpty) {
        return DetectionResult(
          scanType: ScanType.document,
          text: text,
        );
      }

      return const DetectionResult(scanType: ScanType.face);
    } catch (e) {
      throw DetectionException('Failed to process camera image: $e');
    }
  }

  Future<void> dispose() async {
    await _faceDetector.close();
    await _textRecognizer.close();
  }
}
