import 'package:image_flow/domain/entities/scan_entity.dart';
import 'package:image_flow/domain/repositories/scan_repository.dart';

class SaveScanUseCase {
  const SaveScanUseCase(this._repository);

  final ScanRepository _repository;

  Future<void> call(ScanEntity scan) async {
    return _repository.saveScan(scan);
  }
}
