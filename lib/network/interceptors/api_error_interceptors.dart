import 'package:dio/dio.dart';
import 'package:inventory_app_pos/network/exceptions/api_exceptions.dart';

class ApiErrorInterceptors extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
          requestOptions: err.requestOptions,
        type: err.type,
        error: ApiExceptions.fromDio(err),
      ),
    );
  }
}