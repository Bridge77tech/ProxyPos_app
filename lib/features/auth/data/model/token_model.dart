import '../../domain/entity/token_entity.dart';

class Token extends TokenEntity {
  Token({super.expiresAt, super.token});

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  Map<String, dynamic> toJson() => _$TokenToJson();

  static Token _$TokenFromJson(Map<String, dynamic> json) {
    return Token(
      expiresAt: json["expires_at"] == null
          ? null
          : DateTime.parse(json['expires_at']).toLocal(),
      token: json['token'],
    );
  }

  Map<String, dynamic> _$TokenToJson() => {
    "expires_at": expiresAt?.toIso8601String(),
    "token": token,
  };
}