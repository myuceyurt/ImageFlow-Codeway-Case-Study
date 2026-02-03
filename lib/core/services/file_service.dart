import 'dart:io';
import 'dart:typed_data';

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

  Future<Directory> getDocumentsDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> getTempDirectory() async {
    return getTemporaryDirectory();
  }

  Future<Directory> ensureBatchDirectory(String batchId) async {
    final temp = await getTempDirectory();
    final dir = Directory('${temp.path}/batch/$batchId');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> copyToBatchCache({
    required File source,
    required String batchId,
    required String itemId,
  }) async {
    try {
      final dir = await ensureBatchDirectory(batchId);
      final extension = _extensionForPath(source.path);
      final target = File('${dir.path}/${itemId}_original$extension');
      return await source.copy(target.path);
    } catch (e) {
      throw AppException('Failed to copy original file: $e');
    }
  }

  Future<File> writeBytesToFile(Uint8List bytes, String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<File> moveToDocuments(File source) async {
    try {
      final directory = await getDocumentsDirectory();
      final originalName = source.uri.pathSegments.last;
      var targetPath = '${directory.path}/$originalName';
      if (File(targetPath).existsSync()) {
        final extension = _extensionForPath(originalName);
        targetPath = '${directory.path}/${_uuid.v4()}$extension';
      }
      final copied = await source.copy(targetPath);
      await source.delete();
      return copied;
    } catch (e) {
      throw AppException('Failed to move file to documents: $e');
    }
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> deleteDirectoryIfExists(String path) async {
    final dir = Directory(path);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  String _extensionForPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    return path.substring(dot);
  }
}
