import 'package:dio/dio.dart';
import 'package:inventory_app_pos/network/exceptions/unauthorized_exception.dart';

import 'bad_getway_exception.dart';
import 'bad_request_exception.dart';

class ApiExceptions implements Exception {
  dynamic message;
  final int? statusCode;

  ApiExceptions({this.message, this.statusCode});

  static ApiExceptions fromDio(Object error) {
    if (error is DioException) {
      final res = error.response;
      final message = error.message;
      final status = res?.statusCode;

      switch(status) {
        case 401:
          return UnauthorizedException(message: message);
        case 400:
        case 422:
        case 404:
          return BadRequestException(message: message, statusCode: status);
        case 500:
          return BadGatewayException(message: message, statusCode: status);
        default:
          return ApiExceptions(message: message, statusCode: status);
      }
    }
  }

  @override
  String toString() {
    return 'APIException(message: $message, statusCode: $statusCode)';
  }
}