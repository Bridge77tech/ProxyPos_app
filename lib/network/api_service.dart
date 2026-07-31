import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/cupertino.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/remote/top_product_api_service.dart';
import 'package:inventory_app_pos/network/constants/api_string_const.dart';
import 'package:inventory_app_pos/network/interceptors/auth_interceptors.dart';
import 'package:inventory_app_pos/network/interceptors/connectivity_interceptors.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../features/auth/domain/usecases/clear_session_usecase.dart';
import '../features/auth/domain/usecases/get_access_token_use_case.dart';
import '../features/auth/domain/usecases/save_user_token_use_case.dart';
import 'interceptors/api_error_interceptors.dart';

class APIService {
  late Dio _dio;

  Dio get dioInstance => _dio;

  static final APIService _instance = APIService._internal(
    authSessionStorage: AuthSessionStorageImpl.instance,
  );

  factory APIService() => _instance;

  @visibleForTesting
  factory APIService.forTesting({
    required AuthSessionStorageImpl authSessionStorage,
    Dio? dio,
  }) {
    return APIService._internal(
      authSessionStorage: authSessionStorage,
      dio: dio,
    );
  }

  late final GetAccessTokenUseCase _getAccessToken;
  late final ClearSessionUseCase _clearSession;
  late final SaveUserTokenUseCase _saveUserToken;
  // ignore: unused_field
  late final ProductAPIService _productAPIService;

  APIService._internal({
    required AuthSessionStorageImpl authSessionStorage,
    Dio? dio,
  }) {
    _dio = dio ?? Dio();
    _clearSession = ClearSessionUseCase(authSessionStorage);
    _saveUserToken = SaveUserTokenUseCase(authSessionStorage);
    // Pass baseUrl override to include API prefix if needed
    _productAPIService = ProductAPIService(_dio);
    _getAccessToken = GetAccessTokenUseCase(
      authSessionStorage,
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
        _saveUserToken,
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
