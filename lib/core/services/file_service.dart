import 'dart:io';

import 'package:image_flow/core/errors/app_exception.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileService {
  final Uuid _uuid = const Uuid();

  Future<File> saveImageFile(List<int> bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${_uuid.v4()}.jpg';
      final file = File('${directory.path}/$fileName');
      
      return await file.writeAsBytes(bytes);
    } catch (e) {
      throw AppException('Failed to save image file: $e');
    }
  }
}
