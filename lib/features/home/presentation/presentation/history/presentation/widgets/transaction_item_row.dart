import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/sale_items_model.dart';

class TransactionItemRow extends StatelessWidget {
  const TransactionItemRow({super.key, required this.item, required this.isLast});

  final SaleItemsModel item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  item.productName ?? '-',
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${item.quantity ?? 0}',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.unit ?? '-',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'GHC ${item.unitPrice ?? '0.00'}',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'GHC ${item.subtotal ?? '0.00'}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: InvAPColors.kBorderColor.withValues(alpha: 0.4),
            indent: 16.w,
            endIndent: 16.w,
          ),
      ],
    );
  }
}
