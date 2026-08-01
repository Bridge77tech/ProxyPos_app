import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/payment_method_widget.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../../../../../../../generated/assets.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../bloc/cart/cart_state.dart';

class CheckOutOverFlowContent extends StatelessWidget {
  const CheckOutOverFlowContent({super.key});

  @override
  Widget build(BuildContext context) {
    final cartBloc = context.read<CartBloc>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Gap(10.h),

            // Total — rebuilds only when total changes
            BlocBuilder<CartBloc, CartState>(
              buildWhen: (prev, curr) => prev.total != curr.total,
              builder: (context, state) => Column(
                children: [
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
                      "GHC ${state.total.toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: InvAPColors.kPrimaryColor,
                        fontSize: 23,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Gap(16.h),

            // Payment method — rebuilds only when paymentMethod changes
            BlocBuilder<CartBloc, CartState>(
              buildWhen: (prev, curr) =>
                  prev.paymentMethod != curr.paymentMethod,
              builder: (context, state) => Row(
                children: [
                  Expanded(
                    child: PaymentMethodTile(
                      label: 'Mobile Money',
                      iconAsset: Assets.iconsMoneyIcon,
                      selected:
                          state.paymentMethod == PaymentMethod.mobileMoney,
                      onTap: () => context.read<CartBloc>().add(
                        const CartSelectPayment(PaymentMethod.mobileMoney),
                      ),
                    ),
                  ),
                  Gap(10.w),
                  Expanded(
                    child: PaymentMethodTile(
                      label: 'Cash',
                      iconAsset: Assets.iconsMoneyIcon,
                      selected: state.paymentMethod == PaymentMethod.cash,
                      onTap: () => context.read<CartBloc>().add(
                        const CartSelectPayment(PaymentMethod.cash),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Gap(16.h),
            Center(
              child: Text(
                'Amount Received',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Gap(8.h),

            // The field itself is never rebuilt from state — the controller stays the
            // source of truth for its text. Only the border colour and the message
            // below react, so typing is never interrupted.
            BlocBuilder<CartBloc, CartState>(
              buildWhen: (prev, curr) =>
                  prev.amountReceived != curr.amountReceived ||
                  prev.total != curr.total ||
                  prev.paymentMethod != curr.paymentMethod,
              builder: (context, state) {
                // Shown for any selected payment method — a short payment is a short
                // payment whether it arrives as cash or mobile money, and the server
                // now rejects both. Only once something has been entered, though: an
                // untouched field isn't an error.
                final isShort =
                    state.paymentMethod != null &&
                    state.amountReceived > 0 &&
                    state.isShortPayment;

                final border = OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isShort ? InvAPColors.kErrorRedColor : Colors.grey,
                    width: isShort ? 1.4 : 1.0,
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 10.w,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.r),
                            color: InvAPColors.kPrimaryColor,
                          ),
                          child: const Text(
                            "GHC",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: cartBloc.amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (val) {
                              final v = double.tryParse(val) ?? 0.0;
                              cartBloc.add(CartSetAmountReceived(v));
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              border: border,
                              enabledBorder: border,
                              focusedBorder: border,
                              hintText: '0.00',
                              hintStyle: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isShort) ...[
                      Gap(6.h),
                      Text(
                        'Insufficient amount — GHC '
                        '${state.remaining.toStringAsFixed(2)} short',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: InvAPColors.kErrorRedColor,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            Gap(12.h),

            // Remaining and Change — rebuild only when amountReceived changes
            BlocBuilder<CartBloc, CartState>(
              buildWhen: (prev, curr) =>
                  prev.amountReceived != curr.amountReceived ||
                  prev.total != curr.total,
              builder: (context, state) => Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: InvAPColors.kLightRedColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining:'),
                        Text("GHC ${state.remaining.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                  Gap(8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: InvAPColors.kLightGreenColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Change:'),
                        Text("GHC ${state.change.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Gap(16.h),

            // Quick amount chips
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: [
                for (final amt in const [5, 10, 20, 50, 100, 200])
                  InkWell(
                    onTap: () {
                      final val = amt.toDouble();
                      cartBloc.amountController.text = val.toStringAsFixed(2);
                      cartBloc.amountController.selection =
                          TextSelection.collapsed(
                            offset: cartBloc.amountController.text.length,
                          );
                      cartBloc.add(CartSetAmountReceived(val));
                    },
                    child: Container(
                      height: 40.h,
                      width: 80.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: InvAPColors.kPrimaryColor,
                          width: 0.7.w,
                        ),
                      ),
                      child: Text('GHC ${amt.toStringAsFixed(2)}'),
                    ),
                  ),
              ],
            ),

            Gap(16.h),
          ],
        ),
      ),
    );
  }
}
