import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/user_local_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';

/// Storage abstraction for caching top products using the shared BaseUserLocalStorage.
abstract class TopProductsStorage {
  Future<void> saveTopProducts(ProductModel model);
  Future<ProductModel?> getTopProducts();
  Future<void> clearTopProducts();
}

class TopProductsStorageImpl extends BaseUserLocalStorage<dynamic> implements TopProductsStorage {
  TopProductsStorageImpl._() : super(
    boxType: StorageBox.topProducts,
    storageKey: 'top_products',
    loggerName: 'TopProductsStorage',
  );

  static final instance = TopProductsStorageImpl._();

  @override
  Future<void> saveTopProducts(ProductModel model) async {
    await super.saveData(model.toJson());
  }

  @override
  Future<ProductModel?> getTopProducts() async {
    final data = await super.getStorageData();
    if (data == null) return null;
    // Ensure we have a String-keyed map
    final map = Map<String, dynamic>.from(data as Map);
    return ProductModel.fromJson(map);
  }

  @override
  Future<void> clearTopProducts() => super.clearStorage();
}
