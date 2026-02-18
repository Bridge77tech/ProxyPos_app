import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/product_model.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/shared/app_bar/search_overlay_controller.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../core/utils/utils.dart';
import '../../features/home/presentation/presentation/dashboard/data/model/variant.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_state.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart_bloc.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart_event.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart_state.dart';

/// Renders the dropdown list of product suggestions using DashboardBloc state.
class SearchSuggestionsDropdown extends StatelessWidget {
  final SearchOverlayController searchController;
  const SearchSuggestionsDropdown({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // Hide dropdown while a selection modal is being shown
        if ((state.selectedName?.isNotEmpty ?? false)) {
          return const SizedBox.shrink();
        }
        final active = (state.lastQuery?.trim().isNotEmpty ?? false);
        final suggestions = state.searchResults;
        if (!active || suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 365.w, maxHeight: 220.h),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: InvAPColors.kBorderColor.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final p = suggestions[index];
              return ListTile(
                dense: true,
                tileColor: InvAPColors.kWhiteColor,
                title: Text(
                  p.name ?? '-',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: InvAPColors.kBlackColor),
                ),
                subtitle: (p.category != null && p.category!.isNotEmpty)
                    ? Text(
                        p.category!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: InvAPColors.kSecondaryTextColor),
                      )
                    : null,
                onTap: () {
                  final name = p.name ?? '';
                  debugPrint('Selected suggestion: $name');

                  // Correctly hide the overlay dropdown
                  try {
                    searchController.hide();
                  } catch (e) {
                    debugPrint('Failed to hide overlay: $e');
                  }

                  // Show overlay dialog via root navigator
                  final rootCtx = Navigator.of(context, rootNavigator: true).context;
                  Utils.showOverlayDialog<void>(
                    rootCtx,
                    onPressed: () => _onAddToCartOverlay(rootCtx, p),
                    child: InsideOverlay(
                      products: p,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _onAddToCartOverlay(BuildContext context, Products product) {
    final cart = context.read<CartBloc>();
    final state = cart.state;
    final variant = state.selectedVariant;
    final qty = state.selectedQuantity;

    if (variant == null) {
      debugPrint('Cannot add to cart: no variant selected');
      return;
    }
    if (qty <= 0) {
      debugPrint('Cannot add to cart: invalid quantity');
      return;
    }

    cart.add(CartAddItem(product: product, variant: variant, quantity: qty));
    // Reset selection after add so Quantity returns to default and variant clears
    cart.add(const CartResetSelection());
    Navigator.of(context).pop();
  }
}


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
                    child: Image.asset(Assets.imagesItem),
                  ),
                  Text("${products.name}", style: Theme.of(context).textTheme.bodySmall,)
                ],
              ),
            ),
            Gap(5.h),
            //
            Text('Select Item Type with Size', style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
              // Constrain inner ListView to a fixed height to avoid intrinsic dimension computation
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 320.h),
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    final variants = products.variants ?? const <Variants>[];
                    return ListView.separated(
                      primary: false,
                      padding: EdgeInsets.zero,
                      itemCount: variants.length,
                      separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: InvAPColors.kBorderColor.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final v = variants[index];
                        final selected = cartState.selectedVariant == v;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${v.type}', style: Theme.of(context).textTheme.bodySmall),
                          subtitle: Row(
                            spacing: 20.w,
                            children: [
                              Text(
                                  '${v.size}',
                                  style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                  'GHS ${v.sellingPrice}',
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.w500,
                                  ),
                              ),
                            ],
                          ),
                          // Replace deprecated Radio with a selection indicator icon
                          trailing: Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 18,
                            color: selected ? InvAPColors.kPrimaryColor : InvAPColors.kSecondaryTextColor,
                          ),
                          onTap: () {
                            context.read<CartBloc>().add(CartSelectVariant(product: products, variant: v));
                          },
                        );
                      },
                    );
                  },
                ),
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
