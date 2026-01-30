import 'package:hive_ce/hive.dart';

class TokenEntity extends HiveObject {
  final String? token;
  final DateTime? expiresAt;

  TokenEntity({this.token, this.expiresAt});
}