import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/core/app_theme/inv_theme.dart';
import 'package:inventory_app_pos/core/state/connectivity/connectivity_bloc.dart';
import 'package:inventory_app_pos/shared/ap_loader_overlay.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:toastification/toastification.dart';

import 'core/app_constants/ap_colors.dart';
import 'core/routing/inv_navigator_keys.dart';
import 'core/routing/inv_routes.dart';
import 'core/update/update_coordinator.dart';
import 'features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_outlet.dart';



class InventoryApp extends StatefulWidget {
  const InventoryApp({super.key});

  @override
  State<InventoryApp> createState() => _InventoryAppState();
}

class _InventoryAppState extends State<InventoryApp> {
  @override
  void initState() {
    super.initState();

    // The only place the updater is ever triggered.
    //
    // Once per process, and never again — scheduleAtLaunch cancels itself the moment
    // the check starts, so the prompt still cannot appear in the middle of a sale.
    //
    // This used to read rootNavigatorKey.currentContext inside a single post-frame
    // callback and return if it was null. It was null every time: the route guard
    // redirects through an async token read, so go_router has nothing to build on the
    // first frame and the Navigator does not exist yet. The check never ran on any
    // till, and said nothing about it. scheduleAtLaunch waits for the Navigator
    // instead, and writes to UpdateLog either way.
    //
    // Nothing here is awaited and nothing here can be: the app must finish starting
    // whether the check succeeds, fails, or hangs to its timeout. A till with no
    // connection reaches the login screen exactly as fast as it did before any of
    // this existed.
    UpdateCoordinator.scheduleAtLaunch(APNavigatorKeys.rootNavigatorKey);
  }

  @override
  Widget build(BuildContext context) {

    return GlobalLoaderOverlay(
      overlayColor: InvAPColors.kBlackColor.withValues(alpha: 0.7),
      overlayWidgetBuilder: (value) => const FittedBox(
      child: APOverlayLoader(),
      ),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: ScreenUtilInit(
          designSize: Size(1025, 768),
          useInheritedMediaQuery: true,
          minTextAdapt: true,
          ensureScreenSize: true,
          builder: (context, _) => ToastificationWrapper(
            config: ToastificationConfig(
              itemWidth: MediaQuery.of(context).size.width,
              marginBuilder: (context, _) => EdgeInsets.symmetric(horizontal: 16.w),
            ),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ConnectivityBloc>(
                  create: (_) => ConnectivityBloc(),
              ),
              cartOutlet,
            ],
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: "ProxyPOS",
              theme: themeData(),
              routerConfig: InvRouters.apRouter,
            ),
          ),
        ),
      ),
    ),
    );
  }
}
