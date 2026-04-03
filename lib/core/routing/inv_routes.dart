import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/core/routing/route_constants.dart';
import 'package:inventory_app_pos/features/auth/presentation/bloc/auth_outlet.dart';

import '../../features/home/presentation/bloc/main_layout_outlet.dart';
import 'inv_navigator_keys.dart';

part 'inv_routers.dart';

class InvRoutes {
  InvRoutes._();

  static final _apRoutes = [
    apLogin,
    apHome,
  ];

  static List<GoRoute> get routes => _apRoutes;

  static final GoRoute apLogin = GoRoute(
    path: InvRouteConstants.loginRoute.routePath,
    name: InvRouteConstants.loginRoute.routeName,
    builder: (context, state) => authOutlet,
  );

  static final GoRoute apHome = GoRoute(
    path: InvRouteConstants.apHomeRoute.routePath,
    name: InvRouteConstants.apHomeRoute.routeName,
    builder: (context, state) => mainLayOutlet,
  );
}