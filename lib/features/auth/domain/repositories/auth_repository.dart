import 'package:inventory_app_pos/features/auth/data/model/user_token_model.dart';

/// Minimal repository interface used by auth use-cases.
abstract class AuthRepository {
  /// Attempt to refresh tokens using a refresh token.
  /// Should return a [UserToken] on success or throw on failure.
  Future<UserToken> refreshToken(String refreshToken);

  /// Optional: expose login/register methods if needed by your app.
}
