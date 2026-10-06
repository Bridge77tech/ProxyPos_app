import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_haus_state_status.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter/cupertino.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:inventory_app_pos/core/update/update_coordinator.dart';
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

    // Tell the server which build this till is running.
    //
    // Sent on login because that is the one request every till makes, from a machine
    // nobody can see, on a schedule nobody controls. Without it "has every till taken
    // the update?" is unanswerable — and that question is step 2 of any safe move of
    // the update-check address, where guessing wrong strands a shop permanently.
    //
    // Best-effort by design. A till whose version cannot be read must still be able to
    // log in and sell; the field is simply omitted and the server leaves the previous
    // value alone.
    final version = await UpdateCoordinator.currentVersion();
    if (version != null) payload['appVersion'] = version.toString();

    emit(state.copyWith(stateStatus: const LoggingInUser()));

    try {
      final UserModel rawData = await _loginUseCase(payload);

      debugPrint('Login response: ${rawData.token}');

      final role = rawData.user?.role?.toLowerCase().trim();

      // 'clerk' was renamed to 'salesperson'. Because this is an allow-list rather than a
      // deny-list, the rename failed *closed*: a salesperson was not in the set, so the till
      // refused the exact role it exists for with "this account role cannot log in here".
      //
      // Both names stay. The four apps deploy separately and this one ships through an app store,
      // so a till running an older build has to keep working against a renamed backend — and a
      // till that cannot take a sale is the most expensive failure in the system.
      const allowedRoles = {'salesperson', 'clerk', 'manager', 'owner'};
      if (!allowedRoles.contains(role)) {
        _log.w('Login blocked — role "$role" is not allowed');
        emit(state.copyWith(
          stateStatus: const ErrorStatus(
            'Unauthorized: this account role cannot log in here.',
          ),
        ));
        return;
      }

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
      // Local writes only — the till reaches the dashboard without waiting on
      // the network. The product caches are warmed afterwards, off this path.
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
      // Deliberately not awaited: the clerk is already on the dashboard, which
      // renders from Hive and fetches on a miss. warmProductCaches swallows its
      // own failures, so nothing here can strand the login.
      unawaited(_saveUserInfoUseCase.warmProductCaches());
    } on LocalStorageException catch (e) {
      _log.e('Failed to save user info: ${e.message}');
      _failLogin(emit, e.message);
    } catch (e, st) {
      // Anything at all, not just LocalStorageException. The loader is held up
      // deliberately across LoginSuccess and is only taken down after the
      // navigation above, so an escaping error used to leave the till spinning
      // on a login that had in fact succeeded — the token was already written,
      // which is why a restart went straight in.
      _log.e('Unexpected failure completing login', error: e, stackTrace: st);
      _failLogin(emit, null);
    }
  }

  /// Emits the error status the login form listens for, which is also what
  /// takes the loader overlay down.
  void _failLogin(Emitter<AuthState> emit, String? message) {
    emit(
      state.copyWith(
        stateStatus: ErrorStatus(
          message ?? "Unable to login user at this time.",
        ),
      ),
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      _log.i('Clearing session storages on logout (pending sales preserved)...');
      // Stop the timer before the token goes, so no tick fires against a
      // session that is being torn down.
      _saveUserInfoUseCase.stopProductSync();
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
