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
    try {
      final converted = _deepConvert(data);
      return ProductModel.fromJson(converted as Map<String, dynamic>);
    } catch (e) {
      log.w('Cached top products unreadable, clearing: $e');
      await clearTopProducts();
      return null;
    }
  }

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
  Future<void> clearTopProducts() => super.clearStorage();
}
