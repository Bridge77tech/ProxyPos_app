import 'dart:convert';

import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';

/// Stateless helper — reads the stored token and reports whether it is
/// present and not yet expired.  Shared by [TokenSessionGuard] (periodic
/// check) and the GoRouter redirect (startup / page-refresh check).
class TokenValidator {
  const TokenValidator._();

  /// Returns `true` when a non-expired JWT is found in local storage.
  static Future<bool> hasValidToken() async {
    try {
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) return false;

      final parts = token.split('.');
      if (parts.length != 3) return true; // not a JWT — assume valid

      final payload = _decodePayload(parts[1]);
      final exp = payload['exp'];
      if (exp is! int) return true; // no exp claim — assume valid

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> _decodePayload(String str) {
    var padded = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (padded.length % 4) {
      case 2:
        padded += '==';
        break;
      case 3:
        padded += '=';
        break;
    }
    final bytes = base64.decode(padded);
    return json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
  }
}
