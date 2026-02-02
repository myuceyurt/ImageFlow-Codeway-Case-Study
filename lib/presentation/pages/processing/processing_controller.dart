import 'dart:io';
import 'package:get/get.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class ProcessingController extends GetxController {
  final ImageProcessingService _imageProcessingService = Get.find();

  late String originalImagePath;
  late ScanType scanType;
  
  final RxString statusMessage = 'Initializing...'.obs;
  final RxDouble progress = 0.0.obs;
  final RxBool hasError = false.obs;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    originalImagePath = args['imagePath'] as String;
    
    // Default to face if not provided, though it should be.
    if (args.containsKey('type')) {
       scanType = args['type'] as ScanType;
    } else {
       scanType = ScanType.face;
    }

    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      hasError.value = false;
      progress.value = 0.1;
      statusMessage.value = 'Loading image...';
      
      final originalFile = File(originalImagePath);
      if (!await originalFile.exists()) {
        throw Exception('Image file not found');
      }

      // Simulate some steps for UX if needed, or update progress during actual processing if service supports it
      await Future.delayed(const Duration(milliseconds: 500)); 
      progress.value = 0.3;
      statusMessage.value = scanType == ScanType.face 
          ? 'Detecting faces and contours...' 
          : 'Scanning document text...';

      File processedFile;
      
      // Auto-switch logic: If face mode, check for faces first.
      if (scanType == ScanType.face) {
        final hasFaces = await _imageProcessingService.hasFaces(originalFile);
        if (!hasFaces) {
          // Switch to document mode if no faces found
          scanType = ScanType.document;
          statusMessage.value = 'No faces detected. Switching to document scan...';
          await Future.delayed(const Duration(milliseconds: 1000)); // Show message briefly
        }
      }

      if (scanType == ScanType.face) {
        statusMessage.value = 'Processing face...';
        processedFile = await _imageProcessingService.processFaceFlow(originalFile);
      } else {
        // Document Flow
        statusMessage.value = 'Recognizing text...';
        
        // Note: For document flow, we might need text detection first if the service requires it separately
        final detectedText = await _imageProcessingService.detectText(originalFile);
        
        progress.value = 0.6;
        statusMessage.value = 'Enhancing document...';
        
        processedFile = await _imageProcessingService.processDocumentFlow(originalFile, detectedText);
      }

      progress.value = 1.0;
      statusMessage.value = 'Processing complete!';
      
      await Future.delayed(const Duration(milliseconds: 500)); // Show complete state briefly

      Get.offNamed<void>(
        Routes.RESULT,
        arguments: {
           'imagePath': originalImagePath,
           'processedFile': processedFile,
           'type': scanType,
        },
      );

    } catch (e) {
      hasError.value = true;
      errorMessage = e.toString();
      statusMessage.value = 'Processing failed.';
    }
  }

  void retry() {
    _startProcessing();
  }

  void goBack() {
    Get.back<void>();
  }
}
