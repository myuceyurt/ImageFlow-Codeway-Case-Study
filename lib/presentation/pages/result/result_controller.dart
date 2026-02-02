import 'dart:io';

import 'package:get/get.dart';

import 'package:image_flow/core/services/image_processing_service.dart';

class ResultController extends GetxController {
  final ImageProcessingService _imageProcessingService = Get.find();

  String? originalImagePath;
  String? processedImagePath;

  
  bool isLoading = true;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    originalImagePath = args['imagePath'] as String;
    
    _processImage();
  }

  Future<void> _processImage() async {
    if (originalImagePath == null) {
      errorMessage = 'No image captured';
      isLoading = false;
      update();
      return;
    }

    try {
      final originalFile = File(originalImagePath!);
      final processedFile = await _imageProcessingService.processFaceFlow(
        originalFile,
      );
      
      processedImagePath = processedFile.path;
      isLoading = false;
    } catch (e) {
      errorMessage = 'Processing failed: $e';
      isLoading = false;
    }
    update();
  }
  
  void goBack() {
    Get.back<void>();
  }
}
