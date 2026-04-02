import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';

class Utils {
  Utils._();
  /// Shows an overlay dialog with the provided child widget.
  /// Returns a Future that completes when the dialog is dismissed.
  static Future<T?> showOverlayDialog<T>(
      BuildContext context, {
        required Widget child,
        bool useRootNavigator = true,
        VoidCallback? onPressed,
        String title = 'Add to Cart',
        double height = 0.8,
        double roundCorner = 0,
        String btnText = 'Add to Cart',
        Widget? bottomWidget,
      }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: useRootNavigator,
      builder: (ctx) {
        return SizedBox(
          width: 0.3.sw,
          height: height.sh,
          child: AlertDialog(
            contentPadding: EdgeInsets.symmetric(vertical: 0.sh, horizontal: 0.sw),
            backgroundColor: InvAPColors.kAppBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(roundCorner.r)),
            title: Container(
              width: 0.3.sw,
              padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: InvAPColors.kBlackColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(roundCorner.r),
                  topRight: Radius.circular(roundCorner.r),
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: InvAPColors.kWhiteColor,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    splashColor: Colors.transparent,
                    child: Container(
                      height: 25.h,
                      width: 25.w,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: InvAPColors.kWhiteColor,
                            width: 1.w,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: InvAPColors.kWhiteColor,
                        size: 10.sp,
                      ),
                    ),
                  )
                ],
              ),
            ),
            titlePadding: EdgeInsets.symmetric(vertical: 0.sh, horizontal: 0.sw),
            // Constrain content and allow scrolling to avoid overflow
            content: SizedBox(
              width: 0.3.sw,
              height: height.sh,
              child: Column(
                children: [
                  Expanded(child: SingleChildScrollView(child: child)),
                  bottomWidget ?? ApButton(
                    btnText: btnText,
                    width: 0.3.sw,
                    cornerRadius: roundCorner,
                    onPressed: onPressed,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}