import 'package:hive/hive.dart';
import 'package:image_flow/data/models/scan_model.dart' as data_models;
import 'package:image_flow/domain/entities/scan_entity.dart';
import 'package:image_flow/domain/repositories/scan_repository.dart';

class ScanRepositoryImpl implements ScanRepository {
  ScanRepositoryImpl(this._box);

  final Box<data_models.ScanModel> _box;

  @override
  Future<List<ScanEntity>> getAllScans() async {
    return _box.values.map(_toEntity).toList();
  }

  @override
  Future<ScanEntity?> getScanById(String id) async {
    final model = _box.values.cast<data_models.ScanModel?>().firstWhere(
          (scan) => scan?.id == id,
          orElse: () => null,
        );
    return model != null ? _toEntity(model) : null;
  }

  @override
  Future<void> saveScan(ScanEntity scan) async {
    final model = _toModel(scan);
    await _box.add(model);
  }

  @override
  Future<void> deleteScan(String id) async {
    final index = _box.values.toList().indexWhere((scan) => scan.id == id);
    if (index != -1) {
      await _box.deleteAt(index);
    }
  }

  @override
  Future<void> deleteAllScans() async {
    await _box.clear();
  }

  ScanEntity _toEntity(data_models.ScanModel model) {
    return ScanEntity(
      id: model.id,
      date: model.date,
      type: _convertType(model.type),
      resultFilePath: model.resultFilePath,
      originalFilePath: model.originalFilePath,
      thumbnailPath: model.thumbnailPath,
    );
  }

  data_models.ScanModel _toModel(ScanEntity entity) {
    return data_models.ScanModel(
      id: entity.id,
      date: entity.date,
      type: _convertToModelType(entity.type),
      resultFilePath: entity.resultFilePath,
      originalFilePath: entity.originalFilePath,
      thumbnailPath: entity.thumbnailPath,
    );
  }

  ScanType _convertType(data_models.ScanType type) {
    switch (type) {
      case data_models.ScanType.face:
        return ScanType.face;
      case data_models.ScanType.document:
        return ScanType.document;
    }
  }

  data_models.ScanType _convertToModelType(ScanType type) {
    switch (type) {
      case ScanType.face:
        return data_models.ScanType.face;
      case ScanType.document:
        return data_models.ScanType.document;
    }
  }
}
