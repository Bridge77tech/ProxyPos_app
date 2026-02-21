import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';

import '../../data/model/product_model.dart';
import '../../data/model/variant.dart';
import '../../data/model/unit_model.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';



class ProductContainerCard extends StatefulWidget {
  const ProductContainerCard({
    super.key,
    required this.variants,
    required this.product,
    this.unit,
  });

  final Variants? variants;
  final Products? product;
  final UnitModel? unit;

  @override
  State<ProductContainerCard> createState() => _ProductContainerCardState();
}

class _ProductContainerCardState extends State<ProductContainerCard> {
  int qty = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.product?.name ?? '';
    final unitType = widget.unit?.type;
    final price = widget.unit?.sellingPrice ?? widget.variants?.sellingPrice ?? 0.0;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        // border: Border.all(color: InvAPColors.kBorderColor, width: 0.7.w),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2.h,
        children: [
          Container(
            width: 1.sw,
            height: 73.h,
            decoration: BoxDecoration(
              color: InvAPColors.kWhiteColor,
              border: Border.all(
                color: InvAPColors.kBorderColor,
                width: 0.7.w,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              height: 43.h,
              child: Image.asset(
                widget.product?.imagePath ?? Assets.imagesItem,
                fit: BoxFit.contain,
                width: 43.w,
                height: 43.h,
              ),
            ),
          ),
          Text(
            displayName,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unitType ?? "${widget.variants?.type}, ${widget.variants?.size}",
            style: theme.textTheme.bodySmall?.copyWith(
              color: InvAPColors.kSecondaryTextColor,
              fontSize: 10.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GH₵${price.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      color: (widget.variants?.currentStock ?? 0) > 0
                          ? Colors.green
                          : InvAPColors.kBorderColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '${widget.variants?.currentStock ?? 0}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: InvAPColors.kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: InvAPColors.kBorderColor,
                    width: 0.7.w,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: qty > 0
                          ? () => setState(() => qty = qty - 1)
                          : null,
                      child: Icon(
                        Icons.remove,
                        size: 12.sp,
                        color: qty > 0
                            ? InvAPColors.kSecondaryTextColor
                            : InvAPColors.kBorderColor,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text('$qty', style: theme.textTheme.bodyMedium),
                    SizedBox(width: 10.w),
                    InkWell(
                      onTap: () => setState(() => qty = qty + 1),
                      child: Icon(
                        Icons.add,
                        size: 12.sp,
                        color: InvAPColors.kSecondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: Platform.isWindows ? 40.w : 50.w,
                height: Platform.isWindows ? 32.h : 20.h,
                child: ApButton(
                  height: 20.h,
                  width: 50.w,
                  onPressed: qty == 0 || widget.product == null || widget.variants == null || widget.unit == null
                      ? null
                      : () {
                          final cart = context.read<CartBloc>();
                          final product = widget.product!;
                          final variant = widget.variants!;
                          final unit = widget.unit!;
                          cart.add(CartAddItem(product: product, variant: variant, unit: unit, quantity: qty));
                          setState(() => qty = 0);
                        },
                  btnText: 'Add',
                  paddingHorizontal: 8.0,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}