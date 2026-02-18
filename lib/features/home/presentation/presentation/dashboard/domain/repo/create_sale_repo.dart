import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/product_sale_model.dart';

/// Repository contract for creating a new sale.
/// Implementations should call the remote API and may cache the result locally.
abstract class CreateSaleRepository {
  /// Create a new sale using the provided bearer [token] and request [payload].
  ///
  /// [token] should be passed as a full header value, e.g. "Bearer <accessToken>".
  /// Returns a [ProductSaleModel] parsed from the API response.
  Future<ProductSaleModel> createSale({
    required String token,
    required Map<String, dynamic> payload,
  });
}
