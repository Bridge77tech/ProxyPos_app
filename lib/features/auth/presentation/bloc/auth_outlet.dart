import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/local_storage_service_impl.dart';
import '../../../../network/api_service.dart';
import '../views/login_page.dart';
import 'auth_bloc.dart';

BlocProvider get authOutlet {
  // Build auth repo using the shared Dio + prefix
  final dio = APIService().dioInstance;
  // final getTopProductsUseCase = GetTopProductUseCase();
  final storage = LocalStorageServiceImpl.instance;

  return BlocProvider<AuthBloc>(
    create: (context) => AuthBloc(storage),
    child: const APLoginPage(),
  );
}
