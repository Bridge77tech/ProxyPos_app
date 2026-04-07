import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/product_model.dart';
import 'package:inventory_app_pos/shared/app_bar/search_overlay_controller.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../core/utils/utils.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard/dashboard_bloc.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard/dashboard_event.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard/dashboard_state.dart';

import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_bloc.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_event.dart';
import 'inside_overlay_dialog.dart';

/// Renders the dropdown list of product suggestions using DashboardBloc state.
class SearchSuggestionsDropdown extends StatelessWidget {
  final SearchOverlayController searchController;
  final TextEditingController textController;
  final FocusNode focusNode;
  const SearchSuggestionsDropdown({
    super.key,
    required this.searchController,
    required this.textController,
    required this.focusNode,
  });

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
                  // Hide dropdown, clear field, and dismiss keyboard immediately
                  searchController.hide();
                  textController.clear();
                  focusNode.unfocus();
                  // Clear search state in bloc
                  context.read<DashboardBloc>().add(const SearchProducts(''));

                  // Show the product detail dialog
                  final rootCtx = Navigator.of(context, rootNavigator: true).context;
                  Utils.showOverlayDialog<void>(
                    rootCtx,
                    onPressed: () => _onAddToCartOverlay(rootCtx, p),
                    child: InsideOverlay(products: p),
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
    final unit = state.selectedUnit;
    final qty = state.selectedQuantity;

    if (variant == null || unit == null) {
      debugPrint('Cannot add to cart: no unit selected');
      return;
    }
    if (qty <= 0) {
      debugPrint('Cannot add to cart: invalid quantity');
      return;
    }

    cart.add(CartAddItem(
      product: product,
      variant: variant,
      unit: unit,
      quantity: qty,
    ));
    // Reset selection after add so Quantity returns to default and variant clears
    cart.add(const CartResetSelection());
    Navigator.of(context).pop();
  }
}

