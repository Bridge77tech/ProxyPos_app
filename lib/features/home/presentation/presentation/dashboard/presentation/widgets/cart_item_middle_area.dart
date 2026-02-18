import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import 'cart_item_card_row.dart';

class CartItemsMiddleArea extends StatelessWidget {
  const CartItemsMiddleArea({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                    variantLabel:
                    '${it.variant.type} ${it.variant.size}',
                    price: it.variant.sellingPrice ?? 0,
                    quantity: it.quantity,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
