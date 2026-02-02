import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_flow/core/utils/camera_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanController extends GetxController {
  CameraController? cameraController;
  final RxList<Face> detectedFaces = <Face>[].obs;
  
  bool _isBusy = false;
  
  bool isInitialized = false;
  int _cameraIndex = 0;
  List<CameraDescription> _cameras = [];
  
  late final FaceDetector _faceDetector;

  @override
  void onInit() {
    super.onInit();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    _initializeCamera();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    _faceDetector.close();
    super.onClose();
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
        (c) => c.lensDirection == CameraLensDirection.back,
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

    // Use Future to avoid void async
    Future<void>(() async {
      try {
        final camera = _cameras[_cameraIndex];
        final inputImage = CameraUtils.convertCameraImageToInputImage(
          image,
          camera,
        );

        final faces = await _faceDetector.processImage(inputImage);
        detectedFaces.value = faces;
      } catch (e) {
        if (kDebugMode) print('Face detection error: $e');
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
