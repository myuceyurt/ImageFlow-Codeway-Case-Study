import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class ResultController extends GetxController {
  late String originalImagePath;
  late String resultFilePath;
  late String thumbnailPath;
  ScanType scanType = ScanType.face;

  bool isLoading = false;
  String? errorMessage;
  bool _isSaved = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    
    if (args['imagePath'] != null) {
      originalImagePath = args['imagePath'] as String;
    }
    
    if (args['processedFile'] != null) {
      resultFilePath = (args['processedFile'] as File).path;
    } else {
      errorMessage = 'No result file found';
    }

    if (args['thumbnailFile'] != null) {
      thumbnailPath = (args['thumbnailFile'] as File).path;
    } else {
      thumbnailPath = resultFilePath;
    }
    
    if (args.containsKey('type')) {
      scanType = args['type'] as ScanType;
    }
  }

  Future<void> complete() async {
    try {
      await _saveToHistoryIfNeeded();
      await Get.offAllNamed<void>(Routes.home);
    } catch (e) {
      errorMessage = 'Save failed: $e';
      isLoading = false;
      update();
    }
  }

  Future<void> openPdf() async {
    try {
      await _saveToHistoryIfNeeded();
      final result = await OpenFile.open(resultFilePath);
      if (result.type != ResultType.done) {
        Get.snackbar('Error', 'Could not open PDF: ${result.message}');
        return;
      }
      await Get.offAllNamed<void>(Routes.home);
    } catch (e) {
      errorMessage = 'Open failed: $e';
      isLoading = false;
      update();
    }
  }

  Future<void> _saveToHistoryIfNeeded() async {
    if (_isSaved) return;
    if (isLoading) return;
    isLoading = true;
    update();

    final box = Hive.box<ScanModel>('scans');
    final scan = ScanModel(
      id: const Uuid().v4(),
      date: DateTime.now(),
      type: scanType,
      resultFilePath: resultFilePath,
      originalFilePath: originalImagePath,
      thumbnailPath: thumbnailPath,
    );
    await box.add(scan);
    _isSaved = true;
    isLoading = false;
    update();
  }
  
  void goBack() {
    Get.back<void>();
  }
}
