import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/core/routing/route_constants.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';
import 'package:inventory_app_pos/shared/input_fileds/ap_username_field.dart';
import 'package:inventory_app_pos/shared/input_fileds/app_password_field.dart';

import '../../../../core/app_constants/ap_colors.dart';
import '../../../../core/routing/navigation_helper.dart';
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10.w,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            InvAppConstants.kLogIntoYourAccount,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            InvAppConstants.kEnterAccountCredentials,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color: InvAPColors.kSecondaryTextColor,
                                ),
                          )
                        ],
                      ),
                      Image.asset(
                        Assets.iconsLoginSmallIcon,
                        scale: 4.0,
                      ),
                    ]),
                Gap(50.h),
                Form(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 100.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5.h,
                      children: [
                        Text(
                          InvAppConstants.kUsername,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const APUsernameField(),
                        Gap(10.h),
                        Text(
                          InvAppConstants.kPassword,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const APPasswordField(),
                        Gap(20.h),
                        ApButton(
                          btnText: InvAppConstants.kLogin,
                          width: 1.sw,
                          height: 40,
                          fontSize: 10.sp,
                          onPressed: () => NavigationHelper.goNamed(InvRouteConstants.apHomeRoute.routeName),
                        )
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Text(
                    InvAppConstants.kPoweredByFasaha,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
