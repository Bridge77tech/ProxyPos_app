import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/left_side_dashboard_view_card.dart';

class APDashboardPage extends StatelessWidget {
  const APDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Left column - flexible (approx 70%)
          Expanded(
            flex: 7,
            child: LeftSideDashboardViewCard(),
          ),

          Gap(10.w),

          // Right column - flexible (approx 30%) using flex-based vertical sizing
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Top small card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.r),
                    color: InvAPColors.kWhiteColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        InvAppConstants.kCart,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      InkWell(
                        onTap: () {},
                        child: Image.asset(
                          Assets.iconsDeleteIcon,
                          scale: 4.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Gap(10.h),

                // Middle area: takes majority of remaining vertical space
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: InvAPColors.kWhiteColor,
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      interactive: true,
                      child: ListView.builder(
                        // Remove standalone controller; use PrimaryScrollController via primary: true
                        primary: true,
                        itemCount: 10,
                        itemBuilder: (context, item) => CartItemCard(),
                      ),
                    ),
                  ),
                ),

                Gap(10.h),

                // Bottom area: smaller area that shares remaining space
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 1.sw,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: InvAPColors.kWhiteColor,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10.h,
                        children: [
                          _rowText(
                            context,
                            label: InvAppConstants.kVAT,
                            value: '${InvAppConstants.kGHC} 100.00',
                          ),
                          _rowText(
                            context,
                            label: InvAppConstants.kDiscount,
                            value: '${InvAppConstants.kGHC} 0.00',
                          ),
                          _rowText(
                            context,
                            label: InvAppConstants.kSubTotal,
                            value: '${InvAppConstants.kGHC} 100.00',
                          ),
                          _rowText(
                            context,
                            label: InvAppConstants.kTotal,
                            value: '${InvAppConstants.kGHC} 100.00',
                            fontWeight: FontWeight.w700,
                          ),
                          ApButton(
                            onPressed: () {},
                            btnText: 'Submit Order',
                            fontSize: 12,
                            height: 40,
                            width: 1.sw,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Gap(10.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowText(
    BuildContext context, {
    required String label,
    required String value,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(fontWeight: fontWeight),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(fontWeight: fontWeight),
        ),
      ],
    );
  }
}

