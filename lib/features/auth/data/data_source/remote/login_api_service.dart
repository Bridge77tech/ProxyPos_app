import 'package:dio/dio.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../../network/constants/api_endpoint_const.dart';

part 'login_api_service.g.dart';

@RestApi()
abstract class LoginAPIService {
  factory LoginAPIService(Dio dio) = _LoginAPIService;

  @POST(APIEndpointConst.apLogin)
  Future<UserModel> loginUser(@Body() Map<String, dynamic> payload);
}
