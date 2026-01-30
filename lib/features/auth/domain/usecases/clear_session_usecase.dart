import '../../data/session/auth_session_storage.dart';

class ClearSessionUseCase {
  ClearSessionUseCase(this._session);
  final AuthSessionStorage _session;

  Future<void> call() async {
    await _session.clear();
  }
}
