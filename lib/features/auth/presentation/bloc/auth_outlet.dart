import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/local_storage_service_impl.dart';
import '../../../../network/api_service.dart';
import '../../../../network/constants/api_string_const.dart';
import '../../../home/data/remote/home_api_service.dart';
import '../../../home/data/repositories/home_repo_impl.dart';
import '../../../home/domain/usecases/get_top_product_use_case.dart';
import '../../data/remote/auth_api_service.dart';
import '../../data/repositories/auth_repo_impl.dart';
import '../../data/session/user_profile_storage_hive.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/save_user_info_use_case.dart';
import '../views/login_page.dart';
import 'auth_bloc.dart';

BlocProvider get authOutlet {
  // Build auth repo using the shared Dio + prefix
  final dio = APIService().dioInstance;
  final authService = AuthAPIService(dio, baseUrl: APIStringConst.apAPIPrefix);
  final authRepo = AuthRepoImpl(authService);
  final loginUseCase = LoginUseCase<Map<String, dynamic>>(authRepo);
  final saveUserInfoUseCase = SaveUserInfoUseCase(
    UserProfileStorageHive.instance,
  );

  // Prepare Home use case for prefetching top products after login
  final homeApi = HomeAPIService(dio, baseUrl: APIStringConst.apAPIPrefix);
  final homeRepo = HomeRepoImpl<Map<String, dynamic>>(homeApi, (json) => json);
  final getTopProductsUseCase = GetTopProductUseCase(homeRepo);
  final storage = LocalStorageServiceImpl.instance;

  return BlocProvider<AuthBloc<Map<String, dynamic>>>(
    create: (context) => AuthBloc<Map<String, dynamic>>(
      loginUseCase,
      saveUserInfoUseCase,
      getTopProductsUseCase,
      storage,
    ),
    child: const APLoginPage(),
  );
}
