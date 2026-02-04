import '../../domain/entity/ap_user_entity.dart';

class ApUserModel extends ApUserEntity {
  ApUserModel({super.id, super.username, super.email, super.role, super.lastSync});

  factory ApUserModel.fromJson(Map<String, dynamic> json) {
    return ApUserModel(
      id: json['id'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      lastSync: json['lastSync'] == null ? null : DateTime.tryParse(json['lastSync'] as String)?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'lastSync': lastSync?.toIso8601String(),
      };
}
