import 'package:hive_ce_flutter/hive_flutter.dart';
import 'ap_user_model.dart';

class APUserModelAdapter extends TypeAdapter<APUserModel> {
  @override
  final int typeId = 11; // unique type id; ensure it doesn't clash

  @override
  APUserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
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
}
