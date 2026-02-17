import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_user_token_use_case.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_cashier_info_use_case.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/cashier_info_storage_impl.dart';
import 'package:inventory_app_pos/network/api_service.dart';

import '../../../home/presentation/presentation/dashboard/domain/usecases/all_product_use_case.dart';
import '../../../home/presentation/presentation/dashboard/domain/services/all_products_sync_service.dart';
import '../../data/data_source/remote/login_api_service.dart';
import '../../data/repo/auth_repo_impl.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/save_user_use_case.dart';
import '../views/login_page.dart';
import 'auth_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/repos/product_repo_impl.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/usecases/top_products_use_case.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/top_products_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/repo/top_product_repo.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/all_product_storage.dart';

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

  // Build GetAndCacheTopProductsUseCase (token reader -> repo -> cache)
  final productRepo = ProductRepoImpl.instance as ProductRepository<ProductModel>;
  final topCache = _TopProductsCacheAdapter();
  final tokenReader = _AuthSessionReaderAdapter(authSessionStorage);
  final getAndCacheTopProducts = GetAndCacheTopProductsUseCase(
    tokenReader,
    productRepo,
    topCache,
  );

  final allProductsCache = _AllProductsCacheAdapter();
  final getAllProduct = GetAndCacheAllProductsUseCase(
    tokenReader,
    productRepo,
    allProductsCache,
  );

  // Create a sync service that refreshes all products every 30 minutes
  final allProductsSync = AllProductsSyncService(getAllProduct, interval: const Duration(minutes: 30));
  if (!allProductsSync.isRunning) {
    allProductsSync.start(runImmediately: true);
  }

  final SaveUserInfoUseCase saveUserInfo = SaveUserInfoUseCase(
    saveUserToken,
    saveCashierInfo,
    getAndCacheTopProducts,
    getAllProduct,
  );

  return BlocProvider<AuthBloc>(
    create: (context) => AuthBloc(loginUseCase, saveUserInfo),
    child: const APLoginPage(),
  );
}

class _AuthSessionReaderAdapter implements AuthSessionReader {
  final AuthSessionStorageImpl storage;
  _AuthSessionReaderAdapter(this.storage);

  @override
  Future<String?> getToken() async {
    final token = await storage.getStorageData();
    return token is String ? token : null;
  }
}

class _TopProductsCacheAdapter implements TopProductsCache {
  final _storage = TopProductsStorageImpl.instance;
  @override
  Future<void> saveTopProducts(ProductModel products) async {
    await _storage.saveTopProducts(products);
  }
}

class _AllProductsCacheAdapter implements AllProductsCache {
  final _storage = AllProductsStorageImpl.instance;
  @override
  Future<void> saveAllProducts(ProductModel products) async {
    await _storage.saveAllProducts(products);
  }
}


