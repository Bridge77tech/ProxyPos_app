
import 'package:inventory_app_pos/features/auth/data/model/token_model.dart';
import 'package:inventory_app_pos/features/auth/domain/entity/user_token.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_token_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserToken extends UserTokenEntity {
  UserToken({super.access, super.refresh});

  factory UserToken.fromJson(Map<String, dynamic> json) => _$UserTokenFromJson(json);

  Map<String, dynamic> toJson() => _$UserTokenToJson(this);
}