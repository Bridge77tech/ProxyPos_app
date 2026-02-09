import 'package:inventory_app_pos/features/auth/data/data_source/local/user_local_storage.dart';

import '../../../../../core/app_constants/inv_app_constants.dart';
import '../../../../../data/storage_box.dart';

class AuthSessionStorageImpl  extends BaseUserLocalStorage {
  AuthSessionStorageImpl._()
    : super(
    boxType: StorageBox.auth,
    storageKey: InvAppConstants.kAuthBoxKey,
    loggerName: 'AuthSessionStorageImpl',
  );

  static final instance = AuthSessionStorageImpl._();
}