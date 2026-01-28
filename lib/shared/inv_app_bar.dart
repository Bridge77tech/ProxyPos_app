import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';

import '../core/app_constants/ap_colors.dart';
import '../generated/assets.dart';
import '../features/home/presentation/bloc/main_layout_bloc.dart';
import '../features/home/presentation/bloc/main_layout_event.dart';
import '../features/home/presentation/bloc/main_layout_state.dart';


class InvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InvAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // We expect a MainLayoutBloc to be available above this widget.
    final bloc = BlocProvider.of<MainLayoutBloc>(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildLeading(context),
            Gap(80.w),
            Expanded(child: _buildSearchArea(context)),
            Gap(10.w),
            ApButton(
              btnText: 'Search',
              paddingHorizontal: 5,
              paddingVertical: 5,
              height: 30,
              width: 50,
              fontSize: 12,
              onPressed: () {},
            ),
            Gap(70.w),
          ],
        ),
        backgroundColor: InvAPColors.kWhiteColor,
        toolbarHeight: 97.h,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        actions: [_buildActions(context, bloc)],
      ),
    );
  }

  // Leading/logo widget
  Widget _buildLeading(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: InvAPColors.kPrimaryColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        'Logo',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: InvAPColors.kWhiteColor),
      ),
    );
  }

  // Search field with tight vertical padding so it lines up with the button
  Widget _buildSearchArea(BuildContext context) {
    return TextFormField(
      cursorColor: InvAPColors.kBorderColor,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: Image.asset(Assets.iconsSearchIcon, scale: 4.5),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: InvAPColors.kBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: InvAPColors.kBorderColor),
        ),
        hintText: 'Search product',
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: InvAPColors.kSecondaryTextColor),
      ),
    );
  }

  // Actions section: uses BlocBuilder to read and update selected tab
  Widget _buildActions(BuildContext context, MainLayoutBloc bloc) {
    return BlocBuilder<MainLayoutBloc, MainLayoutState>(
      builder: (context, state) {
        return Row(
          children: [
            _buildAppBarItem(context,
                icon: Assets.iconsDashbordIcon,
                label: 'Dashboard',
                isActive: state.selectedTab == MainLayoutTab.dashboard,
                onTap: () => bloc.add(const SelectTab(MainLayoutTab.dashboard))),
            Gap(18.w),
            _buildAppBarItem(context,
                icon: Assets.iconsHistoryIcon,
                label: 'History',
                isActive: state.selectedTab == MainLayoutTab.history,
                onTap: () => bloc.add(const SelectTab(MainLayoutTab.history))),
            Gap(18.w),
            _buildAppBarItem(context,
                icon: Assets.iconsMyAccountIcon,
                label: 'My Account',
                isActive: state.selectedTab == MainLayoutTab.myAccount,
                onTap: () => bloc.add(const SelectTab(MainLayoutTab.myAccount))),
            Gap(20.w),
            // Notification icon
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
            // Profile icon
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(50.r),
              child: SizedBox(
                height: 32.h,
                width: 32.h,
                child: ClipRRect(borderRadius: BorderRadius.circular(50.r), child: Image.asset(Assets.iconsProfileIcon)),
              ),
            ),
            Gap(8.w),
          ],
        );
      },
    );
  }

  // Single tab/action item
  Widget _buildAppBarItem(BuildContext context,
      {required String icon, required String label, required VoidCallback onTap, bool isActive = false}) {
    final color = isActive ? InvAPColors.kPrimaryColor : InvAPColors.kPrimaryTextColor;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          ImageIcon(AssetImage(icon), color: color),
          SizedBox(width: 6.w),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.h);
}
