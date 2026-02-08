
import 'package:dio/dio.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';
import 'package:inventory_app_pos/network/constants/api_endpoint_const.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';

part 'top_product_api_service.g.dart';

@RestApi()
abstract class TopProductAPIService {
  factory TopProductAPIService(Dio dio) = _TopProductAPIService;

  @GET(APIEndpointConst.apTopProduct)
  Future<ProductModel> getTopProducts(@Header('Authorization') String token);
}