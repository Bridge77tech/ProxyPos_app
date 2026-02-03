import 'dart:convert';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../../../network/exceptions/api_exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../model/token_model.dart';
import '../model/user_token_model.dart';
import '../remote/auth_api_service.dart';

class AuthRepoImpl implements AuthRepository {
  AuthRepoImpl(this._service);
  final AuthAPIService _service;
  final _log = getLogger('AuthRepoImpl');

  @override
  Future<UserToken> refreshToken(String refreshToken) {
    return _service.refresh({'refresh': refreshToken});
  }

  @override
  Future<UserToken> login({
    required String username,
    required String password,
  }) {
    return _service.login({'username': username, 'password': password}).then((
      httpRes,
    ) {
      final status = httpRes.response.statusCode;
      final parsed = _toJsonMap(httpRes.data);

      if (status == 200 || (parsed?['statusCode'] == 200)) {
        final tokenStr = parsed?['token'] as String?;
        if (tokenStr == null || tokenStr.isEmpty) {
          _log.e('Missing token in response');
          throw ApiExceptions(
            message: 'Missing token in response',
            statusCode: status,
          );
        }
        final expiresAt = _parseJwtExpiry(tokenStr);
        final access = Token(token: tokenStr, expiresAt: expiresAt);
        return UserToken(access: access);
      }

      final msg = parsed?['message']?.toString() ?? 'Login failed';
      _log.e('Login failed: $msg (status: $status)');
      throw ApiExceptions(message: msg, statusCode: status);
    });
  }

  Map<String, dynamic>? _toJsonMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = json.decode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        return null;
      } catch (e) {
        // Likely HTML or non-JSON payload
        final snippet = data.toString();
        _log.e(
          'Unexpected response format (non-JSON): ${snippet.substring(0, snippet.length > 120 ? 120 : snippet.length)}',
        );
        return null;
      }
    }
    try {
      final encoded = json.encode(data);
      final decoded = json.decode(encoded);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  DateTime? _parseJwtExpiry(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final jsonStr = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> map =
          json.decode(jsonStr) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
          isUtc: true,
        ).toLocal();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
