import '../../domain/usecases/top_products_use_case.dart';
import 'top_products_storage.dart';
import '../model/products_model.dart';

/// Cache implementation that saves/fetches via Hive storage.
class TopProductsCacheImpl implements TopProductsCache {
  final TopProductsStorage _storage;

  TopProductsCacheImpl(this._storage);

  @override
  Future<void> saveTopProducts(ProductModel products) {
    return _storage.saveTopProducts(products);
  }
}
