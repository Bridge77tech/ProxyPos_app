import '../../data/session/auth_session_storage.dart';
import 'attempt_token_refresh_usecase.dart';
import 'clear_session_usecase.dart';

/// Returns the access token if available and not expiring soon.
/// If the token is expiring soon/expired, attempts a refresh via
/// [AttemptTokenRefreshUseCase]; on refresh failure it calls
/// [ClearSessionUseCase].
class GetAccessTokenUseCase {
  GetAccessTokenUseCase(this._session, this._attemptRefresh, this._clear);

  final AuthSessionStorage _session;
  final AttemptTokenRefreshUseCase _attemptRefresh;
  final ClearSessionUseCase _clear;

  Future<String?> call() async {
    final stored = await _session.read();
    if (stored == null) return null;

    // If access token is valid, return it
    if (!stored.isAccessTokenExpOrExpiringSoon) return stored.access?.token;

    // Try refresh if we have a refresh token
    final hasRefresh = stored.refresh?.token?.isNotEmpty ?? false;
    if (hasRefresh) {
      final refreshed = await _attemptRefresh.call();
      if (refreshed) {
        final updated = await _session.read();
        return updated?.access?.token;
      }
    }

    // No refresh token or refresh failed: fall back to current access token if present
    if (stored.access?.token?.isNotEmpty ?? false) {
      return stored.access!.token;
    }

    // Otherwise clear session and return null
    await _clear.call();
    return null;
  }
}
