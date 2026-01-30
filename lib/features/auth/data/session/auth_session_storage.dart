import 'package:inventory_app_pos/features/auth/data/model/user_token_model.dart';

/// Minimal abstraction for session storage used by the API layer.
abstract class AuthSessionStorage {
  Future<UserToken?> read();
  Future<void> write(UserToken token);
  Future<void> clear();
}

/// Simple in-memory implementation used by tests or as a placeholder.
class AuthSessionStorageImpl implements AuthSessionStorage {
  AuthSessionStorageImpl._();
  static final instance = AuthSessionStorageImpl._();

  UserToken? _token;

  @override
  Future<UserToken?> read() async => _token;

  @override
  Future<void> write(UserToken token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
