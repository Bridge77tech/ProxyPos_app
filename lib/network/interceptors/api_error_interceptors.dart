import 'package:dio/dio.dart';
import 'package:inventory_app_pos/network/exceptions/api_exceptions.dart';

class APIErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: APIExceptions.fromDio(err) ?? err.error,
        message: err.message,
      ),
    );
  }
}
