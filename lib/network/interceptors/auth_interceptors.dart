import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../core/exceptions/session_expired_exception.dart';
import '../../core/routing/navigation_helper.dart';
import '../../core/routing/route_constants.dart';
import '../../features/auth/data/data_source/local/auth_session_storage_impl.dart';
import '../../features/auth/domain/usecases/clear_session_usecase.dart';
import '../../features/auth/domain/usecases/get_access_token_use_case.dart';
import '../constants/api_endpoint_const.dart';
import '../models/api_endpoint.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final GetAccessTokenUseCase _getAccessToken;
  final ClearSessionUseCase _clearSession;

  final _log = getLogger("AuthInterceptor");

  AuthInterceptor(
    this._getAccessToken,
    this._clearSession,
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

        options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      } on SessionExpiredException catch (e) {
        _log.e('Session expired: ${e.toString()}');
        await _clearSession();
        // Navigate to login page
        _navigateToLogin();
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'Session expired. Please login again.',
          ),
        );
      } catch (e) {
        _log.e('Error getting access token: ${e.toString()}');
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: e,
          ),
        );
      }
    } else {
      return handler.next(options);
    }
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Sliding session: pick up the token the backend silently refreshes on
    // every authenticated request, so an active user is never logged out.
    final refreshedToken = response.headers.value('x-refreshed-token');
    if (refreshedToken != null && refreshedToken.isNotEmpty) {
      try {
        await AuthSessionStorageImpl.instance.saveData(refreshedToken);
      } catch (e) {
        _log.w('Failed to persist refreshed token: ${e.toString()}');
      }
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Check if this is a login request - don't logout on failed login
      final isLoginRequest = !_requestRequiresAuth(err.requestOptions.path);

      if (isLoginRequest) {
        // This is a failed login attempt (wrong credentials)
        // Don't clear session or navigate - just pass the error through
        _log.i('Login failed with 401 (invalid credentials), not clearing session');
        return handler.next(err);
      }

      // This is a 401 on a protected endpoint - session expired
      _log.w('Received 401 Unauthorized on protected endpoint; clearing session and logging out');
      await _clearSession();
      // Navigate to login page
      _navigateToLogin();
      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: 'Session expired. Please login again.',
        ),
      );
    }

    return handler.next(err);
  }

  /// Navigate to login page and clear navigation stack
  void _navigateToLogin() {
    try {
      _log.i('Navigating to login page due to session expiry');
      // Clear all routes and navigate to login
      NavigationHelper.popAllAndPushNamed(
        InvRouteConstants.loginRoute.routeName,
      );
    } catch (e) {
      _log.e('Failed to navigate to login: ${e.toString()}');
    }
  }

  bool _requestRequiresAuth(String path) {
    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Check against private endpoints
    final endpoint = APIEndpointConst.privateAPIEndpoint.firstWhere(
      (endpoint) => cleanPath.endsWith(endpoint.route) || cleanPath == endpoint.route,
      orElse: () => const APIEndpoint(route: "", requiredAuth: false),
    );

    // If found in private list and requires auth, return true
    if (endpoint.route.isNotEmpty && endpoint.requiredAuth) {
      _log.i('Path "$path" requires authentication');
      return true;
    }

    // Check if it's explicitly in the public list
    final publicEndpoint = APIEndpointConst.publicAPIEndpoint.firstWhere(
      (endpoint) => cleanPath.endsWith(endpoint.route) || cleanPath == endpoint.route,
      orElse: () => const APIEndpoint(route: "", requiredAuth: false),
    );

    if (publicEndpoint.route.isNotEmpty) {
      _log.i('Path "$path" is public (no auth required)');
      return false;
    }

    // Default: require auth if not explicitly marked as public
    _log.w('Path "$path" not found in endpoint lists, defaulting to requiring auth');
    return true;
  }
}
