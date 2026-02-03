import 'package:hive_ce/hive.dart';

class ApUserEntity extends HiveObject {
  final String? id;
  final String? username;
  final String? email;
  final String? role;
  final DateTime? lastSync;

  ApUserEntity({this.id, this.username, this.email, this.role, this.lastSync});
}
