import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_flow/core/errors/app_exception.dart';
import 'package:image_flow/core/services/detection_service.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  CameraController? cameraController;
  
  final RxList<Face> detectedFaces = <Face>[].obs;
  final Rx<RecognizedText?> recognizedText = Rx<RecognizedText?>(null);
  final Rx<ScanType> scanType = ScanType.face.obs;
  
  bool _isBusy = false;
  
  bool isInitialized = false;
  bool documentOnly = false;
  int _cameraIndex = 0;
  List<CameraDescription> _cameras = [];
  
  late final DetectionService _detectionService;
  late final ImageProcessingService _imageProcessingService;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['documentOnly'] == true) {
      documentOnly = true;
      scanType.value = ScanType.document;
    }
    _detectionService = Get.find<DetectionService>();
    _imageProcessingService = Get.find<ImageProcessingService>();
    _initializeCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  void setScanType(ScanType type) {
    scanType.value = type;
    detectedFaces.clear();
    recognizedText.value = null;
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      Get.snackbar(
        'Permission Required',
        'Camera permission is permanently denied. Please enable it in settings.',
        duration: const Duration(seconds: 4),
      );
      return;
    }
    if (status.isDenied) {
      Get.snackbar(
        'Permission Required',
        'Camera permission is required to scan.',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw const CameraPermissionException('No cameras found on device');
      }
      
      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_cameraIndex == -1) _cameraIndex = 0;

      await _startCamera(_cameras[_cameraIndex]);
    } on CameraPermissionException catch (e) {
      Get.snackbar('Camera Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize camera');
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
    } on CameraPermissionException catch (e) {
      Get.snackbar('Camera Error', e.message);
    } catch (e) {
      Get.snackbar('Error', 'Camera initialization failed');
    }
  }

  void _processImageStream(CameraImage image) {
    if (_isBusy) return;
    _isBusy = true;

    Future<void>(() async {
      try {
        final camera = _cameras[_cameraIndex];
        final result = await _detectionService.detectFromCameraImage(
          image,
          camera,
          documentOnly: documentOnly,
        );

        if (result.hasFaces) {
          if (scanType.value != ScanType.face) {
            scanType.value = ScanType.face;
          }
          detectedFaces.value = result.faces;
          recognizedText.value = null;
        } else if (result.hasText) {
          if (scanType.value != ScanType.document) {
            scanType.value = ScanType.document;
          }
          recognizedText.value = result.text;
          detectedFaces.clear();
        } else {
          detectedFaces.clear();
          recognizedText.value = null;
        }
      } on DetectionException {
        detectedFaces.clear();
        recognizedText.value = null;
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

  Future<List<String>?> captureImage() async {
    if (scanType.value == ScanType.document || documentOnly) {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }

      DocumentScanner? documentScanner;
      try {
        documentScanner = DocumentScanner(
          options: DocumentScannerOptions(),
        );

        final result = await documentScanner.scanDocument();
        var closed = false;
        try {
          await documentScanner.close();
          closed = true;
        } catch (_) {}
        if (closed) {
          documentScanner = null;
        }

        if (cameraController != null &&
            !cameraController!.value.isStreamingImages) {
          await cameraController!.startImageStream(_processImageStream);
        }

        if (result.images.isNotEmpty) {
          return result.images;
        }
        return null;
      } on MissingPluginException {
        Get.snackbar(
          'Plugin Error',
          'Document scanner not available. Please restart the app.',
        );
        if (cameraController != null &&
            !cameraController!.value.isStreamingImages) {
          await cameraController!.startImageStream(_processImageStream);
        }
        return null;
      } catch (e) {
        Get.snackbar('Scan Failed', 'Document scanning failed. Please try again.');
        if (cameraController != null &&
            !cameraController!.value.isStreamingImages) {
          await cameraController!.startImageStream(_processImageStream);
        }
        return null;
      } finally {
        final scanner = documentScanner;
        if (scanner != null) {
          try {
            await scanner.close();
          } catch (_) {}
        }
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
      
      return [xFile.path];
    } catch (e) {
      Get.snackbar('Capture Failed', 'Failed to capture image. Please try again.');
      return null;
    }
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        await cameraController!.stopImageStream();
      }

      try {
        final file = File(image.path);
        if (documentOnly) {
          final text = await _imageProcessingService.detectText(file);
          if (text.blocks.isEmpty) {
            Get.snackbar('No Document', 'No text detected in the image.');
            await _restartCameraStream();
            return;
          }

          await _restartCameraStream();
          await Get.toNamed<void>(
            Routes.processing,
            arguments: {
              'imagePath': image.path,
              'type': ScanType.document,
              'documentSession': true,
              'startNewSession': false,
            },
          );
          return;
        }
        final hasFaces = await _imageProcessingService.hasFaces(file);
        if (hasFaces) {
          await _restartCameraStream();
          await Get.toNamed<void>(
            Routes.processing,
            arguments: {
              'imagePath': image.path,
              'type': ScanType.face,
            },
          );
          return;
        }

        final text = await _imageProcessingService.detectText(file);
        if (text.blocks.isEmpty) {
          Get.snackbar('Nothing Detected', 'No face or document found in the image.');
          await _restartCameraStream();
          return;
        }

        await _restartCameraStream();
        await Get.toNamed<void>(
          Routes.processing,
          arguments: {
            'imagePath': image.path,
            'type': ScanType.document,
            'documentSession': true,
            'startNewSession': true,
          },
        );
      } on DetectionException catch (e) {
        Get.snackbar('Detection Failed', e.message);
        await _restartCameraStream();
      } catch (e) {
        Get.snackbar('Error', 'Failed to process image from gallery.');
        await _restartCameraStream();
      }
    }
  }

  Future<void> _restartCameraStream() async {
    if (cameraController != null &&
        !cameraController!.value.isStreamingImages) {
      await cameraController!.startImageStream(_processImageStream);
    }
  }
}
