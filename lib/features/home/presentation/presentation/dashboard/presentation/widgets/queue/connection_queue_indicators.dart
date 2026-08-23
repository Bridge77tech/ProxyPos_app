import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';

import '../../../data/data_source/local/pending_sales_storage.dart';
import 'pending_order_card.dart';

/// Connection state, and beside it the queue of sales that have not reached the server.
///
/// ## When the queue badge shows
///
///   online, nothing queued   connection indicator only
///   offline                  indicator reads offline, badge appears with a count
///   back online, draining    badge stays while it works through
///   fully drained            badge disappears
///   something held up        badge stays REGARDLESS of connection, with a red triangle
///
/// That last row is the important one and it is deliberate: a badge sitting there while the till is
/// online is itself the signal that something needs a human. Hiding it once connectivity returned
/// would restore exactly the failure this was built to end — takings stranded on a device while the
/// till looks perfectly normal.
class ConnectionQueueIndicators extends StatelessWidget {
  const ConnectionQueueIndicators({
    super.key,
    required this.isOnline,
    required this.queue,
    required this.isOwner,
    required this.onRetry,
    required this.onDiscard,
    required this.onReenter,
  });

  final bool isOnline;
  final List<PendingSale> queue;
  final bool isOwner;
  final void Function(String queueId) onRetry;
  final void Function(String queueId) onDiscard;
  final void Function(String queueId) onReenter;

  bool get _hasHeldUp => queue.any((s) => s.heldUp);

  /// The badge is shown whenever there is anything queued at all. An empty queue is the only state
  /// that hides it — not "we are online again".
  bool get _showBadge => queue.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ConnectionIndicator(isOnline: isOnline),
        if (_showBadge) ...[
          Gap(6.w),
          _QueueBadge(
            count: queue.length,
            hasHeldUp: _hasHeldUp,
            onTap: () => _openDropdown(context),
          ),
        ],
      ],
    );
  }

  void _openDropdown(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => _QueueDropdown(
        queue: queue,
        isOwner: isOwner,
        onRetry: onRetry,
        onDiscard: onDiscard,
        onReenter: onReenter,
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final colour = isOnline ? InvAPColors.kPrimaryColor : InvAPColors.kErrorRedColor;

    return Container(
      key: Key('connection-indicator-${isOnline ? 'online' : 'offline'}'),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          Gap(5.w),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colour,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({
    required this.count,
    required this.hasHeldUp,
    required this.onTap,
  });

  final int count;
  final bool hasHeldUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour =
        hasHeldUp ? InvAPColors.kErrorRedColor : InvAPColors.kSecondaryTextColor;

    return InkWell(
      key: const Key('queue-badge'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasHeldUp) ...[
              Icon(
                Icons.warning_amber_rounded,
                key: const Key('queue-badge-held-up-icon'),
                color: InvAPColors.kErrorRedColor,
                size: 14.sp,
              ),
              Gap(4.w),
            ] else ...[
              Icon(Icons.cloud_upload_outlined, color: colour, size: 14.sp),
              Gap(4.w),
            ],
            Text(
              '$count',
              key: const Key('queue-badge-count'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colour,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The queued orders, in the collapsible format the history page uses.
class _QueueDropdown extends StatelessWidget {
  const _QueueDropdown({
    required this.queue,
    required this.isOwner,
    required this.onRetry,
    required this.onDiscard,
    required this.onReenter,
  });

  final List<PendingSale> queue;
  final bool isOwner;
  final void Function(String queueId) onRetry;
  final void Function(String queueId) onDiscard;
  final void Function(String queueId) onReenter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final heldUp = queue.where((s) => s.heldUp).length;

    return Dialog(
      key: const Key('queue-dropdown'),
      alignment: Alignment.topRight,
      insetPadding: EdgeInsets.only(top: 80.h, right: 24.w, left: 24.w, bottom: 24.h),
      backgroundColor: InvAPColors.kAppBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640.w, maxHeight: 520.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 8.w, 10.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Queued sales',
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Gap(2.h),
                        Text(
                          heldUp > 0
                              ? '${queue.length} waiting · $heldUp need attention'
                              : '${queue.length} waiting to sync',
                          style: textTheme.bodySmall?.copyWith(
                            color: heldUp > 0
                                ? InvAPColors.kErrorRedColor
                                : InvAPColors.kSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 20.sp),
                    color: InvAPColors.kSecondaryTextColor,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                shrinkWrap: true,
                itemCount: queue.length,
                separatorBuilder: (_, _) => Gap(8.h),
                itemBuilder: (_, i) {
                  final sale = queue[i];
                  return PendingOrderCard(
                    sale: sale,
                    isOwner: isOwner,
                    onRetry: () => onRetry(sale.queueId),
                    onDiscard: () => onDiscard(sale.queueId),
                    onReenter: () => onReenter(sale.queueId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
