import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_flow/core/utils/camera_utils.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  CameraController? cameraController;
  
  final RxList<Face> detectedFaces = <Face>[].obs;
  final Rx<RecognizedText?> recognizedText = Rx<RecognizedText?>(null);
  final Rx<ScanType> scanType = ScanType.face.obs;
  
  bool _isBusy = false;
  
  bool isInitialized = false;
  int _cameraIndex = 0;
  List<CameraDescription> _cameras = [];
  
  late final FaceDetector _faceDetector;
  late final TextRecognizer _textRecognizer;

  @override
  void onInit() {
    super.onInit();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    _textRecognizer = TextRecognizer();
    _initializeCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _faceDetector.close();
    _textRecognizer.close();
    super.onClose();
  }

  void setScanType(ScanType type) {
    scanType.value = type;
    detectedFaces.clear();
    recognizedText.value = null;
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied || status.isDenied) {
      await Get.dialog<void>(
        const Center(
          child: Text('Camera permission required. Please enable in settings.'),
        ),
      );
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        Get.snackbar('Error', 'No cameras found on device');
        return;
      }
      
      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_cameraIndex == -1) _cameraIndex = 0;

      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize camera: $e');
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    cameraController = controller;
    
    try {
      await controller.initialize();
      if (!isInitialized) {
        isInitialized = true;
        update();
      }
      
      await controller.startImageStream(_processImageStream);
    } catch (e) {
      Get.snackbar('Error', 'Camera error: $e');
    }
  }

  void _processImageStream(CameraImage image) {
    if (_isBusy) return;
    _isBusy = true;

    Future<void>(() async {
      try {
        final camera = _cameras[_cameraIndex];
        final inputImage = CameraUtils.convertCameraImageToInputImage(
          image,
          camera,
        );

        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          if (scanType.value != ScanType.face) {
            scanType.value = ScanType.face;
          }
          detectedFaces.value = faces;
          recognizedText.value = null;
        } else {
          final text = await _textRecognizer.processImage(inputImage);
          if (text.blocks.isNotEmpty) {
             if (scanType.value != ScanType.document) {
               scanType.value = ScanType.document;
             }
             recognizedText.value = text;
             detectedFaces.clear();
          } else {
             detectedFaces.clear();
             recognizedText.value = null;
          }
        }
      } catch (e) {
        if (kDebugMode) print('Detection error: $e');
      } finally {
        _isBusy = false;
      }
    });
  }

  Future<void> toggleCamera() async {
    if (_cameras.length < 2) return;
    
    isInitialized = false;
    await cameraController?.dispose();
    cameraController = null;
    update();

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<String?> captureImage() async {
    if (scanType.value == ScanType.document) {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }

      try {
        final documentScanner = DocumentScanner(
          options: DocumentScannerOptions(),
        );

        final result = await documentScanner.scanDocument();
        await documentScanner.close();

        if (result.images.isNotEmpty) {
          if (cameraController != null &&
              !cameraController!.value.isStreamingImages) {
            await cameraController!.startImageStream(_processImageStream);
          }
          return result.images.first;
        } else {
          if (cameraController != null &&
              !cameraController!.value.isStreamingImages) {
            await cameraController!.startImageStream(_processImageStream);
          }
          return null;
        }
      } catch (e) {
        Get.snackbar('Error', 'Document scan failed: $e');
        if (cameraController != null &&
            !cameraController!.value.isStreamingImages) {
          await cameraController!.startImageStream(_processImageStream);
        }
        return null;
      }
    }


    if (cameraController == null || !cameraController!.value.isInitialized) {
      return null;
    }
    
    if (cameraController!.value.isStreamingImages) {
      await cameraController!.stopImageStream();
    }
    
    try {
      final xFile = await cameraController!.takePicture();
      
      await cameraController!.startImageStream(_processImageStream);
      
      return xFile.path;
    } catch (e) {
      Get.snackbar('Error', 'Capture failed: $e');
      return null;
    }
  }
}
