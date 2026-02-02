import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/core/services/pdf_service.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:uuid/uuid.dart';

class ResultController extends GetxController {
  final PdfService _pdfService = PdfService();

  late String originalImagePath;
  late String processedImagePath;
  ScanType scanType = ScanType.face;

  bool isLoading = false;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    
    if (args['imagePath'] != null) {
      originalImagePath = args['imagePath'] as String;
    }
    
    if (args['processedFile'] != null) {
      processedImagePath = (args['processedFile'] as File).path;
    } else {
       // Should not happen if coming from Processing Screen
       errorMessage = 'No processed image found';
    }
    
    if (args.containsKey('type')) {
      scanType = args['type'] as ScanType;
    }
  }

  Future<void> saveResult() async {
    try {
      isLoading = true;
      update();

      var finalResultPath = processedImagePath;

      if (scanType == ScanType.document) {
        final pdfFile = await _pdfService.generatePdfFromImage(
          File(processedImagePath),
        );
        finalResultPath = pdfFile.path;
      }

      final box = Hive.box<ScanModel>('scans');
      
      final scan = ScanModel(
        id: const Uuid().v4(),
        date: DateTime.now(),
        type: scanType,
        resultFilePath: finalResultPath,
        originalFilePath: originalImagePath,
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
