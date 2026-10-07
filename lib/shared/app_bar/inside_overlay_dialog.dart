import 'package:flutter/material.dart';
// FilteringTextInputFormatter lives here; material does not re-export it.
import 'package:flutter/services.dart';
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
      // Every box in here is a "fill" in the design, not a hug. A Column defaults its
      // children to their own width, which is why the Item Name and Quantity boxes only
      // looked full — their Rows happen to span — while the variant list shrank to its
      // longest row. stretch gives all of them the dialog's width, less the padding above.
      //
      // Utils.showOverlayDialog already wraps this child in a SingleChildScrollView, so
      // the one that used to be here was a second scrollable inside the first.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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
            key: const Key('item-name-card'),
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
                Text(
                  "${products.name}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Gap(5.h),
          //
          Text(
            'Select from Item variant, Type with Size',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: InvAPColors.kBlackColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          // No Container wrapping this. The other two boxes paint their white on the padded
          // Container itself, so the white spans the full width; this one painted it on the
          // Material *inside* a padded Container, which left this card 10.w narrower on each
          // side than the ones above and below it. The padding belongs to the list now, so
          // all three cards share one edge and the rows keep the same inner inset.
          //
          // The white surface has to stay a Material: a BoxDecoration paints an opaque box
          // ABOVE the Material, and a ListTile's ink splash paints on the Material below it,
          // so the splash would be drawn and then covered.
          Material(
            key: const Key('variant-card'),
            color: InvAPColors.kWhiteColor,
            borderRadius: BorderRadius.circular(5.r),
            // The list's own corners have to be cut to match, or a tile paints over them.
            clipBehavior: Clip.antiAlias,
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
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 10.w,
                  ),
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
                      // Flexible, not plain Text. The popup is 0.3.sw wide and a row here
                      // carries a shop-entered variant name, so a long one ran off the end;
                      // the Material's clip meant it was silently cut rather than striped.
                      // An ellipsis says there is more, which a hard cut does not.
                      title: Row(
                        spacing: 10.w,
                        children: [
                          Flexible(
                            child: Text(
                              "${v.name},",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              u.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        spacing: 10.w,
                        children: [
                          // The size gives way first. The price is what the cashier is
                          // reading off this row, so it is the one thing here that is never
                          // allowed to shrink or truncate.
                          Flexible(
                            child: Text(
                              v.size ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            'GHS ${u.sellingPrice}',
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                          ),
                          // The till already refuses an expired batch — but it refuses it
                          // at the end, after the cashier has picked the item, entered a
                          // quantity and pressed Add, with a customer waiting. Saying so
                          // here turns a rejection into a choice.
                          if (_expiryNote(v) != null)
                            Flexible(
                              child: Text(
                                _expiryNote(v)!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(
                                      color: _expiryColour(v),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: selected
                            ? InvAPColors.kPrimaryColor
                            : InvAPColors.kSecondaryTextColor,
                      ),
                      onTap: () {
                        context.read<CartBloc>().add(
                          CartSelectUnit(
                            product: products,
                            variant: v,
                            unit: u,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Get the purchase Quantity here.
          Gap(5.h),
          Text(
            'Enter Quantity',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: InvAPColors.kBlackColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return Container(
                key: const Key('quantity-card'),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
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
                    // Typed as well as stepped. This was a bare Text between the two
                    // buttons, so entering 20 meant twenty taps. CartSetQuantity already
                    // existed and was already handled by the bloc — nothing was ever
                    // wired to send it.
                    Expanded(
                      child: _QuantityField(
                        quantity: cartState.selectedQuantity,
                      ),
                    ),
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
    );
  }
}

/// A short word about this variant's expiry, or null when there is nothing to say.
///
/// Most goods are not perishable and carry no date at all; a badge rendered for those would
/// be noise on every row and would train the eye to skip the ones that matter.
String? _expiryNote(Variants v) {
  if (v.isExpired) return 'Expired';
  if (!v.isExpiringSoon) return null;
  final days = v.expiringDate!.difference(DateTime.now()).inDays;
  return days <= 0 ? 'Expires today' : 'Expires in ${days}d';
}

/// Red once lapsed, amber inside a week — the same convention as the stock dot on the grid
/// card and the expiry column in the portal's inventory table.
Color _expiryColour(Variants v) {
  if (v.isExpired) return Colors.red;
  return Colors.orange;
}

/// The quantity box in the sale popup.
///
/// Stateful only to own a TextEditingController: the quantity itself lives in CartBloc, and
/// this mirrors it. Writing the controller on every rebuild would fight the cursor of anyone
/// mid-way through typing, so the text is only rewritten when it actually disagrees with the
/// bloc — which is what happens when the +/- buttons move it.
class _QuantityField extends StatefulWidget {
  const _QuantityField({required this.quantity});

  final int quantity;

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.quantity.toString(),
  );

  @override
  void didUpdateWidget(covariant _QuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.quantity.toString();
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      // Digits only, so there is no such thing as an unparseable value below.
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: (value) {
        // An empty box is someone part-way through retyping, not a request for zero.
        // Snapping it back to the previous number here would make the field unusable.
        if (value.isEmpty) return;
        final parsed = int.tryParse(value);
        if (parsed != null) {
          context.read<CartBloc>().add(CartSetQuantity(parsed));
        }
      },
    );
  }
}
