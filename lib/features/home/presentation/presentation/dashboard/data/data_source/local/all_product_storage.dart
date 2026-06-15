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
    try {
      // Hive returns nested maps as Map<dynamic, dynamic>.
      // Deep-convert every map/list before handing to the generated fromJson
      // code which hard-casts to Map<String, dynamic>.
      final converted = _deepConvert(data);
      return ProductModel.fromJson(converted as Map<String, dynamic>);
    } catch (e) {
      // Corrupt or type-incompatible cache — discard it so the next call
      // falls through to the API instead of crashing.
      log.w('Cached products unreadable, clearing: $e');
      await clearAllProducts();
      return null;
    }
  }

  /// Recursively converts every [Map] to [Map<String, dynamic>] and every
  /// [List] to [List<dynamic>] so json_serializable casts never fail.
  static dynamic _deepConvert(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (e) => MapEntry(e.key.toString(), _deepConvert(e.value)),
        ),
      );
    }
    if (value is List) {
      return value.map(_deepConvert).toList();
    }
    return value;
  }

  @override
  Future<void> clearAllProducts() => super.clearStorage();
}
