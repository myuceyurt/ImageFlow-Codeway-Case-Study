class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() {
    return 'AppException: $message ${code != null ? "($code)" : ""}';
  }
}
