// import 'package:dio/dio.dart';
// import 'package:inventory_app_pos/network/models/api_response.dart';
// import 'package:retrofit/retrofit.dart';
//
// part 'home_api_service.g.dart';
//
// @RestApi()
// abstract class HomeAPIService {
//   factory HomeAPIService(Dio dio, {String baseUrl}) = _HomeAPIService;
//
//   /// Get all products that are in stock
//   @GET('/pos/products')
//   Future<APIResponse<dynamic>> getProductsInStock({
//     @Query('in_stock') bool inStock = true,
//   });
//
//   @GET('/pos/products/top-products')
//   Future<APIResponse<dynamic>> getTopProducts({@Query('limit') int limit = 20});
// }
