
// minimal repository for the top product
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';

abstract class ProductRepository<T> {
  // get all top products
  Future<ProductModel> getTopProducts(String token);

  // get all products
  Future<ProductModel> getAllProducts(
      String token, {
    String? search,
    String? category,
  });
}