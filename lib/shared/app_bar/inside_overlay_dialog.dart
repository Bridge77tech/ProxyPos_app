import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../generated/assets.dart';
import '../../features/home/presentation/presentation/dashboard/data/model/product_model.dart';
import '../../features/home/presentation/presentation/dashboard/data/model/unit_model.dart';
import '../../features/home/presentation/presentation/dashboard/data/model/variant.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_bloc.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_event.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_state.dart';

class InsideOverlay extends StatelessWidget {
  const InsideOverlay({required this.products, super.key});

  final Products products;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10.h,
          children: [
            Gap(20.h),
            Text(
              'Item Name',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: InvAPColors.kBlackColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
              decoration: BoxDecoration(
                color: InvAPColors.kWhiteColor,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Row(
                spacing: 10.w,
                children: [
                  SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: () {
                      final imgPath = products.variants
                          ?.map((v) => v.imagePath)
                          .firstWhere(
                            (p) => p != null && p.isNotEmpty,
                            orElse: () => null,
                          );
                      if (imgPath != null) {
                        return Image.network(
                          imgPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              Image.asset(Assets.imagesItem, fit: BoxFit.contain),
                        );
                      }
                      return Image.asset(Assets.imagesItem, fit: BoxFit.contain);
                    }(),
                  ),
                  Text("${products.name}", style: Theme.of(context).textTheme.bodySmall,)
                ],
              ),
            ),
            Gap(5.h),
            //
            Text('Select from Item variant, Type with Size', style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: InvAPColors.kBlackColor,
              fontWeight: FontWeight.w500,
            ),),
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 10.h,
                horizontal: 10.w,
              ),
              decoration: BoxDecoration(
                color: InvAPColors.kWhiteColor,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, cartState) {
                  final variants = products.variants ?? const <Variants>[];
                  // Flatten units from all variants
                  final units = <({Variants variant, UnitModel unit})>[];
                  for (final v in variants) {
                    final vUnits = v.units ?? const <UnitModel>[];
                    for (final u in vUnits) {
                      units.add((variant: v, unit: u));
                    }
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: units.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: InvAPColors.kBorderColor.withValues(alpha: 0.5),
                    ),
                    itemBuilder: (context, index) {
                      final entry = units[index];
                      final v = entry.variant;
                      final u = entry.unit;
                      final selected = cartState.selectedUnit == u;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          spacing: 10.w,
                          children: [
                            Text("${v.name},", style: Theme.of(context).textTheme.bodyMedium,),
                           Text(u.type, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        subtitle: Row(
                          spacing: 10.w,
                          children: [
                            Text(
                              v.size ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'GHS ${u.sellingPrice}',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 18,
                          color: selected ? InvAPColors.kPrimaryColor : InvAPColors.kSecondaryTextColor,
                        ),
                        onTap: () {
                          context.read<CartBloc>().add(CartSelectUnit(product: products, variant: v, unit: u));
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Get the purchase Quantity here.
            Gap(5.h),
            Text('Enter Quantity', style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: InvAPColors.kBlackColor,
              fontWeight: FontWeight.w500,
            ),),
            BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 10.w,
                  ),
                  decoration: BoxDecoration(
                    color: InvAPColors.kWhiteColor,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove,
                          size: 18.sp,
                          color: InvAPColors.kBlack100,
                        ),
                        onPressed: () => context.read<CartBloc>().add(
                          const CartChangeQuantity(-1),
                        ),
                      ),
                      Text('${cartState.selectedQuantity}'),
                      IconButton(
                        icon: Icon(
                          Icons.add,
                          size: 18.sp,
                          color: InvAPColors.kBlack100,
                        ),
                        onPressed: () => context.read<CartBloc>().add(
                          const CartChangeQuantity(1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Add to Cart button
            Gap(10.h),
          ],
        ),
      ),
    );
  }
}