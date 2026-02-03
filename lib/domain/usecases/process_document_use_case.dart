import 'dart:io';
import 'package:image_flow/domain/entities/processing_result.dart';
import 'package:image_flow/domain/repositories/image_processing_repository.dart';

class ProcessDocumentUseCase {
  const ProcessDocumentUseCase(this._repository);

  final ImageProcessingRepository _repository;

  Future<ProcessingResult> call(File originalImage) async {
    return _repository.processDocument(originalImage);
  }
}
