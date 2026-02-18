import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
    this.height,
  });

  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        // Remove fixed height to avoid exceeding Row/overlay constraints
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          border: Border.all(color: InvAPColors.kPrimaryColor, width: 1.5.w),
          color: InvAPColors.kWhiteColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: selected ? Colors.red.withAlpha(25) : InvAPColors.kWhiteColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Image.asset(iconAsset, scale: 4.5),
            ),
            Gap(6.h),
            Text(label),
          ],
        ),
      ),
    );
  }
}
