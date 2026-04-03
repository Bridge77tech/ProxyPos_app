// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) =>
    UserModel(
        user: json['user'] == null
            ? null
            : APUserModel.fromJson(json['user'] as Map<String, dynamic>),
      )
      ..message = json['message'] as String?
      ..statusCode = (json['statusCode'] as num?)?.toInt()
      ..token = json['token'] as String?;

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'message': instance.message,
  'statusCode': instance.statusCode,
  'token': instance.token,
  'user': instance.user?.toJson(),
};
