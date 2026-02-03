import 'package:image_flow/domain/entities/scan_entity.dart';
import 'package:image_flow/domain/repositories/scan_repository.dart';

class GetScansUseCase {
  const GetScansUseCase(this._repository);

  final ScanRepository _repository;

  Future<List<ScanEntity>> call() async {
    return _repository.getAllScans();
  }
}
