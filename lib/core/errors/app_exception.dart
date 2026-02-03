class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() {
    return 'AppException: $message ${code != null ? "($code)" : ""}';
  }
}

class CameraPermissionException extends AppException {
  const CameraPermissionException(super.message, {super.code});
}

class DetectionException extends AppException {
  const DetectionException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class ProcessingException extends AppException {
  const ProcessingException(super.message, {super.code});
}
