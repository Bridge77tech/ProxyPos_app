import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/cashier_info_storage_impl.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/all_product_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/top_products_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/pending_sales_storage.dart';

class ClearSessionUseCase {
  final AuthSessionStorageImpl _authSession;
  final _log = getLogger('ClearSessionUseCase');

  ClearSessionUseCase(this._authSession);

  Future<void> call() async {
    _log.i('Clearing all local storages...');
    try {
      await Future.wait([
        _authSession.clearStorage(),
        CashierInfoStorageImpl.instance.clearStorage(),
        TopProductsStorageImpl.instance.clearTopProducts(),
        AllProductsStorageImpl.instance.clearAllProducts(),
        PendingSalesStorageImpl.instance.clear(),
      ]);
      _log.i('All local storages cleared successfully');
    } catch (e, st) {
      _log.e('Failed to clear some storages', error: e, stackTrace: st);
      // Still throw so calling code knows something went wrong
      rethrow;
    }
  }
}