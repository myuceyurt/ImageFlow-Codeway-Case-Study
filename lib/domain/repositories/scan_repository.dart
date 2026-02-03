import 'package:image_flow/domain/entities/scan_entity.dart';

abstract class ScanRepository {
  Future<List<ScanEntity>> getAllScans();
  Future<ScanEntity?> getScanById(String id);
  Future<void> saveScan(ScanEntity scan);
  Future<void> deleteScan(String id);
  Future<void> deleteAllScans();
}
