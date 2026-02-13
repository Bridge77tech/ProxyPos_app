import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';
import 'package:inventory_app_pos/shared/app_bar/search_field_with_overlay.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../features/home/presentation/bloc/main_layout_bloc.dart';
import 'app_bar_actions.dart';
import 'leading_logo.dart';

class InvAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InvAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final mainBloc = BlocProvider.of<MainLayoutBloc>(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const LeadingLogo(),
            Gap(80.w),
            const Expanded(child: SearchFieldWithOverlay()),
            Gap(10.w),
            // ApButton(
            //   btnText: 'Search',
            //   paddingHorizontal: 5,
            //   paddingVertical: 5,
            //   height: 42,
            //   width: 50,
            //   fontSize: 10,
            //   onPressed: () {},
            // ),
            Gap(70.w),
          ],
        ),
        backgroundColor: InvAPColors.kWhiteColor,
        toolbarHeight: 97.h,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        actions: [AppBarActions(mainBloc: mainBloc)],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(70.h);
}
