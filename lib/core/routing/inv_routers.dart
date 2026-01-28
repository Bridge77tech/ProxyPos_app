part of 'inv_routes.dart';

class InvRouters {
  static GoRouter get apRouter => _apRouterConfig;

  static final _apRouterConfig = GoRouter(
    routes: InvRoutes.routes,
    navigatorKey: APNavigatorKeys.rootNavigatorKey,
    redirectLimit: 1000,
    initialLocation: InvRoutes.apLogin.path,
    debugLogDiagnostics: true,
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Text("${InvAppConstants.kPageNotFound}: ${state.path}"),
        ),
      ),
    ),
  );
}