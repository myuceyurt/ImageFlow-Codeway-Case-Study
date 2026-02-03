import 'package:hive/hive.dart';

enum BatchIntent {
  auto,
  document,
  face,
}

enum BatchJobStatus {
  pending,
  running,
  completed,
  canceled,
}

@HiveType(typeId: 2)
class BatchJob extends HiveObject {
  BatchJob({
    required this.batchId,
    required this.intent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.maxConcurrent,
    required this.totalCount,
  });

  @HiveField(0)
  final String batchId;

  @HiveField(1)
  final BatchIntent intent;

  @HiveField(2)
  final BatchJobStatus status;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5)
  final int maxConcurrent;

  @HiveField(6)
  final int totalCount;

  BatchJob copyWith({
    BatchIntent? intent,
    BatchJobStatus? status,
    DateTime? updatedAt,
    int? maxConcurrent,
    int? totalCount,
  }) {
    return BatchJob(
      batchId: batchId,
      intent: intent ?? this.intent,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maxConcurrent: maxConcurrent ?? this.maxConcurrent,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class BatchJobAdapter extends TypeAdapter<BatchJob> {
  @override
  final int typeId = 2;

  @override
  BatchJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BatchJob(
      batchId: fields[0] as String,
      intent: fields[1] as BatchIntent,
      status: fields[2] as BatchJobStatus,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      maxConcurrent: fields[5] as int,
      totalCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BatchJob obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.batchId)
      ..writeByte(1)
      ..write(obj.intent)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.maxConcurrent)
      ..writeByte(6)
      ..write(obj.totalCount);
  }
}

class BatchIntentAdapter extends TypeAdapter<BatchIntent> {
  @override
  final int typeId = 4;

  @override
  BatchIntent read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BatchIntent.auto;
      case 1:
        return BatchIntent.document;
      case 2:
        return BatchIntent.face;
      default:
        return BatchIntent.auto;
    }
  }

  @override
  void write(BinaryWriter writer, BatchIntent obj) {
    switch (obj) {
      case BatchIntent.auto:
        writer.writeByte(0);
      case BatchIntent.document:
        writer.writeByte(1);
      case BatchIntent.face:
        writer.writeByte(2);
    }
  }
}

class BatchJobStatusAdapter extends TypeAdapter<BatchJobStatus> {
  @override
  final int typeId = 6;

  @override
  BatchJobStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BatchJobStatus.pending;
      case 1:
        return BatchJobStatus.running;
      case 2:
        return BatchJobStatus.completed;
      case 3:
        return BatchJobStatus.canceled;
      default:
        return BatchJobStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, BatchJobStatus obj) {
    switch (obj) {
      case BatchJobStatus.pending:
        writer.writeByte(0);
      case BatchJobStatus.running:
        writer.writeByte(1);
      case BatchJobStatus.completed:
        writer.writeByte(2);
      case BatchJobStatus.canceled:
        writer.writeByte(3);
    }
  }
}
