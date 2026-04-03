import 'dart:convert';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';

import '../../../../core/exceptions/session_expired_exception.dart';
import 'clear_session_usecase.dart';

class GetAccessTokenUseCase {
  final AuthSessionStorageImpl _authSessionStorage;
  final ClearSessionUseCase _clearSession;
  final _log = getLogger('GetAccessTokenUseCase');

  GetAccessTokenUseCase(this._authSessionStorage, this._clearSession);

  Future<String> call() async {
    // Retrieve stored token
    final String? token = await _authSessionStorage.getStorageData();
    if (token == null || token.isEmpty) {
      _log.w('No access token in storage');
      throw SessionExpiredException();
    }

    // Try to parse JWT and validate exp
    try {
      final isExpired = _isJwtExpired(token);
      if (isExpired) {
        _log.w('Access token expired; clearing session');
        await _clearSession();
        throw SessionExpiredException('Access token expired');
      }
    } catch (e) {
      // If token isn't a JWT or parsing fails, log and proceed with token as-is
      _log.w('Failed to parse token for expiry check; proceeding. Error: $e');
    }

    _log.i('Access token retrieved and valid');
    return token;
  }

  // Decodes a JWT and checks its `exp` claim against current time
  bool _isJwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false; // Not a JWT

    final payload = _decodeBase64Url(parts[1]);
    final Map<String, dynamic> data = json.decode(payload) as Map<String, dynamic>;
    final exp = data['exp'];

    if (exp is int) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      final now = DateTime.now().toUtc();
      return now.isAfter(expiry);
    }
    if (exp is String) {
      final parsed = int.tryParse(exp);
      if (parsed != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(parsed * 1000, isUtc: true);
        final now = DateTime.now().toUtc();
        return now.isAfter(expiry);
      }
    }
    return false;
  }

  String _decodeBase64Url(String str) {
    var output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw const FormatException('Invalid Base64Url length');
    }
    return utf8.decode(base64.decode(output));
  }
}