import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/features/auth/presentation/widgets/left_display_widget.dart';

import '../../../../core/app_constants/ap_colors.dart';
import '../../../../generated/assets.dart';

class APLoginPage extends StatelessWidget {
  const APLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvAPColors.kAppBackgroundColor,
      body: Row(
        children: [
          Container(
            width: 0.45.sw,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesLoginLeftImage2),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Gap(100.h),
                Text(
                  InvAppConstants.kOptimizeYourInventory,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontFamily: "Fontspring-DEMO-integralcf",
                    color: const Color(0xFF555654),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          LeftDisplayWidget(),
        ],
      ),
    );
  }
}

