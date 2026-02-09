
// minimal repository for the top product
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';

abstract class TopProductRepository<T> {
  Future<ProductModel> getTopProducts(String token);
}