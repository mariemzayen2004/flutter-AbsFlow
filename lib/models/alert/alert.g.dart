// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlertModelAdapter extends TypeAdapter<AlertModel> {
  @override
  final int typeId = 7;

  @override
  AlertModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertModel(
      id: fields[0] as int,
      studentId: fields[1] as int,
      totalHeuresAbsence: fields[2] as int,
      niveau: fields[3] as AlertLevel,
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AlertModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.totalHeuresAbsence)
      ..writeByte(3)
      ..write(obj.niveau)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlertLevelAdapter extends TypeAdapter<AlertLevel> {
  @override
  final int typeId = 9;

  @override
  AlertLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlertLevel.avertissement;
      case 1:
        return AlertLevel.elimination;
      default:
        return AlertLevel.avertissement;
    }
  }

  @override
  void write(BinaryWriter writer, AlertLevel obj) {
    switch (obj) {
      case AlertLevel.avertissement:
        writer.writeByte(0);
        break;
      case AlertLevel.elimination:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
