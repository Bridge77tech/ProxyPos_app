import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/exceptions/login_exception.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/remote/login_api_service.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';
import 'package:inventory_app_pos/network/exceptions/bad_request_exception.dart';

import '../../domain/repositories/auth_repository.dart';

class LoginRepositoryImpl<T> implements LoginRepository<T> {
  final LoginAPIService _loginAPIService;
  final _log = getLogger('LoginRepositoryImpl');


  LoginRepositoryImpl(this._loginAPIService);


  @override
  Future<UserModel> login(Map<String, dynamic> payload) async {
    try {
      // Retrofit parses the response into UserModel already
      final UserModel res = await _loginAPIService.loginUser(payload);
      _log.i("testing ${res.toString()}");
      return res;
    } on DioException catch (e) {
      _log.e(e.toString());

      // Prefer specific error message if available
      String? message;
      if (e.error is BadRequestException) {
        message = (e.error as BadRequestException).message;
      }
      // fallback to Dio's message or a generic
      message ??= e.message ?? 'Request failed';

      throw LoginException(message: message);
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}
