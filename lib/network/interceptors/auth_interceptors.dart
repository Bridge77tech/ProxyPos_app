import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../core/exceptions/access_token_expired_exception.dart';
import '../../core/exceptions/session_expired_exception.dart';
import '../../features/auth/domain/usecases/attempt_token_refresh_usecase.dart';
import '../../features/auth/domain/usecases/clear_session_usecase.dart';
import '../../features/auth/domain/usecases/get_access_token_usecase.dart';
import '../constants/api_endpoint_const.dart';
import '../models/api_endpoint.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final GetAccessTokenUseCase _getAccessToken;
  final ClearSessionUseCase _clearSession;
  final AttemptTokenRefreshUseCase _attemptTokenRefresh;
  final Dio _dioInstance;

  final _log = getLogger("AuthInterceptor");

  AuthInterceptor(
    this._getAccessToken,
    this._clearSession,
    this._dioInstance,
    this._attemptTokenRefresh,
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    bool requiresAuth = _requestRequiresAuth(options.path);
    if (requiresAuth) {
      try {
        final token = await _getAccessToken();
        if (token == null) {
          await _clearSession();
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
        }

        options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      } on SessionExpiredException catch (e) {
        _log.e(e.toString());
        await _clearSession();
        return handler.reject(
          DioException(requestOptions: options, type: DioExceptionType.cancel),
        );
      } on AccessTokenExpiredException {
        await _refreshAndRetry(options);
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
    if (err.response?.statusCode == 401 &&
        err.response?.extra['isRetry'] != true) {
      _log.w('Received 401 Unauthorized, attempting token refresh');

      try {
        final response = await _refreshAndRetry(err.requestOptions);
        return handler.resolve(response);
      } on SessionExpiredException catch (e) {
        _log.e('Session expired: $e');
        await _clearSession();
        return handler.reject(err);
      } catch (e) {
        _log.e('Token refresh failed: $e');
        await _clearSession();
        return handler.reject(err);
      }
    }

    return handler.next(err);
  }

  /// Refreshes the access token and retries the failed request
  ///
  /// Returns the response from the retried request
  /// Throws [SessionExpiredException] if refresh token is expired
  /// Throws other exceptions if token refresh fails
  Future<Response<dynamic>> _refreshAndRetry(
    RequestOptions requestOptions,
  ) async {
    final refreshed = await _attemptTokenRefresh();
    if (!refreshed) {
      throw SessionExpiredException('Unable to refresh token');
    }

    final token = await _getAccessToken();
    if (token == null) {
      throw SessionExpiredException('Session expired');
    }

    _log.i('Token refresh successful, retrying original request');

    requestOptions.headers['Authorization'] = 'Bearer $token';
    requestOptions.extra['isRetry'] = true;

    final response = await _dioInstance.fetch(requestOptions);
    return response;
  }

  bool _requestRequiresAuth(String path) {
    final endpoint = APIEndpointConst.privateAPIEndpoint.firstWhere(
      (endpoint) => endpoint.route == path,
      orElse: () => const APIEndpoint(route: "", requiredAuth: false),
    );
    return endpoint.requiredAuth;
  }
}
