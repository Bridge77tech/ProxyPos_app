import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:inventory_app_pos/network/exceptions/unauthorized_exception.dart';

import 'bad_getway_exception.dart';
import 'bad_request_exception.dart';
import 'network_exception.dart';

class ApiExceptions implements Exception {
  dynamic message;
  final int? statusCode;

  ApiExceptions({this.message, this.statusCode});

  static ApiExceptions? fromDio(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError) {
        return NetworkException();
      }
      final res = error.response;
      String? message = error.message;
      final status = res?.statusCode;

      // Try to extract a useful message from the response body
      try {
        final data = res?.data;
        Map<String, dynamic>? map;
        if (data is Map) {
          map = Map<String, dynamic>.from(data);
        } else if (data is String) {
          final trimmed = data.trimLeft();
          if (!trimmed.startsWith('<!DOCTYPE html') && trimmed.isNotEmpty) {
            try {
              final decoded = jsonDecode(trimmed);
              if (decoded is Map<String, dynamic>) {
                map = decoded;
              } else if (decoded is String && decoded.isNotEmpty) {
                message = decoded;
              } else {
                message ??= trimmed;
              }
            } catch (_) {
              // Not JSON; use raw string if not HTML
              message ??= trimmed;
            }
          }
        }
        if (map != null) {
          final m =
              map['message'] ?? map['error'] ?? map['detail'] ?? map['msg'];
          if (m != null && m.toString().isNotEmpty) {
            message = m.toString();
          } else {
            final errs = map['errors'];
            if (errs is List && errs.isNotEmpty) {
              message = errs.map((e) => e.toString()).join(', ');
            }
          }
        }
      } catch (_) {
        // ignore parsing errors, keep default message
      }

      switch (status) {
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
    return null;
  }

  @override
  String toString() {
    return message?.toString() ?? 'Request failed';
  }
}
