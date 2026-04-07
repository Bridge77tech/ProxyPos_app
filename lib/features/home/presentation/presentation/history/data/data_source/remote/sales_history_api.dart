import 'package:dio/dio.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/data/model/sales_list_model.dart';
import 'package:inventory_app_pos/network/constants/api_endpoint_const.dart';
import 'package:retrofit/error_logger.dart';
import 'package:retrofit/http.dart';

part 'sales_history_api.g.dart';

@RestApi()
abstract class SalesHistoryApi {
  factory SalesHistoryApi(Dio dio) = _SalesHistoryApi;

  @GET(APIEndpointConst.apSalesHistory)
  Future<SalesListModel> getSalesHistory(
    @Header('Authorization') String token,
    @Query('search') String? search,
    @Query('page') int? page,
  );
}
