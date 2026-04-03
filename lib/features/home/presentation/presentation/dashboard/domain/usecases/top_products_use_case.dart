import 'package:meta/meta.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/repo/top_product_repo.dart';

/// Contract for reading the current auth token (similar to how login flow retrieves it).
abstract class AuthSessionReader {
  Future<String?> getToken();
}

/// Contract for caching top products locally (Hive-backed in the data layer).
abstract class TopProductsCache {
  Future<void> saveTopProducts(ProductModel products);
}

/// Use case that mirrors the login-style flow: read token -> hit API -> cache result.
@immutable
class GetAndCacheTopProductsUseCase {
  final AuthSessionReader _authSessionReader;
  final ProductRepository<ProductModel> _repository;
  final TopProductsCache _cache;

  const GetAndCacheTopProductsUseCase(
    this._authSessionReader,
    this._repository,
    this._cache,
  );

  /// Executes the flow and returns the fetched products.
  /// Throws if token is missing.
  Future<ProductModel> call() async {
    final token = await _authSessionReader.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token');
    }

    final productModel = await _repository.getTopProducts('Bearer $token');
    await _cache.saveTopProducts(productModel);
    return productModel;
  }
}
