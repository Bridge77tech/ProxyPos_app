import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/right_side_dashboard.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:toastification/toastification.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../bloc/cart/cart_state.dart';
import '../widgets/cart_item_middle_area.dart';
import '../widgets/left_side_dashboard_view_card.dart';
import '../widgets/queue/cart_queue_indicators.dart';

class APDashboardPage extends StatelessWidget {
  const APDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        // Show success notification at top right
        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: const Text('Success'),
            description: Text(state.successMessage!),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 4),
            showProgressBar: true,
            primaryColor: InvAPColors.kPrimaryColor,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            icon: const Icon(
              Icons.check_circle,
              color: InvAPColors.kPrimaryColor,
            ),
            borderSide: const BorderSide(
              color: InvAPColors.kPrimaryColor,
              width: 2,
            ),
            boxShadow: lowModeShadow,
            showIcon: true,
            dragToClose: true,
          );
        }

        // Show error notification at top right
        if (state.error != null && state.error!.isNotEmpty) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            title: const Text('Error'),
            description: Text(state.error!),
            alignment: Alignment.topRight,
            autoCloseDuration: const Duration(seconds: 5),
            showProgressBar: true,
            primaryColor: Colors.red,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.error, color: Colors.red),
            borderSide: const BorderSide(color: Colors.red, width: 2),
            boxShadow: lowModeShadow,
            showIcon: true,
            dragToClose: true,
          );
        }
      },
      child: Padding(
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
                        // Connection state, and the queue badge immediately beside it. Placed in
                        // the Cart header because that is where a cashier is looking when a sale
                        // fails to go through.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              InvAppConstants.kCart,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Gap(10.w),
                            const CartQueueIndicators(),
                          ],
                        ),
                        InkWell(
                          onTap: () =>
                              context.read<CartBloc>().add(const CartClear()),
                          child: Image.asset(
                            Assets.iconsDeleteIcon,
                            scale: 4.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(10.h),
                  // Middle area: cart items
                  CartItemsMiddleArea(),

                  Gap(10.h),

                  // Bottom area: totals
                  RightSideDashboard(),

                  Gap(10.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
