import 'package:dio/dio.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';
import 'package:inventory_app_pos/network/constants/api_endpoint_const.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';

part 'top_product_api_service.g.dart';

@RestApi()
abstract class ProductAPIService {
  factory ProductAPIService(Dio dio) = _ProductAPIService;

  @GET(APIEndpointConst.apTopProduct)
  Future<ProductModel> getTopProducts(@Header('Authorization') String token);

  @GET(APIEndpointConst.apAllProduct)
  Future<ProductModel> getAllProducts(
    @Header('Authorization') String token,
    @Query('search') String? search,
    @Query('category') String? category,
  );
}