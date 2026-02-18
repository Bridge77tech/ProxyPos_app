import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/core/utils/utils.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loader_overlay/loader_overlay.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import '../bloc/cart_event.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../widgets/cart_item_middle_area.dart';
import '../widgets/cash_out_overflow_content.dart';
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
          Expanded(flex: 7, child: LeftSideDashboardViewCard()),

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
                        onTap: () =>
                            context.read<CartBloc>().add(const CartClear()),
                        child: Image.asset(Assets.iconsDeleteIcon, scale: 4.5),
                      ),
                    ],
                  ),
                ),
                Gap(10.h),
                // Middle area: cart items
                CartItemsMiddleArea(),

                Gap(10.h),

                // Bottom area: totals
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
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, cartState) {
                        final ghc = InvAppConstants.kGHC;
                        // Show overlay while submitting
                        if (cartState.submitting) {
                          context.loaderOverlay.show();
                        } else {
                          context.loaderOverlay.hide();
                        }
                        return SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            spacing: Platform.isWindows ? 4.5.h : 10.h,
                            children: [
                              _rowText(
                                context,
                                label: InvAppConstants.kVAT,
                                value:
                                    '$ghc ${cartState.vat.toStringAsFixed(2)}',
                              ),
                              _rowText(
                                context,
                                label: InvAppConstants.kDiscount,
                                value:
                                    '$ghc ${cartState.discount.toStringAsFixed(2)}',
                              ),
                              _rowText(
                                context,
                                label: InvAppConstants.kSubTotal,
                                value:
                                    '$ghc ${cartState.subTotal.toStringAsFixed(2)}',
                              ),
                              _rowText(
                                context,
                                label: InvAppConstants.kTotal,
                                value:
                                    '$ghc ${cartState.total.toStringAsFixed(2)}',
                                fontWeight: FontWeight.w700,
                              ),
                              ApButton(
                                onPressed: cartState.items.isEmpty
                                    ? null
                                    : () {
                                        Utils.showOverlayDialog(
                                          context,
                                          title: 'Checkout',
                                          roundCorner: 10,
                                          height: 0.6,
                                          btnText: "Submit",
                                          child: CheckOutOverFlowContent(),
                                          onPressed: () {
                                            // Trigger submit
                                            context.read<CartBloc>().add(const CartSubmitOrder());
                                            // Close the overlay dialog
                                            Navigator.of(context).pop();
                                          },
                                        );
                                      },
                                btnText: 'Submit Order',
                                fontSize: 12,
                                height: 40,
                                width: 1.sw,
                              ),
                            ],
                          ),
                        );
                      },
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
