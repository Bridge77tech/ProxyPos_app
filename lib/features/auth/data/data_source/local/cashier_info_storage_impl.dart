import 'package:inventory_app_pos/features/auth/data/data_source/local/user_local_storage.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/data/storage_box.dart';

/// Storage for saving cashier/user profile info locally using Hive
class CashierInfoStorageImpl extends BaseUserLocalStorage<APUserModel> {
  CashierInfoStorageImpl._()
      : super(
          boxType: StorageBox.userProfile,
          storageKey: InvAppConstants.kUserKey,
          loggerName: 'CashierInfoStorageImpl',
        );

  static final instance = CashierInfoStorageImpl._();
}
