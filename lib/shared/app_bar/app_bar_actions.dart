
// Actions section widget class
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../features/home/presentation/bloc/main_layout_bloc.dart';
import '../../features/home/presentation/bloc/main_layout_event.dart';
import '../../features/home/presentation/bloc/main_layout_state.dart';
import '../../generated/assets.dart';
import 'app_bar_item.dart';

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
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(50.r),
              child: SizedBox(
                height: 32.h,
                width: 32.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50.r),
                  child: Image.asset(Assets.iconsProfileIcon),
                ),
              ),
            ),
            Gap(8.w),
          ],
        );
      },
    );
  }
}