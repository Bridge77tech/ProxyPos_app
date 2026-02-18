import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/network/api_service.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/cart_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/usecases/create_sale_use_case.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/repos/create_sale_repo_impl.dart';

/// Provides a BlocProvider for CartBloc with all dependencies wired.
BlocProvider<CartBloc> get cartOutlet {
  // Build repository and use case for creating sales
  final dio = APIService().dioInstance;
  final repo = CreateSaleRepoImpl.withDio(dio);

  // Auth reader adapter that fetches token from local storage
  final authReader = _CartAuthReaderAdapter(AuthSessionStorageImpl.instance);
  final useCase = CreateSaleUseCase(authReader, repo);

  return BlocProvider<CartBloc>(
    create: (_) => CartBloc(createSaleUseCase: useCase),
  );
}

class _CartAuthReaderAdapter implements CreateSaleAuthReader {
  final AuthSessionStorageImpl storage;
  _CartAuthReaderAdapter(this.storage);
  @override
  Future<String?> getToken() async {
    final data = await storage.getStorageData();
    return data is String ? data : null;
  }
}

