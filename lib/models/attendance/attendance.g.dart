// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceAdapter extends TypeAdapter<Attendance> {
  @override
  final int typeId = 5;

  @override
  Attendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Attendance(
      sessionId: fields[0] as int,
      studentId: fields[2] as int,
      present: fields[3] as bool,
      heuresManquees: fields[4] as int,
      remarque: fields[5] as String?,
      justifie: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Attendance obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.studentId)
      ..writeByte(3)
      ..write(obj.present)
      ..writeByte(4)
      ..write(obj.heuresManquees)
      ..writeByte(5)
      ..write(obj.remarque)
      ..writeByte(6)
      ..write(obj.justifie);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
