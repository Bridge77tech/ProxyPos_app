import 'package:flutter/material.dart';
// FilteringTextInputFormatter lives here; material does not re-export it.
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';

import '../../data/model/product_model.dart';
import '../../data/model/variant.dart';
import '../../data/model/unit_model.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';

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

  /// Lets the quantity be typed as well as stepped. Kept in sync both ways: the
  /// buttons write into it, and typing writes back into [qty].
  final _qtyController = TextEditingController(text: '0');

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  /// Individual items one of this unit consumes. A pack of 12 draws 12, so 20 in
  /// stock permits one pack, not twenty.
  double get _perUnit {
    final per = widget.unit?.individualPieces ?? 1;
    return per <= 0 ? 1.0 : per;
  }

  /// Most of this unit that stock allows. Ignores what is already in the cart — the
  /// card cannot see it — so CartBloc still has the final say; this only stops the
  /// obvious case of asking for more than exists.
  int get _maxQty => ((widget.variants?.currentStock ?? 0) / _perUnit).floor();

  /// Single point of change for the quantity, so the field and the buttons can never
  /// disagree. [fromField] avoids rewriting the text the user is mid-way through
  /// typing, which would fight their cursor.
  void _setQty(int next, {bool fromField = false}) {
    final clamped = next.clamp(0, _maxQty);
    setState(() => qty = clamped);

    final text = clamped.toString();
    if (_qtyController.text != text && !(fromField && next == clamped)) {
      _qtyController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = widget.product?.name ?? '';
    final variantName = widget.variants?.name?.trim() ?? '';
    final price =
        widget.unit?.sellingPrice ?? widget.variants?.sellingPrice ?? 0.0;

    final maxQty = _maxQty;

    // One height for the stepper and the Add button, so they line up.
    //
    // Raw design units, not pre-scaled: ApButton applies ScreenUtil itself
    // (fixedSize: Size(width.w, height.h), fontSize.sp), so a caller passing 20.h had
    // it scaled twice. The stepper multiplies by .h at its own use site instead.
    const controlHeight = 38.0;

    // Unit, type and size on one line, e.g. "Bulk · tin · 500g".
    //
    // This line used to read `unitType ?? "${type}, ${size}"`, which showed the
    // unit type *instead of* the type and size. Every card in the grid is built
    // from a unit, so unitType was never null and the fallback never ran — the
    // variant's type and size were unreachable. Joining only the parts that are
    // actually present also avoids rendering stray separators for the many
    // variants that have no type or no size.
    final unitTypeAndSize =
        [widget.unit?.type, widget.variants?.type, widget.variants?.size]
            .whereType<String>()
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .join(' · ');
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16.r)),
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
              border: Border.all(color: InvAPColors.kBorderColor, width: 0.7.w),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              height: 43.h,
              child: () {
                final path = widget.variants?.imagePath;
                if (path != null && path.isNotEmpty) {
                  return Image.network(
                    path,
                    fit: BoxFit.contain,
                    width: 43.w,
                    height: 43.h,
                    errorBuilder: (ctx, e, stack) => Image.asset(
                      Assets.imagesItem,
                      fit: BoxFit.contain,
                      width: 43.w,
                      height: 43.h,
                    ),
                  );
                }
                return Image.asset(
                  Assets.imagesItem,
                  fit: BoxFit.contain,
                  width: 43.w,
                  height: 43.h,
                );
              }(),
            ),
          ),
          Text(
            displayName,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (variantName.isNotEmpty)
            Text(
              variantName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: InvAPColors.kSecondaryTextColor,
                fontSize: 10.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (unitTypeAndSize.isNotEmpty)
            Text(
              unitTypeAndSize,
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
                    // Stock is a whole count of individual items, but the model
                    // holds it as a double, so plain interpolation printed "164.0".
                    (widget.variants?.currentStock ?? 0).toStringAsFixed(0),
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
              // Expanded rather than self-sizing: the fixed-width quantity slot
              // pushed this row 14px past the card. Taking whatever the Add
              // button leaves means it cannot overflow at any card width.
              Expanded(
                child: Container(
                  // Fixed height rather than derived from padding, so this and the
                  // Add button are provably the same size rather than coincidentally
                  // similar. The Row centres its children within it.
                  height: controlHeight.h,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: InvAPColors.kBorderColor,
                      width: 0.7.w,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    // Pinned to the edges, so the buttons stay put whatever the
                    // number between them reads.
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: qty > 0 ? () => _setQty(qty - 1) : null,
                        child: Icon(
                          Icons.remove,
                          size: 12.sp,
                          color: qty > 0
                              ? InvAPColors.kSecondaryTextColor
                              : InvAPColors.kBorderColor,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          // Digits only, so there is no such thing as an unparseable
                          // value to defend against further down.
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: theme.textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          // Empty reads as 0 rather than snapping back to the previous
                          // value, so clearing the box to retype is not a fight.
                          onChanged: (value) => _setQty(
                            int.tryParse(value) ?? 0,
                            fromField: true,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: qty < maxQty ? () => _setQty(qty + 1) : null,
                        child: Icon(
                          Icons.add,
                          size: 12.sp,
                          color: qty < maxQty
                              ? InvAPColors.kSecondaryTextColor
                              : InvAPColors.kBorderColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 24px between the stepper and the button.
              SizedBox(width: 24.w),
              SizedBox(
                child: ApButton(
                  // Raw units — ApButton scales them itself. Font raised from 8 in
                  // step with the height going 20 -> 38, so the label keeps its
                  // proportions. The Windows-specific box is gone: both controls now
                  // share one height on every platform.
                  height: controlHeight,
                  width: 56,
                  fontSize: 15,
                  onPressed:
                      qty == 0 ||
                          widget.product == null ||
                          widget.variants == null ||
                          widget.unit == null
                      ? null
                      : () {
                          final cart = context.read<CartBloc>();
                          final product = widget.product!;
                          final variant = widget.variants!;
                          final unit = widget.unit!;
                          cart.add(
                            CartAddItem(
                              product: product,
                              variant: variant,
                              unit: unit,
                              quantity: qty,
                            ),
                          );
                          // Through the setter, so the field clears with it —
                          // otherwise Add greys out while the box still shows a
                          // number.
                          _setQty(0);
                        },
                  btnText: 'Add',
                  paddingHorizontal: 8.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
