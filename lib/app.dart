import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/core/app_theme/inv_theme.dart';
import 'package:inventory_app_pos/core/state/connectivity/connectivity_bloc.dart';
import 'package:inventory_app_pos/shared/ap_loader_overlay.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:toastification/toastification.dart';

import 'core/app_constants/ap_colors.dart';
import 'core/routing/inv_routes.dart';

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

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
            ],
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: "Inventory App",
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
