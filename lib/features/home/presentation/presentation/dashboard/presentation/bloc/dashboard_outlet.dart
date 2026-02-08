import 'package:flutter_bloc/flutter_bloc.dart';

import '../views/dashboard.dart';
import 'dashboard_bloc.dart';
import 'dashboard_event.dart';

BlocProvider get dashboardOutlet {
  return BlocProvider<DashboardBloc>(
    create: (_) {
      final bloc = DashboardBloc();
      bloc.add(const LoadTopProducts());
      return bloc;
    },
    child: const APDashboardPage(),
  );
}
