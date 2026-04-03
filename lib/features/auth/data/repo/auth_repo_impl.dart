import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/exceptions/login_exception.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/remote/login_api_service.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';

import '../../domain/repositories/auth_repository.dart';

class LoginRepositoryImpl<T> implements LoginRepository<T> {
  final LoginAPIService _loginAPIService;
  final AuthSessionStorageImpl _authStorage;
  final _log = getLogger('LoginRepositoryImpl');


  LoginRepositoryImpl(
    this._loginAPIService, {
    AuthSessionStorageImpl? authStorage,
  }) : _authStorage = authStorage ?? AuthSessionStorageImpl.instance;


  @override
  Future<UserModel> login(Map<String, dynamic> payload) async {
    try {
      // Retrofit parses the response into UserModel already
      final UserModel res = await _loginAPIService.loginUser(payload);
      _log.i("Login successful for user: ${res.user?.username ?? 'unknown'}");
      return res;
    } on DioException catch (e) {
      _log.e('Login failed with status ${e.response?.statusCode}: ${e.message}');

      // If 401 or authentication error, clear any existing token
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        _log.w('Authentication failed (${e.response?.statusCode}), clearing any existing token');
        try {
          await _authStorage.clearStorage();
        } catch (clearError) {
          _log.e('Failed to clear storage after auth failure: $clearError');
        }
      }

      // Extract clean error message from server response
      String message = 'Login failed';

      try {
        // Try to get message from response body
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          message = responseData['message']?.toString() ??
                    responseData['error']?.toString() ??
                    message;
        }
      } catch (_) {
        // If parsing fails, use status-based messages
      }

      // Use status-based messages if no server message
      if (message == 'Login failed') {
        if (e.response?.statusCode == 401) {
          message = 'Invalid username or password';
        } else if (e.response?.statusCode == 403) {
          message = 'Access denied. Contact administrator.';
        } else if (e.response?.statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else if (e.type == DioExceptionType.connectionTimeout) {
          message = 'Connection timeout. Check your internet.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          message = 'Server took too long to respond.';
        } else if (e.type == DioExceptionType.unknown) {
          message = 'Network error. Check your connection.';
        }
      }

      throw LoginException(message: message);
    } catch (e) {
      _log.e('Unexpected error during login: ${e.toString()}');
      throw LoginException(message: 'An unexpected error occurred');
    }
  }
}
