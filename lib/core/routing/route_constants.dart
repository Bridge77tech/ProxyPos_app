import 'package:inventory_app_pos/core/routing/inv_router_model.dart';

class InvRouteConstants {
  static const loginRoute = InvRouterModel(
    routeName: 'loginRoute',
    routePath: '/login',
  );
  static const apHomeRoute = InvRouterModel(
      routeName: 'apHomeRoute',
      routePath: '/home',
  );
}