import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/user_local_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';

/// Storage abstraction for caching all products using the shared BaseUserLocalStorage.
abstract class AllProductsStorage {
  Future<void> saveAllProducts(ProductModel model);
  Future<ProductModel?> getAllProducts();
  Future<void> clearAllProducts();
}

class AllProductsStorageImpl extends BaseUserLocalStorage<dynamic> implements AllProductsStorage {
  AllProductsStorageImpl._()
      : super(
          boxType: StorageBox.allProducts,
          storageKey: 'all_products',
          loggerName: 'AllProductsStorage',
        );

  static final instance = AllProductsStorageImpl._();

  @override
  Future<void> saveAllProducts(ProductModel model) async {
    await super.saveData(model.toJson());
  }

  @override
  Future<ProductModel?> getAllProducts() async {
    final data = await super.getStorageData();
    if (data == null) return null;
    final map = Map<String, dynamic>.from(data as Map);
    return ProductModel.fromJson(map);
  }

  @override
  Future<void> clearAllProducts() => super.clearStorage();
}
