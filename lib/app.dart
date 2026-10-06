import 'dart:async';

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
    // Once, after the first frame, and never again for the life of the process.
    // There is no timer and no listener behind this call, which is what guarantees
    // the prompt cannot appear in the middle of a sale.
    //
    // Not awaited, and it cannot be: the app must finish starting whether the check
    // succeeds, fails, or hangs until it times out. A till with no connection — the
    // ordinary case in the shops this is sold into — reaches the login screen at
    // exactly the speed it did before this existed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = APNavigatorKeys.rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      unawaited(UpdateCoordinator.maybePrompt(context));
    });
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
              title: "ProxyPos",
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
