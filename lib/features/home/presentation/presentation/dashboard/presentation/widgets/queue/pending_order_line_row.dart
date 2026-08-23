import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';

import '../../../data/data_source/local/pending_sales_storage.dart';

/// One line of a queued order.
///
/// Deliberately the same shape as TransactionItemRow in the history page — same flex weights
/// (4/1/2/2/2), same bodyMedium, same 10.h/16.w padding, same hairline divider between rows. A
/// cashier who already reads transaction history should recognise this without being taught it.
///
/// The only addition is the held-up marker, which appears on the line the server actually
/// complained about rather than on the whole order, so the cashier can see which item to deal with.
class PendingOrderLineRow extends StatelessWidget {
  const PendingOrderLineRow({
    super.key,
    required this.line,
    required this.isLast,
    this.isAffected = false,
  });

  final PendingSaleLine line;
  final bool isLast;

  /// The line the failure names. Carries the same red triangle as the collapsed order row.
  final bool isAffected;

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
                child: Row(
                  children: [
                    if (isAffected) ...[
                      Icon(
                        Icons.warning_amber_rounded,
                        key: const Key('queue-line-held-up-icon'),
                        color: InvAPColors.kErrorRedColor,
                        size: 16.sp,
                      ),
                      Gap(6.w),
                    ],
                    Expanded(
                      child: Text(
                        line.productName,
                        style: textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${line.quantity}',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  line.unitType.isEmpty ? '-' : line.unitType,
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'GHC ${line.unitPrice.toStringAsFixed(2)}',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'GHC ${line.lineTotal.toStringAsFixed(2)}',
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
