import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/core/services/pdf_service.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:uuid/uuid.dart';

class ResultController extends GetxController {
  final ImageProcessingService _imageProcessingService = Get.find();
  final PdfService _pdfService = PdfService();

  String? originalImagePath;
  String? processedImagePath;
  ScanType scanType = ScanType.face;

  bool isLoading = true;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    originalImagePath = args['imagePath'] as String;
    
    if (args.containsKey('processedFile')) {
      processedImagePath = (args['processedFile'] as File).path;
    }
    
    if (args.containsKey('type')) {
      scanType = args['type'] as ScanType;
    }

    if (processedImagePath == null) {
      _processImage();
    } else {
      isLoading = false;
    }
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
      File processedFile;

      if (scanType == ScanType.face) {
        processedFile = await _imageProcessingService.processFaceFlow(
          originalFile,
        );
      } else {
        processedFile = originalFile;
      }
      
      processedImagePath = processedFile.path;
      isLoading = false;
    } catch (e) {
      errorMessage = 'Processing failed: $e';
      isLoading = false;
    }
    update();
  }

  Future<void> saveResult() async {
    if (originalImagePath == null || processedImagePath == null) return;

    try {
      isLoading = true;
      update();

      var finalResultPath = processedImagePath!;

      if (scanType == ScanType.document) {
        final pdfFile = await _pdfService.generatePdfFromImage(
          File(processedImagePath!),
        );
        finalResultPath = pdfFile.path;
      }

      final box = Hive.box<ScanModel>('scans');
      
      final scan = ScanModel(
        id: const Uuid().v4(),
        date: DateTime.now(),
        type: scanType,
        resultFilePath: finalResultPath,
        originalFilePath: originalImagePath!,
        thumbnailPath: processedImagePath,
      );

      await box.add(scan);
      
      await Get.offAllNamed<void>(Routes.HOME);
    } catch (e) {
      errorMessage = 'Save failed: $e';
      isLoading = false;
      update();
    }
  }
  
  void goBack() {
    Get.back<void>();
  }
}
