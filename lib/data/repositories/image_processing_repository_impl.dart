import 'dart:io';
import 'package:image_flow/core/services/file_service.dart';
import 'package:image_flow/core/services/image_processing_service.dart';
import 'package:image_flow/domain/entities/processing_result.dart';
import 'package:image_flow/domain/repositories/image_processing_repository.dart';

class ImageProcessingRepositoryImpl implements ImageProcessingRepository {
  ImageProcessingRepositoryImpl({
    required ImageProcessingService imageProcessingService,
    required FileService fileService,
  })  : _imageProcessingService = imageProcessingService,
        _fileService = fileService;

  final ImageProcessingService _imageProcessingService;
  final FileService _fileService;

  @override
  Future<ProcessingResult> processFace(File originalImage) async {
    final processedFile = await _imageProcessingService.processFaceFlow(
      originalImage,
    );
    final movedOriginal = await _fileService.moveToDocuments(originalImage);
    return ProcessingResult(
      processedFile: processedFile,
      thumbnailFile: processedFile,
      originalPath: movedOriginal.path,
    );
  }

  @override
  Future<ProcessingResult> processDocument(File originalImage) async {
    final enhancedFile = await _imageProcessingService.processDocumentFlow(
      originalImage,
    );
    final movedOriginal = await _fileService.moveToDocuments(originalImage);
    return ProcessingResult(
      processedFile: enhancedFile,
      thumbnailFile: enhancedFile,
      originalPath: movedOriginal.path,
    );
  }

  @override
  Future<bool> hasFaces(File image) async {
    return _imageProcessingService.hasFaces(image);
  }
}
