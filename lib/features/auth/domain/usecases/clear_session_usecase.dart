import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';

class ClearSessionUseCase {
  final AuthSessionStorageImpl _authSession;

  ClearSessionUseCase(this._authSession);

  Future<void> call() async {
    await _authSession.clearStorage();
  }
}