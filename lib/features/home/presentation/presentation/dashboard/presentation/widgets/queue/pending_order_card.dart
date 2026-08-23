import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';

import '../../../data/data_source/local/pending_sales_storage.dart';
import 'pending_order_line_row.dart';

/// A queued order: collapsed to one row, expanding to its line items.
///
/// Built to the same pattern as TransactionCard on the history page — the same 200ms
/// AnimatedContainer, the same InkWell header, the same rotating chevron, the same column headings
/// over the expanded rows — because a cashier meeting this for the first time has already used that
/// screen. It is a smaller version of a familiar thing rather than a new thing.
///
/// ## Why the actions are not all equal
///
/// **Retry** is safe for anyone, cashiers included. The queued payload keeps the idempotency key it
/// was created with, so the server recognises a repeat and returns the sale it already recorded.
/// The worst case is no change at all.
///
/// **Re-enter** creates a NEW sale with a NEW key. If the stuck original later succeeds, the shop
/// has two sales for one basket: stock deducted twice and revenue overstated. **Discard** removes
/// real takings from the record entirely.
///
/// Both are therefore owner-only. The owner is the person who reads the reports those mistakes
/// would distort, so they are the person who should carry the decision. A cashier under pressure
/// with a customer waiting should not be able to make a revenue figure wrong to clear a badge —
/// which is also why the two buttons are shown greyed rather than hidden: a cashier can see the
/// options exist and that they need the owner, instead of concluding the till is broken.
class PendingOrderCard extends StatefulWidget {
  const PendingOrderCard({
    super.key,
    required this.sale,
    required this.isOwner,
    required this.onRetry,
    required this.onDiscard,
    required this.onReenter,
  });

  final PendingSale sale;

  /// Gates discard and re-enter. Passed in rather than read from storage here so the permission is
  /// explicit at the call site and directly settable in a test.
  final bool isOwner;

  final VoidCallback onRetry;

  /// Called only after the confirmation is accepted. This widget owns that dialog.
  final VoidCallback onDiscard;

  final VoidCallback onReenter;

  @override
  State<PendingOrderCard> createState() => _PendingOrderCardState();
}

class _PendingOrderCardState extends State<PendingOrderCard> {
  bool _expanded = false;

