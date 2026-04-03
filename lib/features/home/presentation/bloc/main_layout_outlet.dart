import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/main_layout.dart';
import 'package:inventory_app_pos/features/home/presentation/bloc/main_layout_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_bloc.dart';

Widget get mainLayOutlet {
  return MultiBlocProvider(
    providers: [
      BlocProvider<MainLayoutBloc>(create: (_) => MainLayoutBloc()),
      BlocProvider<DashboardBloc>(create: (_) => DashboardBloc()),
    ],
    child: const APMainLayoutPage(),
  );
}