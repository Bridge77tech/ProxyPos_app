import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/sale_model.dart';

import 'transaction_item_row.dart';

class TransactionCard extends StatefulWidget {
  const TransactionCard({super.key, required this.sale});

  final SaleModel sale;

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _expanded = false;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'am' : 'pm';
      return '$day/$month/$year  $hour:$minute$period';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = widget.sale.items ?? [];
    final itemCount = items.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: InvAPColors.kWhiteColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // --- Collapsed header row ---
          InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Card icon
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: InvAPColors.kPrimaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: InvAPColors.kPrimaryColor,
                      size: 20.sp,
                    ),
                  ),

                  Gap(12.w),

                  // Amount + date
                  SizedBox(
                    width: 140.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GHC ${widget.sale.totalAmount ?? '0.00'}',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Gap(2.h),
                        Text(
                          _formatDate(widget.sale.saleDate),
                          style: textTheme.bodySmall?.copyWith(
                            color: InvAPColors.kSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Order ID (center)
                  Expanded(
                    child: Text(
                      'Order ID: ${widget.sale.saleNumber ?? '-'}',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Items count + payment method
                  SizedBox(
                    width: 120.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Gap(2.h),
                        Text(
                          widget.sale.paymentMethod ?? '-',
                          style: textTheme.bodySmall?.copyWith(
                            color: InvAPColors.kSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Gap(8.w),

                  // Chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: InvAPColors.kSecondaryTextColor,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Expanded items section ---
          if (_expanded && items.isNotEmpty) ...[
            Divider(height: 1, color: InvAPColors.kBorderColor.withValues(alpha: 0.5)),

            // Header row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Product',
                      style: textTheme.bodySmall?.copyWith(
                        color: InvAPColors.kSecondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Qty',
                      style: textTheme.bodySmall?.copyWith(
                        color: InvAPColors.kSecondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Unit',
                      style: textTheme.bodySmall?.copyWith(
                        color: InvAPColors.kSecondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Unit Price',
                      style: textTheme.bodySmall?.copyWith(
                        color: InvAPColors.kSecondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Subtotal',
                      style: textTheme.bodySmall?.copyWith(
                        color: InvAPColors.kSecondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: InvAPColors.kBorderColor.withValues(alpha: 0.4)),

            ...List.generate(items.length, (i) {
              return TransactionItemRow(
                item: items[i],
                isLast: i == items.length - 1,
              );
            }),

            Gap(4.h),
          ],
        ],
      ),
    );
  }
}
