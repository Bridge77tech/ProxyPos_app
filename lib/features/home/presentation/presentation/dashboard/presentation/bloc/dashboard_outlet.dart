import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/data/local_storage_service_impl.dart';

import '../views/dashboard.dart';
import 'dashboard_bloc.dart';
import 'dashboard_event.dart';

BlocProvider get dashboardOutlet {
  return BlocProvider<DashboardBloc>(
    create: (_) {
      final bloc = DashboardBloc(LocalStorageServiceImpl.instance);
      bloc.add(const LoadTopProducts());
      return bloc;
    },
    child: const APDashboardPage(),
  );
}
