import 'package:inventory_app_pos/features/auth/data/model/user_token_model.dart';
import 'package:inventory_app_pos/features/auth/domain/entity/ap_user_entity.dart';

/// Minimal repository interface used by auth use-cases.
abstract class AuthRepository {
  /// Attempt to refresh tokens using a refresh token.
  /// Should return a [UserToken] on success or throw on failure.
  Future<UserToken> refreshToken(String refreshToken);

  Future<UserToken> login({required String username, required String password});

  /// Fetch the currently authenticated user's profile.
  Future<ApUserEntity> getCurrentUser({required String accessToken});
}
