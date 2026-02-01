import 'package:hive_ce/hive.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_token_model.dart';

class ApUserEntity extends HiveObject {
  UserToken? token;

  ApUserEntity({this.token});
}