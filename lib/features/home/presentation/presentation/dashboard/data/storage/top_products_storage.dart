import 'package:hive_ce/hive.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';

/// Storage abstraction for caching top products using Hive.
abstract class TopProductsStorage {
  Future<void> saveTopProducts(ProductModel model);
  Future<ProductModel?> getTopProducts();
  Future<void> clearTopProducts();
}

class TopProductsStorageImpl implements TopProductsStorage {
  static const String _boxName = 'top_products_v1';
  static const String _key = 'top_products';

  final Future<Box> Function(String name) _openBox;
  final Future<void> Function(String name)? _closeBox;

  /// Provide functions to open/close boxes to mirror your LocalStorageServiceImpl.
  /// Example injection: (name) => LocalStorageServiceImpl.instance.openBox(name)
  TopProductsStorageImpl(this._openBox, {Future<void> Function(String name)? closeBox})
      : _closeBox = closeBox;

  @override
  Future<void> saveTopProducts(ProductModel model) async {
    Box box = await _openBox(_boxName);
    await box.put(_key, model.toJson());
    await _maybeClose();
  }

  @override
  Future<ProductModel?> getTopProducts() async {
    Box box = await _openBox(_boxName);
    final data = box.get(_key);
    await _maybeClose();
    if (data is Map) {
      return ProductModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  @override
  Future<void> clearTopProducts() async {
    Box box = await _openBox(_boxName);
    await box.delete(_key);
    await _maybeClose();
  }

  Future<void> _maybeClose() async {
    if (_closeBox != null) {
      await _closeBox!(_boxName);
    }
  }
}
