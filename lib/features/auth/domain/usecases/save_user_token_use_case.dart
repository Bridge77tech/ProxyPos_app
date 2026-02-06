import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';

class SaveUserTokenUseCase {
  final AuthSessionStorageImpl _authSessionStorage;
  final _log = getLogger('SaveUserTokenUseCase');

  SaveUserTokenUseCase(this._authSessionStorage);

/// saves [token] to session storage after validating it.
///
/// Behaviour:
/// - If the refresh token is expired -> clear session and throw [SessionExpiredException].
/// - if the access token is already expired or expiring soon and [forceSaveIfAccessExpired].
/// - is false -> throw [AccessTokenExpiredException].
/// - otherwise, save the token to storage.
  Future<void> call(String token) async {
    try {
      await _authSessionStorage.saveData(token);
    } catch (e) {
      _log.e(e.toString());
    }
  }
}