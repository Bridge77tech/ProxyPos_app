import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/cashier_info_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';

class SaveCashierInfoUseCase {
  final CashierInfoStorageImpl _storage;
  final _log = getLogger('SaveCashierInfoUseCase');

  SaveCashierInfoUseCase(this._storage);

  /// Saves the cashier/user profile to local storage (Hive)
  /// Mirrors the token save procedure but stores the `APUserModel` under kUserKey.
  Future<void> call(APUserModel cashier) async {
    try {
      await _storage.saveData(cashier);
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}
