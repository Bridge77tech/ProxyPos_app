import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';
import 'package:inventory_app_pos/network/models/api_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel extends APIResponse<UserModel> {
  UserModel({
    this.user,
  });

  @JsonKey(name: 'user')
  APUserModel? user;

  APUserModel get getUser => user ?? APUserModel();

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  @override
  UserModel fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}