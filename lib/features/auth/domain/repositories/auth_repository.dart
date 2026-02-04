import 'package:inventory_app_pos/features/auth/data/model/user_token_model.dart';

/// Minimal repository interface used by auth use-cases.
abstract class AuthRepository<T> {
  /// Attempt to refresh tokens using a refresh token.
  /// Should return a [UserToken] on success or throw on failure.
  Future<T> refreshToken(String refreshToken);

  Future<T> login(Map<String, dynamic> payload);

  /// Fetch the currently authenticated user's profile.
  Future<T> getCurrentUser({required String accessToken});
}
