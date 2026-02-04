import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_haus_state_status.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter/cupertino.dart';
import 'package:inventory_app_pos/core/exceptions/auth_exception.dart';
import 'package:inventory_app_pos/core/exceptions/local_storage_exception.dart';
import 'package:inventory_app_pos/core/routing/navigation_helper.dart';
import 'package:inventory_app_pos/core/routing/route_constants.dart';
import 'package:inventory_app_pos/data/local_storage_service.dart';
import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_token_model.dart';
import 'package:inventory_app_pos/features/auth/data/session/auth_session_storage_hive.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/login_use_case.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_user_info_use_case.dart';
import 'package:inventory_app_pos/features/home/data/model/product_model.dart';
import 'package:inventory_app_pos/features/home/domain/usecases/get_top_product_use_case.dart';
import 'package:inventory_app_pos/network/exceptions/api_exceptions.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc<T> extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase<T> _authUseCase;
  final SaveUserInfoUseCase _saveUserInfoUseCase;
  final GetTopProductUseCase _getTopProductUseCase;
  final ILocalStorageService _storage;
  final _log = getLogger('AuthBloc');

  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  AuthBloc(
    this._authUseCase,
    this._saveUserInfoUseCase,
    this._getTopProductUseCase,
    this._storage,
  ) : super(const AuthState()) {
    on<LoginFormSubmitted>(_onLoginButtonPressed);
    on<UsernameChanged>(_onUsernameChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<SaveUserInfo>(_onSaveUserInfo);
  }

  void _onUsernameChanged(UsernameChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(username: event.username));
  }

  void _onPasswordChanged(PasswordChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onLoginButtonPressed(
    LoginFormSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    ApUserModel? user;
    final payload = {'username': state.username, 'password': state.password};

    emit(state.copyWith(stateStatus: const LoggingInUser()));

    try {
      final T rawResult = await _authUseCase(payload);

      if (rawResult is Map<String, dynamic>) {
        final mapResult = rawResult;
        // Persist tokens to session if present in login response
        try {
          if (mapResult.containsKey('access') ||
              mapResult.containsKey('refresh')) {
            final token = UserToken.fromJson(mapResult);
            await AuthSessionStorageHive.instance.write(token);
          }
        } catch (_) {
          // Ignore token persist errors; interceptor will handle refresh later
        }
        final dynamic userJson = mapResult['user'] ?? mapResult;
        if (userJson is Map<String, dynamic>) {
          user = ApUserModel.fromJson(userJson);
        }
        if (user != null) {
          add(SaveUserInfo(user));
          emit(state.copyWith(stateStatus: LoginSuccess()));
          return;
        }
        // Fallback when response lacks expected structure
        emit(
          state.copyWith(stateStatus: ErrorStatus('Unexpected login response')),
        );
        return;
      }
      // Non-map response
      emit(
        state.copyWith(
          stateStatus: ErrorStatus('Unexpected login response type'),
        ),
      );
    } on AuthException catch (e, st) {
      _log.e('Login failed: ${e.message}');
      _log.e(st.toString());
      emit(
        state.copyWith(
          stateStatus: ErrorStatus(e.message),
          errorMessage: e.message,
        ),
      );
    } on ApiExceptions catch (e, st) {
      _log.e('Login failed: ${e.toString()}');
      _log.e(st.toString());
      emit(
        state.copyWith(
          stateStatus: ErrorStatus(e.toString()),
          errorMessage: e.toString(),
        ),
      );
    } catch (e, st) {
      _log.e('Login failed: $e');
      _log.e(st.toString());
      emit(
        state.copyWith(
          stateStatus: const ErrorStatus('Request failed'),
          errorMessage: 'Request failed',
        ),
      );
    } finally {
      emit(state.copyWith(stateStatus: const InitStatus()));
    }
  }

  Future<void> _onSaveUserInfo(
    SaveUserInfo event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _saveUserInfoUseCase(event.userInfo);
      // Prefetch top products and cache to Hive to speed up initial dashboard
      try {
        await _storage.init();
        final raw = await _getTopProductUseCase.call(const {});
        final products = raw
            .whereType<Map<String, dynamic>>()
            .map((json) => Products.fromJson(json))
            .toList();
        await _storage.openBox<List>(StorageBox.topProducts);
        final box = _storage.getBox<List>(StorageBox.topProducts.name);
        await box.put('top_products', products.map((p) => p.toJson()).toList());
      } catch (_) {
        // Ignore prefetch errors; dashboard will fetch on-demand
      }
      emit(state.copyWith(stateStatus: LoginSuccess()));
      NavigationHelper.popAllAndPushNamed(
        InvRouteConstants.apHomeRoute.routeName,
      );
    } on LocalStorageException catch (e) {
      _log.e('Failed to save user info: ${e.message}');
      emit(
        state.copyWith(
          stateStatus: ErrorStatus(
            e.message ?? "Unable to login user at this time.",
          ),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _log.i('AuthBloc closed');
    return super.close();
  }
}
