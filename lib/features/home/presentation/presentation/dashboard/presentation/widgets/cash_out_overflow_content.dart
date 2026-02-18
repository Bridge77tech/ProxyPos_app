import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/payment_method_widget.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../../../../../../../generated/assets.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CheckOutOverFlowContent extends StatelessWidget {
  const CheckOutOverFlowContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap(10.h),
                  Center(
                    child: Text(
                      'Customer To Pay',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: InvAPColors.kBlack100,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "GHC ${cartState.total.toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: InvAPColors.kPrimaryColor,
                      ),
                    ),
                  ),
                  Gap(16.h),
                  // Payment method buttons
                  Row(
                    children: [
                      Expanded(
                        child: PaymentMethodTile(
                          label: 'Mobile Money',
                          iconAsset: Assets.iconsMoneyIcon,
                          selected: cartState.paymentMethod == PaymentMethod.mobileMoney,
                          onTap: () => context.read<CartBloc>().add(const CartSelectPayment(PaymentMethod.mobileMoney)),
                        ),
                      ),
                      Gap(10.w),
                      Expanded(
                        child: PaymentMethodTile(
                          label: 'Cash',
                          iconAsset: Assets.iconsMoneyIcon,
                          selected: cartState.paymentMethod == PaymentMethod.cash,
                          onTap: () => context.read<CartBloc>().add(const CartSelectPayment(PaymentMethod.cash)),
                        ),
                      ),
                    ],
                  ),
                  Gap(16.h),
                  Center(child: Text('Amount Received', style: Theme.of(context).textTheme.bodyMedium)),
                  Gap(8.h),
                  Row(
                    spacing: 10.w,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.r),
                          color: InvAPColors.kPrimaryColor,
                        ),
                        child: const Text("GHC", style: TextStyle(color: Colors.white)),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: cartState.amountReceived.toStringAsFixed(2),
                          onChanged: (val) {
                            final v = double.tryParse(val) ?? 0.0;
                            context.read<CartBloc>().add(CartSetAmountReceived(v));
                          },
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(12.h),
                  // Remaining and Change
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: InvAPColors.kLightRedColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining:'),
                        Text("GHC ${cartState.remaining.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                  Gap(8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: InvAPColors.kLightGreenColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Change:'),
                        Text("GHC ${cartState.change.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                  // Quick amount chips (optional)
                  Gap(16.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: [
                      for (final amt in const [5, 10, 20, 50, 100, 200])
                        InkWell(
                          onTap: () => context.read<CartBloc>().add(CartSetAmountReceived(amt.toDouble())),
                          child: Container(
                            height: 40.h,
                            width: 80.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: InvAPColors.kPrimaryColor, width: 0.7.w),
                            ),
                            child: Text('GHC ${amt.toStringAsFixed(2)}'),
                          ),
                        ),
                    ],
                  ),
                ],
              ));
        },
      ),
    );
  }
}