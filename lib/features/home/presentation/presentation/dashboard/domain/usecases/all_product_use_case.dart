import 'package:meta/meta.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/usecases/top_products_use_case.dart' show AuthSessionReader;

import '../repo/top_product_repo.dart';

/// Contract for caching all products locally.
abstract class AllProductsCache {
  Future<void> saveAllProducts(ProductModel products);
}

/// Use case: read token -> fetch all products (optionally filtered) -> cache -> return result.
@immutable
class GetAndCacheAllProductsUseCase {
  final AuthSessionReader _authSessionReader;
  final ProductRepository _repository;
  final AllProductsCache _cache;

  const GetAndCacheAllProductsUseCase(
    this._authSessionReader,
    this._repository,
    this._cache,
  );

  Future<ProductModel> call({String? search, String? category}) async {
    final token = await _authSessionReader.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token');
    }

    final model = await _repository.getAllProducts(
      'Bearer $token',
      search: search,
      category: category,
    );
    await _cache.saveAllProducts(model);
    return model;
  }
}
