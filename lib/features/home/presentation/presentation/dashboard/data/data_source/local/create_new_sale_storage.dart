import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/user_local_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/product_sale_model.dart';

/// Storage abstraction for caching newly created sales using the shared BaseUserLocalStorage.
abstract class CreateNewSaleStorage {
  Future<void> saveSale(ProductSaleModel model);
  Future<ProductSaleModel?> getSale();
  Future<void> clearSale();
}

class CreateNewSaleStorageImpl extends BaseUserLocalStorage<dynamic> implements CreateNewSaleStorage {
  CreateNewSaleStorageImpl._()
      : super(
          boxType: StorageBox.createNewSale,
          storageKey: 'create_new_sale',
          loggerName: 'CreateNewSaleStorage',
        );

  static final instance = CreateNewSaleStorageImpl._();

  @override
  Future<void> saveSale(ProductSaleModel model) async {
    // Persist as Map<String, dynamic> to avoid typed Map issues
    await super.saveData(model.toJson());
  }

  @override
  Future<ProductSaleModel?> getSale() async {
    final data = await super.getStorageData();
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data as Map);
    return ProductSaleModel.fromJson(map);
  }

  @override
  Future<void> clearSale() => super.clearStorage();
}
