part of 'inv_routes.dart';

class InvRouters {
  static GoRouter get apRouter => _apRouterConfig;

  static final _apRouterConfig = GoRouter(
    routes: InvRoutes.routes,
    navigatorKey: APNavigatorKeys.rootNavigatorKey,
    redirectLimit: 1000,
    initialLocation: InvRoutes.apLogin.path,
    debugLogDiagnostics: true,
    redirect: _guard,
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text("${InvAppConstants.kPageNotFound}: ${state.path}"),
        ),
      ),
    ),
  );

  /// Route guard: checks stored token validity on every navigation.
  ///
  /// - Valid token + going to login  → send to home (already authenticated)
  /// - Invalid / missing token + not on login → send to login
  /// - Otherwise → no redirect (let the navigation proceed)
  static Future<String?> _guard(BuildContext context, GoRouterState state) async {
    final isAuthenticated = await TokenValidator.hasValidToken();
    final onLogin = state.matchedLocation == InvRouteConstants.loginRoute.routePath;

    if (isAuthenticated && onLogin) {
      return InvRouteConstants.apHomeRoute.routePath;
    }
    if (!isAuthenticated && !onLogin) {
      return InvRouteConstants.loginRoute.routePath;
    }
    return null;
  }
}