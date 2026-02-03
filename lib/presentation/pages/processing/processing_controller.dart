import 'dart:io';
import 'package:get/get.dart';
import 'package:image_flow/core/errors/app_exception.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/core/services/pdf_service.dart';
import 'package:image_flow/data/models/scan_model.dart';
import 'package:image_flow/presentation/controllers/document_session_controller.dart';
import 'package:image_flow/presentation/routes/app_routes.dart';
import 'package:uuid/uuid.dart';

class ProcessingController extends GetxController {
  final ImageProcessingService _imageProcessingService = Get.find();
  final PdfService _pdfService = Get.find();
  late final DocumentSessionController _documentSession;
  final Uuid _uuid = const Uuid();

  late String originalImagePath;
  List<String> originalImagePaths = <String>[];
  late ScanType scanType;
  bool documentSession = false;
  bool startNewSession = false;
  
  final RxString statusMessage = 'Initializing...'.obs;
  final RxDouble progress = 0.0.obs;
  final RxBool hasError = false.obs;
  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    _documentSession = Get.find<DocumentSessionController>();
    final args = Get.arguments as Map<String, dynamic>;
    if (args['imagePaths'] != null) {
      originalImagePaths =
          (args['imagePaths'] as List<dynamic>).cast<String>();
      originalImagePath = originalImagePaths.first;
    } else {
      originalImagePath = args['imagePath'] as String;
      originalImagePaths = [originalImagePath];
    }
    
    if (args.containsKey('type')) {
       scanType = args['type'] as ScanType;
    } else {
       scanType = ScanType.face;
    }
    documentSession = args['documentSession'] == true;
    startNewSession = args['startNewSession'] == true;

    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      hasError.value = false;
      progress.value = 0.1;
      statusMessage.value = 'Loading image...';
      
      await Future<void>.delayed(const Duration(milliseconds: 350));
      progress.value = 0.3;
      statusMessage.value = scanType == ScanType.face
          ? 'Detecting faces and contours...'
          : 'Detecting text...';

      File processedFile;
      File thumbnailFile;
      
      if (scanType == ScanType.face) {
        final originalFile = File(originalImagePath);
        if (!originalFile.existsSync()) {
          throw const StorageException('Image file not found');
        }
        statusMessage.value = 'Processing face...';
        processedFile = await _imageProcessingService.processFaceFlow(
          originalFile,
        );
        thumbnailFile = processedFile;
      } else {
        if (documentSession) {
          if (startNewSession) {
            _documentSession.startNewSession();
          }
          final total = originalImagePaths.length;
          for (var index = 0; index < originalImagePaths.length; index++) {
            final path = originalImagePaths[index];
            final originalFile = File(path);
            if (!originalFile.existsSync()) {
              throw const StorageException('Image file not found');
            }

            statusMessage.value = 'Detecting text...';
            await _imageProcessingService.detectText(
              originalFile,
            );

            final stepBase = total == 1 ? 0.6 : 0.4;
            final stepSpan = total == 1 ? 0.4 : 0.5;
            progress.value =
                stepBase + stepSpan * ((index + 1) / total);
            statusMessage.value =
                'Enhancing page ${index + 1} of $total...';

            final enhancedImage =
                await _imageProcessingService.processDocumentFlow(originalFile);
            thumbnailFile = enhancedImage;

            _documentSession.addPage(
              DocumentPage(
                id: _uuid.v4(),
                originalPath: originalFile.path,
                processedPath: enhancedImage.path,
                thumbnailPath: enhancedImage.path,
              ),
            );
          }

          progress.value = 1.0;
          statusMessage.value = 'Pages ready';
          await Future<void>.delayed(const Duration(milliseconds: 350));
          await Get.offNamedUntil<void>(
            Routes.documentPages,
            (route) => route.settings.name == Routes.home,
          );
          return;
        } else {
          final originalFile = File(originalImagePath);
          if (!originalFile.existsSync()) {
            throw const StorageException('Image file not found');
          }
          statusMessage.value = 'Detecting text...';
          await _imageProcessingService.detectText(
            originalFile,
          );
          
          progress.value = 0.6;
          statusMessage.value = 'Enhancing document...';
          
          final enhancedImage =
              await _imageProcessingService.processDocumentFlow(originalFile);
          thumbnailFile = enhancedImage;

          progress.value = 0.85;
          statusMessage.value = 'Creating PDF...';
          processedFile = await _pdfService.generatePdfFromImage(enhancedImage);
        }
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

    } on StorageException catch (e) {
      hasError.value = true;
      errorMessage = e.message;
      statusMessage.value = 'File not found.';
    } on ProcessingException catch (e) {
      hasError.value = true;
      errorMessage = e.message;
      statusMessage.value = 'Processing failed.';
    } on AppException catch (e) {
      hasError.value = true;
      errorMessage = e.message;
      statusMessage.value = 'Processing failed.';
    } catch (e) {
      hasError.value = true;
      errorMessage = e.toString();
      statusMessage.value = 'An unexpected error occurred.';
    }
  }

  Future<void> retry() async {
    await _startProcessing();
  }

  void goBack() {
    Get.back<void>();
  }
}
