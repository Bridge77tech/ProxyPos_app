import 'package:meta/meta.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';

/// Contract for reading the current auth token (similar to how login flow retrieves it).
abstract class AuthSessionReader {
  Future<String?> getToken();
}

/// Contract for fetching top products from a remote source.
abstract class TopProductRepository {
  Future<ProductModel> getTopProducts({required String token});
}

/// Contract for caching top products locally (Hive-backed in the data layer).
abstract class TopProductsCache {
  Future<void> saveTopProducts(ProductModel products);
}

/// Use case that mirrors the login-style flow: read token -> hit API -> cache result.
@immutable
class GetAndCacheTopProductsUseCase {
  final AuthSessionReader _authSessionReader;
  final TopProductRepository _repository;
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

    final productModel = await _repository.getTopProducts(token: 'Bearer $token');
    await _cache.saveTopProducts(productModel);
    return productModel;
  }
}
