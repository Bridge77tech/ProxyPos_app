// import 'package:dio/dio.dart';
// import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';
// import 'package:inventory_app_pos/network/models/api_response.dart';
// import 'package:retrofit/retrofit.dart';
//
// part 'auth_api_service.g.dart';
//
// @RestApi()
// abstract class AuthAPIService {
//   factory AuthAPIService(Dio dio) = _AuthAPIService;
//
//   @POST('/auth/login')
//   Future<APIResponse<APUserModel>> login(@Body() Map<String, dynamic> body);
//
//   // Fetch the currently authenticated user's profile
//   @GET('/auth/profile')
//   Future<APUserModel> profile(
//     @Header('Authorization') String authorization,
//   );
// }
