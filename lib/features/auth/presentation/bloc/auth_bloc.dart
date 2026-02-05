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
import 'package:inventory_app_pos/features/home/data/model/product_model.dart';
import 'package:inventory_app_pos/features/home/domain/usecases/get_top_product_use_case.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ILocalStorageService _storage;
  final _log = getLogger('AuthBloc');

  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  AuthBloc(
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
    final payload = {
      'username': state.username,
      'password': state.password,
    };

    emit(state.copyWith(stateStatus: const LoggingInUser()));

    try {

    } on AuthException catch (e, st) {
      _log.e('Login failed: ${e.message}');
      _log.e(st.toString());
      emit(
        state.copyWith(
          stateStatus: ErrorStatus(e.message),
          errorMessage: e.message,
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
      // Prefetch top products and cache to Hive to speed up initial dashboard
      try {
        await _storage.init();

        await _storage.openBox<List>(StorageBox.topProducts);
        final box = _storage.getBox<List>(StorageBox.topProducts.name);
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
