import 'package:flutter/material.dart';
// FilteringTextInputFormatter lives here; material does not re-export it.
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/core/utils/unit_stock.dart';
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

  /// How many of THIS unit the shelf holds, or null when the pack size cannot say.
  ///
  /// The one number the cashier needs. They have already tapped "Coca-Cola 12-pack" and there is a
  /// customer waiting; that the variant holds 240 bottles is true and, at this moment, noise.
  ///
  /// Uses the shared mirror in core/utils/unit_stock.dart rather than dividing here, so this card,
  /// the quantity clamp below and the portal cannot drift on the rounding.
  int? get _stockInUnits => unitsAvailable(
        widget.unit?.individualPieces,
        widget.variants?.currentStock,
      );

  /// This unit's own state, falling back to the variant's when the unit cannot be expressed.
  ///
  /// Judged against the threshold converted into this unit — 20 packs is not "low" because the
  /// variant's threshold of 24 bottles happens to be a bigger number.
  UnitStockState get _stockState {
    final own = unitStockState(
      individualPieces: widget.unit?.individualPieces,
      baseUnits: widget.variants?.currentStock,
      baseThreshold: widget.variants?.lowThresholdAlert,
    );
    if (own != null) return own;

    // No usable pack size. Fall back to what the server said about the variant, which is the
    // behaviour this card had before it counted in units.
    final v = widget.variants;
    if (v == null || v.isOutOfStock) return UnitStockState.outOfStock;
    return v.isLowStock ? UnitStockState.lowStock : UnitStockState.inStock;
  }

  /// Most of this unit that stock allows. Ignores what is already in the cart — the
  /// card cannot see it — so CartBloc still has the final say; this only stops the
  /// obvious case of asking for more than exists.
  ///
  /// An unusable pack size clamps to 0 rather than to the raw pool. The old fallback treated a
  /// broken pack size as 1 base item, which would have offered the cashier 240 crates; the sale
  /// path refuses such a unit anyway (baseUnitsFor throws), so offering it was never real.
  int get _maxQty => _stockInUnits ?? 0;

  /// What the stock dot means, worst state first.
  ///
  /// Expired outranks out-of-stock: a shelf holding expired goods is a worse problem than an
  /// empty one, and the cart refuses the sale either way.
  ///
  /// Stock is judged for the selected unit, expiry for the whole variant — a batch expires as a
  /// batch, regardless of how it is packaged.
  Color get _stockDotColour {
    final v = widget.variants;
    if (v == null) return InvAPColors.kBorderColor;
    if (v.isExpired) return Colors.red;
    if (_stockState == UnitStockState.outOfStock) return InvAPColors.kBorderColor;
    if (v.isExpiringSoon || _stockState == UnitStockState.lowStock) return Colors.orange;
    return Colors.green;
  }

  /// A short word beside the count, or null when the stock is simply fine.
  String? get _stockNote {
    final v = widget.variants;
    if (v == null) return null;
    if (v.isExpired) return 'Expired';
    if (_stockState == UnitStockState.outOfStock) return null; // the count already reads 0
    if (v.isExpiringSoon) {
      final days = v.expiringDate!.difference(DateTime.now()).inDays;
      return days <= 0 ? 'Expires today' : 'Expires in \${days}d';
    }
    if (_stockState == UnitStockState.lowStock) return 'Low';
    return null;
  }

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
              // Swapped with the price: this takes bodySmall (13), the price takes
              // the 10 this used to have.
              style: theme.textTheme.bodySmall?.copyWith(
                color: InvAPColors.kSecondaryTextColor,
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
                  // Swapped with the unit/size line above, which now takes the 13
                  // this had.
                  fontSize: 10.sp,
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
                      color: _stockDotColour,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    // The count in the SELECTED unit, not the variant's base-unit pool. Having
                    // tapped "12-pack", the useful number is 20 crates, not 240 bottles. Base
                    // units belong at the till in exactly one place — the refusal message, which
                    // still says "need 12, have 11" and stays that way.
                    //
                    // A dash when the pack size cannot say: falling back to the pool would put
                    // 240 back on the pack card, which is the bug.
                    _stockInUnits?.toString() ?? '—',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: InvAPColors.kPrimaryColor,
                    ),
                  ),
                  // Only rendered when there is something to say. Most stock is neither low nor
                  // perishable, and a card carrying an empty badge reads as a rendering fault.
                  if (_stockNote != null) ...[
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        _stockNote!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: _stockDotColour),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // 4px above: the Column contributes 2 via its spacing, this adds the
          // other 2.
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Row(
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
                // 8px between the stepper and the button.
                SizedBox(width: 8.w),
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
          ),
        ],
      ),
    );
  }
}
