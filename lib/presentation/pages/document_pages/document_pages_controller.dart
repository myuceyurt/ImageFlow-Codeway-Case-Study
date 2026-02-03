import 'dart:io';

import 'package:get/get.dart';
import 'package:image_flow/core/services/pdf_service.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/controllers/document_session_controller.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';

class DocumentPagesController extends GetxController {
  final DocumentSessionController _session = Get.find();
  final PdfService _pdfService = PdfService();

  final RxBool isExporting = false.obs;

  List<DocumentPage> get pages => _session.pages;

  void reorder(int oldIndex, int newIndex) {
    _session.reorder(oldIndex, newIndex);
  }

  void removePage(DocumentPage page) {
    _session.removeById(page.id);
  }

  Future<void> addPage() async {
    await Get.toNamed<void>(
      Routes.scan,
      arguments: {
        'documentOnly': true,
      },
    );
  }

  Future<void> exportPdf() async {
    if (pages.isEmpty) {
      Get.snackbar('Pages', 'Add at least one page');
      return;
    }
    if (isExporting.value) return;
    isExporting.value = true;
    try {
      final files = pages.map((page) => File(page.processedPath)).toList();
      final pdfFile = await _pdfService.generatePdfFromImages(files);
      final firstPage = pages.first;
      _session.clear();
      await Get.offNamed<void>(
        Routes.result,
        arguments: {
          'imagePath': firstPage.originalPath,
          'processedFile': pdfFile,
          'thumbnailFile': File(firstPage.thumbnailPath),
          'type': ScanType.document,
        },
      );
    } catch (e) {
      Get.snackbar('Error', 'Export failed: $e');
      isExporting.value = false;
    }
  }

  void cancel() {
    _session.clear();
    Get.offAllNamed<void>(Routes.home);
  }
}
