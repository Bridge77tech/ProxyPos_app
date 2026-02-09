// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ap_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APUserModel _$APUserModelFromJson(Map<String, dynamic> json) => APUserModel(
  id: json['id'] as String?,
  username: json['username'] as String?,
  email: json['email'] as String?,
  role: json['role'] as String?,
  lastSync: json['lastSync'] as String?,
);

Map<String, dynamic> _$APUserModelToJson(APUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'role': instance.role,
      'lastSync': instance.lastSync,
    };
