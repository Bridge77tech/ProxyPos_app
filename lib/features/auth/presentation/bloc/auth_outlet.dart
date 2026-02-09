import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_user_token_use_case.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_cashier_info_use_case.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/cashier_info_storage_impl.dart';
import 'package:inventory_app_pos/network/api_service.dart';

import '../../data/data_source/remote/login_api_service.dart';
import '../../data/repo/auth_repo_impl.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/save_user_use_case.dart';
import '../views/login_page.dart';
import 'auth_bloc.dart';

BlocProvider get authOutlet {
  final LoginAPIService apiService = LoginAPIService(
    APIService().dioInstance,
  );
  final loginRepo = LoginRepositoryImpl(
      apiService
  );
  final authSessionStorage = AuthSessionStorageImpl.instance;
  final saveUserToken = SaveUserTokenUseCase(authSessionStorage);
  final cashierInfoStorage = CashierInfoStorageImpl.instance;
  final saveCashierInfo = SaveCashierInfoUseCase(cashierInfoStorage);
  final loginUseCase = LoginUseCase(loginRepo);
  final SaveUserInfoUseCase saveUserInfo = SaveUserInfoUseCase(
      saveUserToken,
    saveCashierInfo,
  );

  return BlocProvider<AuthBloc>(
    create: (context) => AuthBloc(loginUseCase, saveUserInfo),
    child: const APLoginPage(),
  );
}
