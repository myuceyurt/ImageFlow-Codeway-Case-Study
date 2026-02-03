import 'dart:io';
import 'package:get/get.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/core/services/pdf_service.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class ProcessingController extends GetxController {
  final ImageProcessingService _imageProcessingService = Get.find();
  final PdfService _pdfService = PdfService();

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
      if (!originalFile.existsSync()) {
        throw Exception('Image file not found');
      }

      await Future<void>.delayed(const Duration(milliseconds: 350));
      progress.value = 0.3;
      statusMessage.value = scanType == ScanType.face
          ? 'Detecting faces and contours...'
          : 'Scanning document text...';

      File processedFile;
      File thumbnailFile;
      
      if (scanType == ScanType.face) {
        final hasFaces = await _imageProcessingService.hasFaces(originalFile);
        if (!hasFaces) {
          scanType = ScanType.document;
          statusMessage.value =
              'No faces detected. Switching to document scan...';
          await Future<void>.delayed(const Duration(milliseconds: 900));
        }
      }

      if (scanType == ScanType.face) {
        statusMessage.value = 'Processing face...';
        processedFile = await _imageProcessingService.processFaceFlow(
          originalFile,
        );
        thumbnailFile = processedFile;
      } else {
        statusMessage.value = 'Recognizing text...';
        
        final detectedText = await _imageProcessingService.detectText(
          originalFile,
        );
        
        progress.value = 0.6;
        statusMessage.value = 'Enhancing document...';
        
        final enhancedImage = await _imageProcessingService.processDocumentFlow(
          originalFile,
          detectedText,
        );
        thumbnailFile = enhancedImage;

        progress.value = 0.85;
        statusMessage.value = 'Creating PDF...';
        processedFile = await _pdfService.generatePdfFromImage(enhancedImage);
      }

      progress.value = 1.0;
      statusMessage.value = 'Processing complete!';
      
      await Future<void>.delayed(const Duration(milliseconds: 350));

      await Get.offNamed<void>(
        Routes.result,
        arguments: {
           'imagePath': originalImagePath,
           'processedFile': processedFile,
           'thumbnailFile': thumbnailFile,
           'type': scanType,
        },
      );

    } catch (e) {
      hasError.value = true;
      errorMessage = e.toString();
      statusMessage.value = 'Processing failed.';
    }
  }

  Future<void> retry() async {
    await _startProcessing();
  }

  void goBack() {
    Get.back<void>();
  }
}
