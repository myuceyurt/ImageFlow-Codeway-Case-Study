import 'package:hive/hive.dart';

enum ScanType {
  face,
  document,
}

@HiveType(typeId: 0)
class ScanModel extends HiveObject {
  ScanModel({
    required this.id,
    required this.date,
    required this.type,
    required this.resultFilePath,
    required this.originalFilePath,
    this.thumbnailPath,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final ScanType type;

  @HiveField(3)
  final String resultFilePath;

  @HiveField(4)
  final String originalFilePath;

  @HiveField(5)
  final String? thumbnailPath;
}

class ScanModelAdapter extends TypeAdapter<ScanModel> {
  @override
  final int typeId = 0;

  @override
  ScanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as ScanType,
      resultFilePath: fields[3] as String,
      originalFilePath: fields[4] as String,
      thumbnailPath: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.resultFilePath)
      ..writeByte(4)
      ..write(obj.originalFilePath)
      ..writeByte(5)
      ..write(obj.thumbnailPath);
  }
}

class ScanTypeAdapter extends TypeAdapter<ScanType> {
  @override
  final int typeId = 1;

  @override
  ScanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScanType.face;
      case 1:
        return ScanType.document;
      default:
        return ScanType.face;
    }
  }

  @override
  void write(BinaryWriter writer, ScanType obj) {
    switch (obj) {
      case ScanType.face:
        writer.writeByte(0);
      case ScanType.document:
        writer.writeByte(1);
    }
  }
}
