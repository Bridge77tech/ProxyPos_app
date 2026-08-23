// Does the badge's TAP survive the dashboard's real layout, at the real window sizes?
//
// queue_ui_test.dart mounts the indicators in a Center, which is the right place to test what the
// widget itself decides. It cannot catch what the surrounding layout does to it, and that is what
// went wrong: at the 800x600 the macOS build opens at (macos/Runner/Base.lproj/MainMenu.xib), the
// Cart header's left group took its natural width, overflowed the column by 29px, and put the badge
// outside its parent's bounds. Flutter paints an overflowing child anyway, so the badge looked
// perfectly normal — but hit testing stops at the parent, so the tap never reached the InkWell.
// A badge sitting there doing nothing is worse than no badge at all: it says the queue is fine.
//
// So this rebuilds the Cart header as dashboard.dart actually nests it, with the real theme and the
// real clear-cart asset — a plain Text and a placeholder box are both narrower than the real thing
// and hid the bug — and taps the badge at each size the till is used at. Only asserting "no
// overflow" would pass on a layout that clips the badge some other way; the assertion has to be
// that the tap lands.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/core/app_theme/inv_theme.dart';
import 'package:inventory_app_pos/generated/assets.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/pending_sales_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/queue/connection_queue_indicators.dart';

const _badge = Key('queue-badge');
const _dropdown = Key('queue-dropdown');

final _queue = [
  PendingSale(
    queueId: 'q1',
    payload: const {'idempotencyKey': 'q1'},
    total: 240,
    lines: const [
      PendingSaleLine(productName: 'Bottled Water', unitType: 'Pack', quantity: 2, unitPrice: 20),
    ],
  ),
];

/// The Cart header, nested as dashboard.dart nests it.
///
/// A mirror, not the page itself: APDashboardPage needs CartBloc, which reaches Hive on
/// construction, and there is no Hive harness in this suite. So the nesting here has to be kept in
/// step with dashboard.dart by hand — if that header's structure changes, change this with it, or
/// this test starts proving something about a layout the app no longer has.
Widget cartHeaderHarness() => ScreenUtilInit(
      // The app's own design size — lib/app.dart:32.
      designSize: const Size(1025, 768),
      builder: (_, _) => MaterialApp(
        theme: themeData(),
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                const Expanded(flex: 7, child: SizedBox.expand()),
                Gap(10.w),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (context) => Flexible(
                                      child: Text(
                                        InvAppConstants.kCart,
                                        style: Theme.of(context).textTheme.bodyLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Gap(10.w),
                                  ConnectionQueueIndicators(
                                    isOnline: false,
                                    queue: _queue,
                                    isOwner: false,
                                    onRetry: (_) {},
                                    onDiscard: (_) {},
                                    onReenter: (_) {},
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {},
                              child: Image.asset(Assets.iconsDeleteIcon, scale: 4.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

void main() {
  // A MacBook window, the design size itself, and 800x600 — which is not a hypothetical narrow
  // case but the size the macOS build actually opens at, and the one this failed at.
  for (final size in const [Size(1512, 982), Size(1025, 768), Size(800, 600)]) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('tapping the badge opens the queue at $label', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(cartHeaderHarness());
      await tester.pumpAndSettle();

      expect(find.byKey(_badge), findsOneWidget);

      // The badge has to be inside the header it lives in, or it cannot be tapped however it
      // looks. Asserted directly, because this is the thing that broke.
      final badge = tester.getRect(find.byKey(_badge));
      final header = tester.getRect(find.byType(Row).at(1));
      expect(badge.right, lessThanOrEqualTo(header.right + 0.01),
          reason: 'badge is painted outside the header at $label, so taps cannot reach it');

      await tester.tap(find.byKey(_badge));
      await tester.pumpAndSettle();

      expect(find.byKey(_dropdown), findsOneWidget,
          reason: 'tapping the badge must open the queue at $label');
    });
  }
}
