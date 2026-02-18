import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../../../../../../../core/app_constants/inv_app_constants.dart';
import '../../../../../../../generated/assets.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';

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