import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/cupertino.dart';
import 'package:inventory_app_pos/network/constants/api_string_const.dart';
import 'package:inventory_app_pos/network/interceptors/auth_interceptors.dart';
import 'package:inventory_app_pos/network/interceptors/connectivity_interceptors.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../features/auth/data/remote/auth_api_service.dart';
import '../features/auth/data/repositories/auth_repo_impl.dart';
import '../features/auth/data/session/auth_session_storage.dart';
import '../features/auth/data/session/auth_session_storage_hive.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/attempt_token_refresh_usecase.dart';
import '../features/auth/domain/usecases/clear_session_usecase.dart';
import '../features/auth/domain/usecases/get_access_token_usecase.dart';
import '../features/home/data/remote/home_api_service.dart';
import 'interceptors/api_error_interceptors.dart';

class APIService {
  late Dio _dio;

  Dio get dioInstance => _dio;

  static final APIService _instance = APIService._internal(
    authSessionStorage: AuthSessionStorageHive.instance,
  );

  factory APIService() => _instance;

  @visibleForTesting
  factory APIService.forTesting({
    required AuthSessionStorage authSessionStorage,
    Dio? dio,
  }) {
    return APIService._internal(
      authSessionStorage: authSessionStorage,
      dio: dio,
    );
  }

  late final GetAccessTokenUseCase _getAccessToken;
  late final ClearSessionUseCase _clearSession;
  late final AttemptTokenRefreshUseCase _attemptTokenRefresh;
  late final AuthRepository _authRepo;
  late final AuthAPIService _authAPIService;
  // ignore: unused_field
  late final HomeAPIService _homeAPIService;

  APIService._internal({
    required AuthSessionStorage authSessionStorage,
    Dio? dio,
  }) {
    _dio = dio ?? Dio();
    _clearSession = ClearSessionUseCase(authSessionStorage);
    // Pass baseUrl override to include API prefix if needed
    _authAPIService = AuthAPIService(_dio, baseUrl: APIStringConst.apAPIPrefix);
    _authRepo = AuthRepoImpl(_authAPIService);
    _homeAPIService = HomeAPIService(_dio, baseUrl: APIStringConst.apAPIPrefix);
    _attemptTokenRefresh = AttemptTokenRefreshUseCase(
      authSessionStorage,
      _authRepo,
      _clearSession.call,
    );
    _getAccessToken = GetAccessTokenUseCase(
      authSessionStorage,
      _attemptTokenRefresh,
      _clearSession,
    );
    _configureDio();
  }

  void _configureDio() {
    _dio.options
      ..receiveDataWhenStatusError = true
      ..validateStatus = (status) {
        return status != null && status >= 200 && status < 300;
      }
      ..baseUrl = APIStringConst.apAPIBaseURL
      ..contentType = Headers.jsonContentType
      ..headers = {..._dio.options.headers, 'Accept': Headers.jsonContentType}
      ..connectTimeout = 15.seconds
      ..receiveTimeout = 30.seconds;

    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return HttpClient()..idleTimeout = 15.seconds;
    };

    _dio.interceptors.addAll([
      ConnectivityInterceptor(),
      AuthInterceptor(
        _getAccessToken,
        _clearSession,
        _dio,
        _attemptTokenRefresh,
      ),
      APIErrorInterceptor(),
      RetryInterceptor(
        dio: _dio,
        logPrint: print,
        retries: 2,
        retryDelays: [1.seconds, 2.seconds],
      ),
      PrettyDioLogger(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
        compact: true,
        maxWidth: 150,
      ),
    ]);
  }
}
