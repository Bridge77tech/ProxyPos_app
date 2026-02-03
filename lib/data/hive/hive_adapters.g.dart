// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class TokenAdapter extends TypeAdapter<Token> {
  @override
  final typeId = 0;

  @override
  Token read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Token(
      expiresAt: fields[1] as DateTime?,
      token: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Token obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.token)
      ..writeByte(1)
      ..write(obj.expiresAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserTokenAdapter extends TypeAdapter<UserToken> {
  @override
  final typeId = 1;

  @override
  UserToken read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserToken(access: fields[0] as Token?, refresh: fields[1] as Token?);
  }

  @override
  void write(BinaryWriter writer, UserToken obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.access)
      ..writeByte(1)
      ..write(obj.refresh);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserTokenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
