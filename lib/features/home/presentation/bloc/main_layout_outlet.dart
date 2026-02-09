import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/bloc/main_layout_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/main_layout.dart';

Widget get mainLayOutlet {
  return BlocProvider<MainLayoutBloc>(
    create: (_) => MainLayoutBloc(),
    child: APMainLayoutPage(),
  );
}