import 'package:dio/dio.dart';
import 'package:inventory_app_pos/core/services/connectivity_service.dart';

/// Dio interceptor that checks network connectivity before making requests.
///
/// If the device is offline, immediately rejects the request with a
/// [DioException] of type [DioExceptionType.connectionError] instead of
/// waiting for a network timeout.
///
/// This provides:
/// - Fail-fast behavior for offline scenarios
/// - Consistent error handling across all API calls
/// - Better UX with immediate offline feedback
class ConnectivityInterceptor extends Interceptor {
  final ConnectivityService _connectivityService;

  ConnectivityInterceptor({ConnectivityService? connectivityService})
    : _connectivityService =
          connectivityService ?? ConnectivityService.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _connectivityService.checkConnectivity().then((isOnline) {
      if (!isOnline) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'No internet connection',
          ),
          true, // Call onError handlers
        );
      }
      handler.next(options);
    });
  }
}