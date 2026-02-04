/// Minimal repository interface for Home feature.
abstract class HomeRepository<T> {
  /// Retrieve all products that are in stock.
  /// Returns the raw HttpResponse for HomeBloc to handle.
  Future<T> getProductsInStock(Map<String, dynamic> params);

  /// Retrieve top products based on certain criteria.
  /// Returns a list of dynamic objects representing top products.
  Future<List<dynamic>> getTopProducts(Map<String, dynamic> params);
}
