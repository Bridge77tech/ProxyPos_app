import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/features/auth/presentation/widgets/login_form.dart';
import 'package:inventory_app_pos/generated/assets.dart';

class LeftDisplayWidget extends StatelessWidget {
  const LeftDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: InvAPColors.kSecondaryTextColor,
                    ),
                  ),
                ],
              ),
              Image.asset(Assets.iconsLoginSmallIcon, scale: 4.0),
            ],
          ),
          Gap(50.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100.0),
            child: LoginForm(),
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
    );
  }
}
