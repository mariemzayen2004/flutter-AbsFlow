// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 8;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      seuilAvertissement: fields[0] as int,
      seuilElimination: fields[1] as int,
      isDarkMode: fields[2] as bool,
      modeAffichage: fields[3] as ModeAffichage,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.seuilAvertissement)
      ..writeByte(1)
      ..write(obj.seuilElimination)
      ..writeByte(2)
      ..write(obj.isDarkMode)
      ..writeByte(3)
      ..write(obj.modeAffichage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ModeAffichageAdapter extends TypeAdapter<ModeAffichage> {
  @override
  final int typeId = 6;

  @override
  ModeAffichage read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ModeAffichage.liste;
      case 1:
        return ModeAffichage.grille;
      default:
        return ModeAffichage.liste;
    }
  }

  @override
  void write(BinaryWriter writer, ModeAffichage obj) {
    switch (obj) {
      case ModeAffichage.liste:
        writer.writeByte(0);
        break;
      case ModeAffichage.grille:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModeAffichageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