  Future<void> _confirmDiscard() async {
    final sale = widget.sale;

    // Naming the amount is the point of this dialog. "Discard this order?" invites a reflex yes;
    // "Discard GHC 240.00?" is a number someone has to decide about, and these are real takings
    // that no longer exist anywhere else once this is done.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('queue-discard-confirm'),
        title: const Text('Discard this sale?'),
        content: Text(
          'GHC ${sale.total.toStringAsFixed(2)} will be removed from the queue and never sent. '
          'This cannot be undone, and the sale will not appear in any report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const Key('queue-discard-confirm-accept'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: InvAPColors.kErrorRedColor),
            child: const Text('Discard sale'),
          ),
        ],
      ),
    );

    if (confirmed == true) widget.onDiscard();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sale = widget.sale;
    final lines = sale.lines;
    final count = lines.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: InvAPColors.kWhiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: sale.heldUp
            ? Border.all(color: InvAPColors.kErrorRedColor.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        children: [
          // --- Collapsed header row ---
          InkWell(
            key: const Key('queue-order-header'),
            borderRadius: BorderRadius.circular(12.r),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: (sale.heldUp
                              ? InvAPColors.kErrorRedColor
                              : InvAPColors.kPrimaryColor)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      sale.heldUp ? Icons.warning_amber_rounded : Icons.cloud_upload_outlined,
                      key: sale.heldUp ? const Key('queue-order-held-up-icon') : null,
                      color: sale.heldUp
                          ? InvAPColors.kErrorRedColor
                          : InvAPColors.kPrimaryColor,
                      size: 18.sp,
                    ),
                  ),
                  Gap(10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GHC ${sale.total.toStringAsFixed(2)}',
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Gap(2.h),
                        Text(
                          sale.heldUp
                              ? 'Held up — ${sale.lastError ?? 'needs attention'}'
                              : 'Waiting to sync',
                          style: textTheme.bodySmall?.copyWith(
                            color: sale.heldUp
                                ? InvAPColors.kErrorRedColor
                                : InvAPColors.kSecondaryTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}',
                    style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Gap(8.w),
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

          // --- Expanded: line items, then the actions ---
          if (_expanded) ...[
            Divider(height: 1, color: InvAPColors.kBorderColor.withValues(alpha: 0.5)),
            if (lines.isNotEmpty) ...[
              _columnHeadings(textTheme),
              Divider(height: 1, color: InvAPColors.kBorderColor.withValues(alpha: 0.4)),
              ...List.generate(
                lines.length,
                (i) => PendingOrderLineRow(
                  line: lines[i],
                  isLast: i == lines.length - 1,
                  isAffected: sale.isLineAffected(lines[i]),
                ),
              ),
            ] else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Text(
                  // Only reachable for a sale queued by a build that stored no line snapshot.
                  'Item details were not recorded for this order.',
                  style: textTheme.bodySmall?.copyWith(
                    color: InvAPColors.kSecondaryTextColor,
                  ),
                ),
              ),
            Divider(height: 1, color: InvAPColors.kBorderColor.withValues(alpha: 0.4)),
            _actions(),
            Gap(4.h),
          ],
        ],
      ),
    );
  }

  Widget _columnHeadings(TextTheme textTheme) {
    Widget heading(String label, int flex, TextAlign align) => Expanded(
          flex: flex,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: InvAPColors.kSecondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: align,
          ),
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          heading('Product', 4, TextAlign.start),
          heading('Qty', 1, TextAlign.center),
          heading('Unit', 2, TextAlign.center),
          heading('Unit Price', 2, TextAlign.center),
          heading('Subtotal', 2, TextAlign.end),
        ],
      ),
    );
  }

  Widget _actions() {
    // Wrap rather than Row: three labelled buttons do not fit the dropdown's width on a narrower
    // till, and a Row clips them — the last action silently disappears off the edge. Wrapping to a
    // second line keeps all three reachable at any width. A widget test caught this.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 4.w,
        runSpacing: 4.h,
        children: [
          TextButton.icon(
            key: const Key('queue-action-retry'),
            onPressed: widget.onRetry,
            icon: Icon(Icons.refresh_rounded, size: 18.sp),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: InvAPColors.kPrimaryColor),
          ),
          _ownerOnly(
            key: const Key('queue-action-reenter'),
            label: 'Re-enter',
            icon: Icons.edit_outlined,
            onPressed: widget.onReenter,
          ),
          _ownerOnly(
            key: const Key('queue-action-discard'),
            label: 'Discard',
            icon: Icons.delete_outline_rounded,
            onPressed: _confirmDiscard,
            danger: true,
          ),
        ],
      ),
    );
  }

  /// An action only the owner may take.
  ///
  /// Rendered for everyone and disabled for a cashier — never hidden. A hidden control tells a
  /// cashier nothing; a greyed one with "Admin only" tells them the till is fine and who to ask.
  /// Tooltip is what carries that label: it surfaces on long-press on a touch till and on hover
  /// where there is a pointer, which is exactly the two cases asked for.
  Widget _ownerOnly({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    final enabled = widget.isOwner;
    final colour = danger ? InvAPColors.kErrorRedColor : InvAPColors.kPrimaryTextColor;

    final button = TextButton.icon(
      key: key,
      // null is what actually disables it — a guard inside the callback would still let the ripple
      // and the tap land, and would rely on remembering to re-check.
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18.sp),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: colour,
        disabledForegroundColor: InvAPColors.kDisableBtnColor,
      ),
    );

    if (enabled) return button;

    return Tooltip(
      key: Key('${key.toString()}-admin-only'),
      message: 'Admin only',
      triggerMode: TooltipTriggerMode.longPress,
      child: button,
    );
  }
}
