import 'package:hive/hive.dart';
import 'package:image_flow/data/models/batch_job.dart';
import 'package:image_flow/data/models/scan_model.dart';

enum BatchItemStatus {
  pending,
  processing,
  success,
  failed,
  canceled,
}

@HiveType(typeId: 3)
class BatchItem extends HiveObject {
  BatchItem({
    required this.id,
    required this.batchId,
    required this.originalPath,
    required this.status,
    required this.requestedType,
    required this.createdAt,
    this.detectedType,
    this.processedFilePath,
    this.thumbnailPath,
    this.errorMessage,
    this.startedAt,
    this.completedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String batchId;

  @HiveField(2)
  final String originalPath;

  @HiveField(3)
  final BatchItemStatus status;

  @HiveField(4)
  final BatchIntent requestedType;

  @HiveField(5)
  final ScanType? detectedType;

  @HiveField(6)
  final String? processedFilePath;

  @HiveField(7)
  final String? thumbnailPath;

  @HiveField(8)
  final String? errorMessage;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime? startedAt;

  @HiveField(11)
  final DateTime? completedAt;

  BatchItem copyWith({
    String? originalPath,
    BatchItemStatus? status,
    BatchIntent? requestedType,
    Object? detectedType = _unset,
    Object? processedFilePath = _unset,
    Object? thumbnailPath = _unset,
    Object? errorMessage = _unset,
    Object? startedAt = _unset,
    Object? completedAt = _unset,
  }) {
    return BatchItem(
      id: id,
      batchId: batchId,
      originalPath: originalPath ?? this.originalPath,
      status: status ?? this.status,
      requestedType: requestedType ?? this.requestedType,
      detectedType: detectedType == _unset
          ? this.detectedType
          : detectedType as ScanType?,
      processedFilePath: processedFilePath == _unset
          ? this.processedFilePath
          : processedFilePath as String?,
      thumbnailPath: thumbnailPath == _unset
          ? this.thumbnailPath
          : thumbnailPath as String?,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      createdAt: createdAt,
      startedAt:
          startedAt == _unset ? this.startedAt : startedAt as DateTime?,
      completedAt: completedAt == _unset
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }
}

const Object _unset = Object();

class BatchItemAdapter extends TypeAdapter<BatchItem> {
  @override
  final int typeId = 3;

  @override
  BatchItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BatchItem(
      id: fields[0] as String,
      batchId: fields[1] as String,
      originalPath: fields[2] as String,
      status: fields[3] as BatchItemStatus,
      requestedType: fields[4] as BatchIntent,
      detectedType: fields[5] as ScanType?,
      processedFilePath: fields[6] as String?,
      thumbnailPath: fields[7] as String?,
      errorMessage: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      startedAt: fields[10] as DateTime?,
      completedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BatchItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.batchId)
      ..writeByte(2)
      ..write(obj.originalPath)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.requestedType)
      ..writeByte(5)
      ..write(obj.detectedType)
      ..writeByte(6)
      ..write(obj.processedFilePath)
      ..writeByte(7)
      ..write(obj.thumbnailPath)
      ..writeByte(8)
      ..write(obj.errorMessage)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.startedAt)
      ..writeByte(11)
      ..write(obj.completedAt);
  }
}

class BatchItemStatusAdapter extends TypeAdapter<BatchItemStatus> {
  @override
  final int typeId = 5;

  @override
  BatchItemStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BatchItemStatus.pending;
      case 1:
        return BatchItemStatus.processing;
      case 2:
        return BatchItemStatus.success;
      case 3:
        return BatchItemStatus.failed;
      case 4:
        return BatchItemStatus.canceled;
      default:
        return BatchItemStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, BatchItemStatus obj) {
    switch (obj) {
      case BatchItemStatus.pending:
        writer.writeByte(0);
      case BatchItemStatus.processing:
        writer.writeByte(1);
      case BatchItemStatus.success:
        writer.writeByte(2);
      case BatchItemStatus.failed:
        writer.writeByte(3);
      case BatchItemStatus.canceled:
        writer.writeByte(4);
    }
  }
}
