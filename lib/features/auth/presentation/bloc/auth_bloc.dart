import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_haus_state_status.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter/cupertino.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:inventory_app_pos/core/exceptions/local_storage_exception.dart';
import 'package:inventory_app_pos/core/exceptions/login_exception.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/login_use_case.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_user_use_case.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/all_product_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/top_products_storage.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/cashier_info_storage_impl.dart';

import '../../../../core/routing/inv_navigator_keys.dart';
import '../../../../core/routing/navigation_helper.dart';
import '../../../../core/routing/route_constants.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc<T> extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase<T> _loginUseCase;
  final SaveUserInfoUseCase _saveUserInfoUseCase;
  APUserModel? user;
  final _log = getLogger('AuthBloc');

  FocusNode usernameFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  AuthBloc(this._loginUseCase, this._saveUserInfoUseCase) : super(const AuthState()) {
    on<LoginFormSubmitted>(_onLoginButtonPressed);
    on<UsernameChanged>(_onUsernameChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<SaveUserInfo>(_onSaveUserInfo);
    on<LogoutRequested>(_onLogoutRequested);
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
    final payload = {
      'username': state.username.trim(),
      'password': state.password.trim(),
    };

    emit(state.copyWith(stateStatus: const LoggingInUser()));

    try {
      final UserModel rawData = await _loginUseCase(payload);

      debugPrint('Login response: ${rawData.token}');

      if(rawData.user != null) {
        add(SaveUserInfo(rawData));
      }

      emit(state.copyWith(stateStatus: LoginSuccess()));

    } on LoginException catch (e, st) {
      _log.e('Login failed: ${e.message}');
      _log.e(st.toString());
      emit(
        state.copyWith(
          stateStatus: ErrorStatus(
            e.message ?? "Unable to login user at this time.",
          ),
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
      // Prefetch top products and cache to Hive to speed up initial dashboard
      await _saveUserInfoUseCase(event.userInfo);
      emit(state.copyWith(stateStatus: LoginSuccess()));
      NavigationHelper.popAllAndPushNamed(
        InvRouteConstants.apHomeRoute.routeName,
      );
      // Hide the global loader once the home page is in the tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = APNavigatorKeys.rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ctx.loaderOverlay.hide();
        }
      });
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

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      _log.i('Clearing session storages on logout (pending sales preserved)...');
      await Future.wait([
        AuthSessionStorageImpl.instance.clearStorage(),
        CashierInfoStorageImpl.instance.clearStorage(),
        TopProductsStorageImpl.instance.clearTopProducts(),
        AllProductsStorageImpl.instance.clearAllProducts(),
        // NOTE: PendingSalesStorageImpl is intentionally NOT cleared here —
        // offline orders survive logout and sync after the next login.
      ]);
      _log.i('Session storages cleared');
      emit(const AuthState());
      NavigationHelper.popAllAndPushNamed(
        InvRouteConstants.loginRoute.routeName,
      );
    } catch (e, st) {
      _log.e('Failed to clear storages on logout', error: e, stackTrace: st);
    }
  }

  @override
  Future<void> close() {
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    _log.i('AuthBloc closed');
    return super.close();
  }
}
