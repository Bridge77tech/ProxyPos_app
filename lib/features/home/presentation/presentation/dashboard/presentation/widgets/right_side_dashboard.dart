import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/core/utils/utils.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_event.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_state.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/cash_out_overflow_content.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';
import 'package:loader_overlay/loader_overlay.dart';

class RightSideDashboard extends StatelessWidget {
  const RightSideDashboard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                rowText(
                  context,
                  label: InvAppConstants.kVAT,
                  value:
                      '$ghc ${cartState.vat.toStringAsFixed(2)}',
                ),
                rowText(
                  context,
                  label: InvAppConstants.kDiscount,
                  value:
                      '$ghc ${cartState.discount.toStringAsFixed(2)}',
                ),
                rowText(
                  context,
                  label: InvAppConstants.kSubTotal,
                  value:
                      '$ghc ${cartState.subTotal.toStringAsFixed(2)}',
                ),
                rowText(
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
                          final bloc = context.read<CartBloc>();
                          Utils.showOverlayDialog(
                            context,
                            title: 'Checkout',
                            roundCorner: 10,
                            height: 0.7,
                            child: CheckOutOverFlowContent(),
                            bottomWidget: BlocBuilder<CartBloc, CartState>(
                              bloc: bloc,
                              builder: (ctx, state) => ApButton(
                                btnText: 'Submit',
                                width: 0.3.sw,
                                cornerRadius: 10,
                                // Also disabled while the amount is short: the server
                                // rejects an underpaid sale for every payment method,
                                // so submitting one can only ever fail.
                                onPressed: state.paymentMethod == null ||
                                        state.amountReceived <= 0 ||
                                        state.isShortPayment
                                    ? null
                                    : () {
                                        bloc.add(const CartSubmitOrder());
                                      },
                              ),
                            ),
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
                    );
  }
}


Widget rowText(
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
