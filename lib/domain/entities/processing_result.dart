import 'dart:io';

class ProcessingResult {
  const ProcessingResult({
    required this.processedFile,
    required this.thumbnailFile,
    required this.originalPath,
  });

  final File processedFile;
  final File thumbnailFile;
  final String originalPath;
}
