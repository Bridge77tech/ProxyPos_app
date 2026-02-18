import 'package:dio/dio.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/product_sale_model.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';

import 'package:inventory_app_pos/network/constants/api_endpoint_const.dart';

part 'create_new_sale_api.g.dart';

@RestApi()
abstract class CreateNewSaleApi {
  factory CreateNewSaleApi(Dio dio) = _CreateNewSaleApi;

  @POST(APIEndpointConst.apCreateNewSale)
  Future<ProductSaleModel> createNewSale(
    @Header('Authorization') String bearerToken,
    @Body() Map<String, dynamic> payload,
  );
}