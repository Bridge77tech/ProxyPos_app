// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_token_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserToken _$UserTokenFromJson(Map<String, dynamic> json) => UserToken(
  access: json['access'] == null
      ? null
      : Token.fromJson(json['access'] as Map<String, dynamic>),
  refresh: json['refresh'] == null
      ? null
      : Token.fromJson(json['refresh'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserTokenToJson(UserToken instance) => <String, dynamic>{
  'access': instance.access?.toJson(),
  'refresh': instance.refresh?.toJson(),
};
