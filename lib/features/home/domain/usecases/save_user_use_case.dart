import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../../../core/exceptions/local_storage_exception.dart';
import '../../../auth/data/model/ap_user_model.dart';
import '../../../auth/data/session/user_profile_storage_hive.dart';

class SaveUserUseCase {
  final _log = getLogger('SaveUserUseCase');
  final UserProfileStorage _storage;

  SaveUserUseCase(this._storage);

  Future<void> call(ApUserModel user) async {
    try {
      if (user.id == null && (user.username == null || user.email == null)) {
        throw LocalStorageException(message: 'Invalid user payload');
      }
      await _storage.write(user);
    } catch (e) {
      _log.e(e.toString());
      if (e is LocalStorageException) rethrow;
      throw LocalStorageException(message: 'Failed to save user info');
    }
  }
}
