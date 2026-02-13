// Leading/logo widget class
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_constants/ap_colors.dart';

class LeadingLogo extends StatelessWidget {
  const LeadingLogo({super.key});
  @override
  Widget build(BuildContext context) {
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
}