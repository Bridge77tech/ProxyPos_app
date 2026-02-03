import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../../data/local_storage_service_impl.dart';
import '../../../../data/storage_box.dart';
import '../../data/model/user_token_model.dart';
import 'auth_session_storage.dart';

/// Hive-backed session storage using encrypted box when available.
class AuthSessionStorageHive implements AuthSessionStorage {
  AuthSessionStorageHive._();
  static final instance = AuthSessionStorageHive._();

  static const _kKey = 'user_token';

  Future<Box<String>> _box() async {
    return await LocalStorageServiceImpl.instance.openBox<String>(
      StorageBox.auth,
    );
  }

  @override
  Future<UserToken?> read() async {
    final box = await _box();
    final raw = box.get(_kKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserToken.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(UserToken token) async {
    final box = await _box();
    final raw = jsonEncode(token.toJson());
    await box.put(_kKey, raw);
  }

  @override
  Future<void> clear() async {
    final box = await _box();
    await box.delete(_kKey);
  }
}
