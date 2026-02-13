import 'dart:async';
import 'dart:convert';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:inventory_app_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';

import '../../presentation/bloc/auth_state.dart';

/// Periodically checks the auth token and logs out if expired.
class TokenSessionGuard {
  TokenSessionGuard({Duration interval = const Duration(minutes: 5)})
      : _interval = interval,
        _log = getLogger('TokenSessionGuard');

  final Duration _interval;
  final _log;
  Timer? _timer;

  bool get isRunning => _timer != null;

  void start(BlocBase<AuthState> authBloc) {
    if (_timer != null) return;
    _log.i('Starting token session guard with interval: ${_interval.inMinutes} minutes');
    // run immediately, then periodically
    _checkToken(authBloc);
    _timer = Timer.periodic(_interval, (_) => _checkToken(authBloc));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _log.i('Stopped token session guard');
  }

  Future<void> _checkToken(BlocBase<AuthState> authBloc) async {
    try {
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) {
        _log.w('No auth token found; requesting logout');
        if (authBloc is AuthBloc) authBloc.add(const LogoutRequested());
        return;
      }

      // Try decode as JWT and check exp claim
      final parts = token.split('.');
      if (parts.length != 3) {
        _log.w('Token is not a JWT; skipping expiry check');
        return;
      }
      final payload = _decodeBase64Url(parts[1]);
      final exp = payload['exp'];
      if (exp is int) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();
        if (now.isAfter(expiry)) {
          _log.w('Token expired at $expiry; logging out');
          if (authBloc is AuthBloc) authBloc.add(const LogoutRequested());
          return;
        }
        final remaining = expiry.difference(now);
        _log.i('Token valid. Time remaining: ${remaining.inMinutes} min');
      } else {
        _log.w('No exp claim in token; skipping expiry check');
      }
    } catch (e, st) {
      _log.e('Token check failed', error: e, stackTrace: st);
    }
  }

  Map<String, dynamic> _decodeBase64Url(String str) {
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
        throw FormatException('Illegal base64url string!');
    }
    final bytes = base64.decode(output);
    final jsonStr = utf8.decode(bytes);
    return json.decode(jsonStr) as Map<String, dynamic>;
  }
}
