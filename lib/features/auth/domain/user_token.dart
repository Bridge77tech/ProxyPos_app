import 'package:hive/hive.dart';

import '../data/model/token_model.dart';

class UserTokenEntity extends HiveObject {
  Token? access;
  Token? refresh;

  UserTokenEntity({this.access, this.refresh});

  bool get isRefreshExpired {
    return refresh?.token == null ||
        refresh?.expiresAt == null ||
        DateTime.now().isAfter(refresh!.expiresAt!);
  }

  bool get isAccessTokenExpOrExpiringSoon {
    final bufferWindow = DateTime.now().add(const Duration(seconds: 10));
    if (access == null || access!.expiresAt == null) {
      return true;
    }
    return bufferWindow.isAfter(access!.expiresAt!);
  }

  UserTokenEntity copyWith({Token? access, Token? refresh}) {
    return UserTokenEntity(
      access: access ?? this.access,
      refresh: refresh ?? this.refresh,
    );
  }
}