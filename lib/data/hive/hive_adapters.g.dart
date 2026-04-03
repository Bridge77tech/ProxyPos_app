// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class APUserModelAdapter extends TypeAdapter<APUserModel> {
  @override
  final typeId = 0;

  @override
  APUserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return APUserModel(
      id: fields[0] as String?,
      username: fields[1] as String?,
      email: fields[2] as String?,
      role: fields[3] as String?,
      lastSync: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, APUserModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.lastSync);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is APUserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
