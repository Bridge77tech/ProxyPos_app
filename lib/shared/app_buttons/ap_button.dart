import 'package:flutter/material.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApButton extends StatelessWidget {
  const ApButton({
    required this.btnText,
    this.apPrefixIcon,
    this.apSuffixIcon,
    this.apPrefixIconColor = Colors.grey,
    this.apSuffixIconColor = Colors.grey,
    this.apColor = InvAPColors.kPrimaryColor,
    this.apTextColor = InvAPColors.kWhiteColor,
    this.onPressed,
    this.width = _minBtnWidth,
    this.height = _minBtnHeight,
    this.paddingHorizontal = 20.0,
    this.paddingVertical = 10.0,
    this.disabledBgColor = InvAPColors.kDisableBtnColor,
    this.fontSize = 18.0,
    this.btnPrefixIconSize = 20,
    this.fontWeight = FontWeight.w500,
    this.cornerRadius = 7.0,
    super.key,
  });

  final String btnText;
  final String? apPrefixIcon;
  final String? apSuffixIcon;
  final Color apPrefixIconColor;
  final Color apSuffixIconColor;
  final Color apColor;
  final Color apTextColor;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double paddingHorizontal;
  final double paddingVertical;
  final Color disabledBgColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double? btnPrefixIconSize;
  final double cornerRadius;

  static const double _minBtnHeight = 50.0;
  static const double _minBtnWidth = 157.0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onPressed!();
            },
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: disabledBgColor,
        // Use fixedSize so the button exactly matches the requested size (after scaling)
        fixedSize: Size(width.w, height.h),
        minimumSize: Size(width.w, height.h),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.center,
        // Keep horizontal padding but avoid vertical padding increasing height
        padding: EdgeInsets.symmetric(
          horizontal: paddingHorizontal.w,
          vertical: 0,
        ),
        elevation: 0,
        splashFactory: NoSplash.splashFactory,
        backgroundColor: apColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius.r),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (apPrefixIcon != null && apPrefixIcon!.isNotEmpty) ...[
              ImageIcon(
                AssetImage(apPrefixIcon!),
                size: btnPrefixIconSize?.sp,
                color: apPrefixIconColor,
              ),
              SizedBox(width: 10.w),
            ],
            Text(
              btnText,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: apTextColor,
                    fontSize: fontSize.sp,
                    fontWeight: fontWeight,
                  ),
            ),
            if (apSuffixIcon != null && apSuffixIcon!.isNotEmpty) ...[
              SizedBox(width: 10.w),
              ImageIcon(
                AssetImage(apSuffixIcon!),
                size: btnPrefixIconSize?.sp,
                color: apSuffixIconColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
