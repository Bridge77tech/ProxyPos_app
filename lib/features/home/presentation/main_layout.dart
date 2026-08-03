import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/cashier_info_storage_impl.dart';
import 'package:inventory_app_pos/features/auth/domain/services/token_session_guard.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/all_product_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/top_products_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_event.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/dashboard/dashboard_outlet.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/presentation/bloc/history_outlet.dart';
import 'package:inventory_app_pos/shared/app_bar/inv_app_bar.dart';

import '../../../core/app_constants/ap_colors.dart';
import '../../../core/routing/navigation_helper.dart';
import '../../../core/routing/route_constants.dart';
import '../../../core/services/connectivity_service.dart';
import 'bloc/main_layout_bloc.dart';
import 'bloc/main_layout_state.dart';
import 'widgets/idle_screensaver.dart';

class APMainLayoutPage extends StatefulWidget {
  const APMainLayoutPage({super.key});

  @override
  State<APMainLayoutPage> createState() => _APMainLayoutPageState();
}

class _APMainLayoutPageState extends State<APMainLayoutPage> {
  final _guard = TokenSessionGuard();

  @override
  void initState() {
    super.initState();
    _guard.start(_onSessionExpired);
    _syncPendingIfOnline();
  }

  @override
  void dispose() {
    _guard.stop();
    super.dispose();
  }

  /// Called by [TokenSessionGuard] when the token is missing or expired.
  /// Clears session data — pending offline orders are intentionally kept
  /// so they can be synced after the user logs back in.
  Future<void> _onSessionExpired() async {
    _guard.stop();
    await Future.wait([
      AuthSessionStorageImpl.instance.clearStorage(),
      CashierInfoStorageImpl.instance.clearStorage(),
      TopProductsStorageImpl.instance.clearTopProducts(),
      AllProductsStorageImpl.instance.clearAllProducts(),
    ]);
    NavigationHelper.popAllAndPushNamed(InvRouteConstants.loginRoute.routeName);
  }

  /// If the device is online and there are queued offline orders, kick off
  /// an immediate sync.  This runs every time the home screen mounts,
  /// which includes the moment right after a fresh login.
  void _syncPendingIfOnline() {
    if (!ConnectivityService.instance.isOnline) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartBloc>().add(const CartSyncPending());
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wraps the whole authenticated shell, including the app bar, so an idle till
    // is covered completely. Never reaches the login screen, which sits outside.
    return IdleScreensaver(
      child: Scaffold(
        backgroundColor: InvAPColors.kAppBackgroundColor,
        appBar: const InvAppBar(),
        body: BlocBuilder<MainLayoutBloc, MainLayoutState>(
          builder: (context, state) {
            switch (state.selectedTab) {
              case MainLayoutTab.dashboard:
                return dashboardOutlet;
              case MainLayoutTab.history:
                return historyOutlet;
              case MainLayoutTab.myAccount:
                return const Center(child: Text('My Account'));
            }
          },
        ),
      ),
    );
  }
}
