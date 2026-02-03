import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../model/user_token_model.dart';

part 'auth_api_service.g.dart';

@RestApi()
abstract class AuthAPIService {
  factory AuthAPIService(Dio dio, {String baseUrl}) = _AuthAPIService;

  @POST('/auth/refresh')
  Future<UserToken> refresh(@Body() Map<String, dynamic> body);

  @POST('/auth/login')
  Future<HttpResponse<dynamic>> login(@Body() Map<String, dynamic> body);

  // Fetch the currently authenticated user's profile
  @GET('/auth/profile')
  Future<HttpResponse<dynamic>> profile(
    @Header('Authorization') String authorization,
  );
}
