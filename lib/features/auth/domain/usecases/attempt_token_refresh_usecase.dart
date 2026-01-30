import '../../data/session/auth_session_storage.dart';
import '../../domain/repositories/auth_repository.dart';

/// Attempts to refresh tokens using the [AuthRepository]. On success writes
/// the new tokens to session storage. On failure, calls clearSession.
class AttemptTokenRefreshUseCase {
  AttemptTokenRefreshUseCase(this._session, this._repo, this._clearSession);

  final AuthSessionStorage _session;
  final AuthRepository _repo;
  final Future<void> Function() _clearSession;

  Future<bool> call() async {
    final current = await _session.read();
    final refresh = current?.refresh?.token;
    if (refresh == null) return false;

    try {
      final newTokens = await _repo.refreshToken(refresh);
      await _session.write(newTokens);
      return true;
    } catch (e) {
      await _clearSession();
      return false;
    }
  }
}
