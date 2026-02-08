import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/bloc/dashboard_bloc.dart';
import '../presentation/bloc/dashboard_event.dart';

/// Provides DashboardBloc and triggers initial LoadTopProducts when created.
class DashboardProvider extends StatelessWidget {
  const DashboardProvider({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardBloc>(
      create: (_) => DashboardBloc()..add(const LoadTopProducts()),
      child: child,
    );
  }
}
