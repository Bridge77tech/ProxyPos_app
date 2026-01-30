import 'package:dio/dio.dart';
import '../model/user_token_model.dart';

class AuthAPIService {
  AuthAPIService(this._dio);
  final Dio _dio;

  /// Sample refresh endpoint call. Replace path/body with your API contract.
  Future<UserToken> refresh(String refreshToken) async {
    final res = await _dio.post('/auth/refresh', data: {'refresh': refreshToken});
    return UserToken.fromJson(res.data as Map<String, dynamic>);
  }
}
