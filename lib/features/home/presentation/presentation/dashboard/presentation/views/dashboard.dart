import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import '../bloc/cart_event.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
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
                        onTap: () => context.read<CartBloc>().add(const CartClear()),
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
                Expanded(
                  flex: 3,
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
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, cartState) {
                        if (cartState.items.isEmpty) {
                          return Center(
                            child: Text(
                              'Your cart is empty',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }
                        return Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          child: ListView.builder(
                            primary: true,
                            itemCount: cartState.items.length,
                            itemBuilder: (context, index) {
                              final it = cartState.items[index];
                              return CartItemCardRow(
                                index: index,
                                name: it.productName,
                                variantLabel: '${it.variant.type} ${it.variant.size}',
                                price: it.variant.sellingPrice ?? 0,
                                quantity: it.quantity,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

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
                        return SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4.5.h,
                            children: [
                              _rowText(context, label: InvAppConstants.kVAT, value: '$ghc ${cartState.vat.toStringAsFixed(2)}'),
                              _rowText(context, label: InvAppConstants.kDiscount, value: '$ghc ${cartState.discount.toStringAsFixed(2)}'),
                              _rowText(context, label: InvAppConstants.kSubTotal, value: '$ghc ${cartState.subTotal.toStringAsFixed(2)}'),
                              _rowText(context, label: InvAppConstants.kTotal, value: '$ghc ${cartState.total.toStringAsFixed(2)}', fontWeight: FontWeight.w700),
                              ApButton(
                                onPressed: cartState.items.isEmpty ? null : () {
                                  debugPrint('Submit Order: ${cartState.items.length} items, total ${cartState.total}');
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

class CartItemCardRow extends StatelessWidget {
  const CartItemCardRow({super.key, required this.index, required this.name, required this.variantLabel, required this.price, required this.quantity});
  final int index;
  final String name;
  final String variantLabel;
  final num price;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final ghc = InvAppConstants.kGHC;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      width: 1.sw,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: InvAPColors.kBorderColor, width: 0.7.w),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${index + 1}', style: Theme.of(context).textTheme.bodySmall),
              InkWell(
                onTap: () => context.read<CartBloc>().add(CartRemoveItem(index)),
                child: Image.asset(Assets.iconsDeleteIcon, scale: 5),
              ),
            ],
          ),
          Divider(endIndent: 0, indent: 0, color: InvAPColors.kBorderColor, thickness: 0.7.w),
          Gap(5.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.bodySmall),
                    Text(variantLabel, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: InvAPColors.kSecondaryTextColor)),
                    Text('$ghc ${price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: InvAPColors.kPrimaryColor)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: InvAPColors.kBorderColor, width: 0.7.w),
                ),
                child: Row(
                  spacing: 10.w,
                  children: [
                    InkWell(
                      onTap: () => context.read<CartBloc>().add(CartUpdateItemQuantity(index, -1)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Icon(Icons.minimize, size: 18),
                      ),
                    ),
                    Text('$quantity'),
                    InkWell(
                      onTap: () => context.read<CartBloc>().add(CartUpdateItemQuantity(index, 1)),
                      child: Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
