// Actions section widget class
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../core/state/connectivity/connectivity_bloc.dart';
import '../../core/routing/inv_navigator_keys.dart';
import '../../core/routing/navigation_helper.dart';
import '../../core/routing/route_constants.dart';
import '../../features/auth/data/data_source/local/auth_session_storage_impl.dart';
import '../../features/auth/data/data_source/local/cashier_info_storage_impl.dart';
import '../../features/home/presentation/bloc/main_layout_bloc.dart';
import '../../features/home/presentation/bloc/main_layout_event.dart';
import '../../features/home/presentation/bloc/main_layout_state.dart';
import '../../features/home/presentation/presentation/dashboard/data/data_source/local/all_product_storage.dart';
import '../../features/home/presentation/presentation/dashboard/data/data_source/local/top_products_storage.dart';
import '../../generated/assets.dart';
import 'app_bar_item.dart';

enum _ProfileMenu { logout }

class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key, required this.mainBloc});
  final MainLayoutBloc mainBloc;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainLayoutBloc, MainLayoutState>(
      bloc: mainBloc,
      builder: (context, state) {
        return Row(
          children: [
            AppBarItem(
              icon: Assets.iconsDashbordIcon,
              label: 'Dashboard',
              isActive: state.selectedTab == MainLayoutTab.dashboard,
              onTap: () => mainBloc.add(const SelectTab(MainLayoutTab.dashboard)),
            ),
            Gap(18.w),
            AppBarItem(
              icon: Assets.iconsHistoryIcon,
              label: 'History',
              isActive: state.selectedTab == MainLayoutTab.history,
              onTap: () => mainBloc.add(const SelectTab(MainLayoutTab.history)),
            ),
            Gap(18.w),
            AppBarItem(
              icon: Assets.iconsMyAccountIcon,
              label: 'My Account',
              isActive: state.selectedTab == MainLayoutTab.myAccount,
              onTap: () => mainBloc.add(const SelectTab(MainLayoutTab.myAccount)),
            ),
            Gap(20.w),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(50.r),
              child: Container(
                height: 32.h,
                width: 32.h,
                decoration: BoxDecoration(shape: BoxShape.circle, color: InvAPColors.kAppBackgroundColor),
                child: Image.asset(Assets.iconsNotificationIcon, scale: 4.5),
              ),
            ),
            Gap(10.w),
            PopupMenuButton<_ProfileMenu>(
              offset: Offset(0, 40.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              color: InvAPColors.kWhiteColor,
              elevation: 6,
              onSelected: (value) async {
                if (value == _ProfileMenu.logout) {
                  final ctx = APNavigatorKeys.rootNavigatorKey.currentContext;
                  ctx?.loaderOverlay.show();
                  await Future.wait([
                    AuthSessionStorageImpl.instance.clearStorage(),
                    CashierInfoStorageImpl.instance.clearStorage(),
                    TopProductsStorageImpl.instance.clearTopProducts(),
                    AllProductsStorageImpl.instance.clearAllProducts(),
                  ]);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final navCtx =
                        APNavigatorKeys.rootNavigatorKey.currentContext;
                    navCtx?.loaderOverlay.hide();
                    NavigationHelper.popAllAndPushNamed(
                      InvRouteConstants.loginRoute.routeName,
                    );
                  });
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem<_ProfileMenu>(
                  value: _ProfileMenu.logout,
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 18.sp,
                        color: Colors.redAccent,
                      ),
                      Gap(8.w),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
                builder: (context, connectivity) {
                  final dotColor = connectivity.isOnline
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF9E9E9E);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        height: 32.h,
                        width: 32.h,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.r),
                          child: Image.asset(Assets.iconsProfileIcon),
                        ),
                      ),
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 10.r,
                          height: 10.r,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: InvAPColors.kWhiteColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Gap(8.w),
          ],
        );
      },
    );
  }
}