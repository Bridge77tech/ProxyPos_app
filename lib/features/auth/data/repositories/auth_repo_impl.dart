import '../remote/auth_api_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../model/user_token_model.dart';

class AuthRepoImpl implements AuthRepository {
  AuthRepoImpl(this._service);
  final AuthAPIService _service;

  @override
  Future<UserToken> refreshToken(String refreshToken) {
    return _service.refresh(refreshToken);
  }
}
