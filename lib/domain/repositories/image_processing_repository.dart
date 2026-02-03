import 'dart:io';
import 'package:image_flow/domain/entities/processing_result.dart';

abstract class ImageProcessingRepository {
  Future<ProcessingResult> processFace(File originalImage);
  Future<ProcessingResult> processDocument(File originalImage);
  Future<bool> hasFaces(File image);
}
