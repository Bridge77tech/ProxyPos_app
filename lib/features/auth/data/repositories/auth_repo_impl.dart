import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../../../network/exceptions/api_exceptions.dart';
import '../../domain/repositories/auth_repository.dart';
import '../remote/auth_api_service.dart';

class AuthRepoImpl implements AuthRepository<Map<String, dynamic>> {
  AuthRepoImpl(this._service);
  final AuthAPIService _service;
  final _log = getLogger('AuthRepoImpl');

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) {
    return _service
        .refresh({'refresh': refreshToken})
        .then((token) {
          return token.toJson();
        })
        .catchError((error) {
          if (error is DioException) {
            final mapped = ApiExceptions.fromDio(error);
            if (mapped != null) throw mapped;
          }
          throw error;
        });
  }

  @override
  Future<Map<String, dynamic>> login(Map<String, dynamic> payload) {
    return _service
        .login(payload)
        .then((httpRes) {
          final parsed = _toJsonMap(httpRes.data);
          if (parsed != null) return parsed;
          _log.e('Unexpected login response format');
          throw ApiExceptions(
            message: 'Unexpected login response',
            statusCode: httpRes.response.statusCode,
          );
        })
        .catchError((error) {
          if (error is DioException) {
            final mapped = ApiExceptions.fromDio(error);
            if (mapped != null) throw mapped;
          }
          throw error;
        });
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser({
    required String accessToken,
  }) async {
    try {
      final res = await _service.profile('Bearer $accessToken');
      final parsed = _toJsonMap(res.data);
      if (parsed != null) return parsed;
      _log.e('Unexpected user profile response format');
      throw ApiExceptions(
        message: 'Unexpected user profile response',
        statusCode: res.response.statusCode,
      );
    } catch (error) {
      if (error is DioException) {
        final mapped = ApiExceptions.fromDio(error);
        if (mapped != null) throw mapped;
      }
      rethrow;
    }
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

  // DateTime? _parseJwtExpiry(String jwt) {
  //   try {
  //     final parts = jwt.split('.');
  //     if (parts.length != 3) return null;
  //     final payload = base64Url.normalize(parts[1]);
  //     final jsonStr = utf8.decode(base64Url.decode(payload));
  //     final Map<String, dynamic> map =
  //         json.decode(jsonStr) as Map<String, dynamic>;
  //     final exp = map['exp'];
  //     if (exp is int) {
  //       return DateTime.fromMillisecondsSinceEpoch(
  //         exp * 1000,
  //         isUtc: true,
  //       ).toLocal();
  //     }
  //     return null;
  //   } catch (_) {
  //     return null;
  //   }
  // }
}
