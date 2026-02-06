import 'package:json_annotation/json_annotation.dart';

part 'ap_user_model.g.dart';

@JsonSerializable()
class APUserModel {
  final String? id;

  final String? username;

  final String? email;

  final String? role;

  final String? lastSync;

  APUserModel({
    this.id,
    this.username,
    this.email,
    this.role,
    this.lastSync,
  });

  factory APUserModel.fromJson(Map<String, dynamic> json) => _$APUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$APUserModelToJson(this);
}

