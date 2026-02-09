import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../core/exceptions/session_expired_exception.dart';
import '../constants/api_endpoint_const.dart';
import '../models/api_endpoint.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  // final GetAccessTokenUseCase _getAccessToken;
  // final ClearSessionUseCase _clearSession;

  final _log = getLogger("AuthInterceptor");

  AuthInterceptor(
    // this._getAccessToken,
    // this._clearSession,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    bool requiresAuth = _requestRequiresAuth(options.path);
    if (requiresAuth) {
      try {
        // final token = await _getAccessToken();
        // if (token == null) {
        //   // await _clearSession();
        //   return handler.reject(
        //     DioException(
        //       requestOptions: options,
        //       type: DioExceptionType.cancel,
        //       error: 'Missing access token for ${options.path}',
        //     ),
        //   );
        // }

        // options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      } on SessionExpiredException catch (e) {
        _log.e(e.toString());
        // await _clearSession();
        return handler.reject(
          DioException(requestOptions: options, type: DioExceptionType.cancel),
        );
      }
    } else {
      return handler.next(options);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      _log.w('Received 401 Unauthorized; clearing session');
      // await _clearSession();
      return handler.reject(err);
    }

    return handler.next(err);
  }

  bool _requestRequiresAuth(String path) {
    final endpoint = APIEndpointConst.privateAPIEndpoint.firstWhere(
      (endpoint) => endpoint.route == path,
      orElse: () => const APIEndpoint(route: "", requiredAuth: false),
    );
    return endpoint.requiredAuth;
  }
}
