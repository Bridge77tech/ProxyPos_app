import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../../data/local_storage_service_impl.dart';
import '../../../../data/storage_box.dart';
import '../../domain/entity/ap_user_entity.dart';
import '../model/ap_user_model.dart';

abstract class UserProfileStorage {
  Future<ApUserEntity?> read();
  Future<void> write(ApUserEntity user);
  Future<void> clear();
}

class UserProfileStorageHive implements UserProfileStorage {
  UserProfileStorageHive._();
  static final instance = UserProfileStorageHive._();

  static const _kKey = 'user_profile';

  Future<Box<String>> _box() async {
    return await LocalStorageServiceImpl.instance.openBox<String>(
      StorageBox.auth,
    );
  }

  @override
  Future<ApUserEntity?> read() async {
    final box = await _box();
    final raw = box.get(_kKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ApUserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(ApUserEntity user) async {
    final box = await _box();
    final raw = jsonEncode(
      (user is ApUserModel)
          ? user.toJson()
          : ApUserModel(
              id: user.id,
              username: user.username,
              email: user.email,
              role: user.role,
              lastSync: user.lastSync,
            ).toJson(),
    );
    await box.put(_kKey, raw);
  }

  @override
  Future<void> clear() async {
    final box = await _box();
    await box.delete(_kKey);
  }
}
