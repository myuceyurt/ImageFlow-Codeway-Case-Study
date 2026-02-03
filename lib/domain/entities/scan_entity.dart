enum ScanType {
  face,
  document,
}

class ScanEntity {
  const ScanEntity({
    required this.id,
    required this.date,
    required this.type,
    required this.resultFilePath,
    required this.originalFilePath,
    this.thumbnailPath,
  });

  final String id;
  final DateTime date;
  final ScanType type;
  final String resultFilePath;
  final String originalFilePath;
  final String? thumbnailPath;

  ScanEntity copyWith({
    String? id,
    DateTime? date,
    ScanType? type,
    String? resultFilePath,
    String? originalFilePath,
    String? thumbnailPath,
  }) {
    return ScanEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      resultFilePath: resultFilePath ?? this.resultFilePath,
      originalFilePath: originalFilePath ?? this.originalFilePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
