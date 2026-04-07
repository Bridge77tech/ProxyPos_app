import 'dart:async';
import 'dart:convert';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:logger/logger.dart';

/// Periodically validates the stored auth token.
///
/// When the token is missing or expired, [onExpired] is called — the caller
/// is responsible for clearing session state and navigating to login.
/// Pending offline sales are intentionally NOT cleared here.
class TokenSessionGuard {
  TokenSessionGuard({Duration interval = const Duration(minutes: 5)})
      : _interval = interval,
        _log = getLogger('TokenSessionGuard');

  final Duration _interval;
  final Logger _log;
  Timer? _timer;
  Future<void> Function()? _onExpired;

  bool get isRunning => _timer != null;

  void start(Future<void> Function() onExpired) {
    if (_timer != null) return;
    _onExpired = onExpired;
    _log.i('Starting token session guard (interval: ${_interval.inMinutes} min)');
    _checkToken();
    _timer = Timer.periodic(_interval, (_) => _checkToken());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _onExpired = null;
    _log.i('Stopped token session guard');
  }

  Future<void> _checkToken() async {
    try {
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) {
        _log.w('No auth token found — session expired');
        await _onExpired?.call();
        return;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        _log.w('Token is not a JWT — skipping expiry check');
        return;
      }

      final payload = _decodePayload(parts[1]);
      final exp = payload['exp'];
      if (exp is! int) {
        _log.w('No exp claim in token — skipping expiry check');
        return;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      if (DateTime.now().isAfter(expiry)) {
        _log.w('Token expired at $expiry — logging out');
        await _onExpired?.call();
        return;
      }

      _log.i('Token valid — ${expiry.difference(DateTime.now()).inMinutes} min remaining');
    } catch (e, st) {
      _log.e('Token check failed', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic> _decodePayload(String str) {
    var padded = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (padded.length % 4) {
      case 2:
        padded += '==';
        break;
      case 3:
        padded += '=';
        break;
    }
    return json.decode(utf8.decode(base64.decode(padded))) as Map<String, dynamic>;
  }
}
