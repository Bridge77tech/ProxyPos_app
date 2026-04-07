import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/product_container_card.dart';
import 'package:inventory_app_pos/shared/ap_empty_products_widget.dart';
import 'package:inventory_app_pos/shared/ap_error_widget.dart';

import '../../../../../../../core/app_constants/ap_colors.dart';
import '../../../../../../../core/utils/utils.dart';
import '../../../../../../../shared/app_bar/inside_overlay_dialog.dart';
import '../../../../../../../shared/app_buttons/ap_button.dart';
import '../../data/model/product_model.dart';
import '../../data/model/variant.dart';
import '../../data/model/unit_model.dart';
import '../bloc/barcode/bar_code_bloc.dart';
import '../bloc/barcode/bar_code_state.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../bloc/cart/cart_state.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_event.dart';
import '../bloc/dashboard/dashboard_state.dart';

class LeftSideDashboardViewCard extends StatelessWidget {
  const LeftSideDashboardViewCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Step 0: order submitted successfully → refresh top products from API
        BlocListener<CartBloc, CartState>(
          listenWhen: (prev, curr) =>
              curr.successMessage != null && curr.successMessage != prev.successMessage,
          listener: (context, state) {
            context.read<DashboardBloc>().add(const RefreshTopProducts());
          },
        ),
        // Step 1: barcode scanned → ask DashboardBloc to find the product
        BlocListener<BarcodeBloc, BarcodeState>(
          listenWhen: (prev, curr) => curr.scannedBarcode != null && curr.scannedBarcode != prev.scannedBarcode,
          listener: (context, state) {
            context.read<DashboardBloc>().add(SearchByBarcode(state.scannedBarcode!));
          },
        ),
        // Step 2: DashboardBloc resolved the product → add to cart or show picker
        BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (prev, curr) => curr.barcodeProduct != null && curr.barcodeProduct != prev.barcodeProduct,
          listener: (context, state) {
            final product = state.barcodeProduct!;
            final cartBloc = context.read<CartBloc>();
            context.read<DashboardBloc>().add(const ClearBarcodeProduct());

            // Flatten all variant+unit combos
            final combos = <({Variants variant, UnitModel unit})>[];
            for (final v in product.variants ?? <Variants>[]) {
              for (final u in v.units ?? <UnitModel>[]) {
                combos.add((variant: v, unit: u));
              }
            }

            if (combos.length == 1) {
              // Only one option — add directly with qty 1
              cartBloc.add(CartAddItem(
                product: product,
                variant: combos.first.variant,
                unit: combos.first.unit,
                quantity: 1,
              ));
            } else {
              // Multiple options — let user pick variant/unit and quantity
              Utils.showOverlayDialog<void>(
                context,
                title: product.name ?? 'Product',
                roundCorner: 10,
                height: 0.7,
                child: InsideOverlay(products: product),
                bottomWidget: BlocBuilder<CartBloc, CartState>(
                  bloc: cartBloc,
                  builder: (ctx, cartState) => ApButton(
                    btnText: 'Add to Cart',
                    width: 0.3.sw,
                    cornerRadius: 10,
                    onPressed: cartState.selectedUnit == null || cartState.selectedQuantity <= 0
                        ? null
                        : () {
                            cartBloc.add(CartAddItem(
                              product: product,
                              variant: cartState.selectedVariant!,
                              unit: cartState.selectedUnit!,
                              quantity: cartState.selectedQuantity,
                            ));
                            cartBloc.add(const CartResetSelection());
                            Navigator.of(ctx).pop();
                          },
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: Column(
      children: [
        Container(
          width: double.infinity,
          height: 0.2.sh,
          padding: EdgeInsets.symmetric(
            horizontal: 30.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: InvAPColors.kWhiteColor,
          ),
          child: Column(children: [

          ],
          ),
        ),
        Gap(10.h),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: InvAPColors.kWhiteColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 25.w,
                    vertical: 12.h,
                  ),
                  child: Text(
                    'Most Purchased',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: BlocConsumer<DashboardBloc, DashboardState>(
                    listenWhen: (previous, current) {
                     return false;
                    },
                    listener: (context, state) {},
                    builder: (context, state) {
                      // Initial one-time dispatch to load top products
                      if (!state.requested) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          context.read<DashboardBloc>().add(const LoadTopProducts());
                        });
                      }

                      if (state.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.error != null) {
                        return APErrorWidget(
                          onRetry: () => context
                              .read<DashboardBloc>()
                              .add(const LoadTopProducts()),
                        );
                      }

                      // Always display topProducts here, ignore search.
                      final List<Products> source = state.topProducts;

                      if (source.isEmpty) {
                        return const APEmptyProductsWidget();
                      }

                      // Build a flat list of (product, variant, unit) entries so all units are displayed
                      final List<({Products product, Variants variant, UnitModel unit})> items = [];
                      for (final p in source) {
                        final vars = p.variants ?? const [];
                        for (final v in vars) {
                          final units = v.units ?? const [];
                          for (final u in units) {
                            items.add((product: p, variant: v, unit: u));
                          }
                        }
                      }

                      if (items.isEmpty) {
                        return const APEmptyProductsWidget();
                      }

                      return GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        shrinkWrap: true,
                        primary: false,
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150.w,
                          mainAxisSpacing: 25.h,
                          crossAxisSpacing: 25.w,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, i) {
                          final entry = items[i];
                          return ProductContainerCard(
                            product: entry.product,
                            variants: entry.variant,
                            unit: entry.unit,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }
}
