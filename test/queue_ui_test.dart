// Queue badge and dropdown behaviour.
//
// ConnectionQueueIndicators takes plain values — isOnline, the queue, isOwner and three callbacks —
// so these tests drive it directly with no bloc, no Hive and no connectivity singleton. The states
// this has to get right ARE the feature; testing them through three layers of plumbing would only
// add ways for the test to pass while the till is wrong.
//
// Every assertion is at the top level. Nothing sits inside an `if (found)` — an assertion in a
// branch that never runs is indistinguishable from a passing test.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/pending_sales_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/queue/connection_queue_indicators.dart';

const _badge = Key('queue-badge');
const _badgeCount = Key('queue-badge-count');
const _badgeTriangle = Key('queue-badge-held-up-icon');
const _orderTriangle = Key('queue-order-held-up-icon');
const _lineTriangle = Key('queue-line-held-up-icon');
const _orderHeader = Key('queue-order-header');
const _discard = Key('queue-action-discard');
const _reenter = Key('queue-action-reenter');
const _retry = Key('queue-action-retry');
const _confirmDialog = Key('queue-discard-confirm');
const _confirmAccept = Key('queue-discard-confirm-accept');

PendingSale sale({
  String id = 'q1',
  double total = 240,
  bool heldUp = false,
  String? lastError,
  List<PendingSaleLine> lines = const [
    PendingSaleLine(productName: 'Bottled Water', unitType: 'Pack', quantity: 2, unitPrice: 20),
    PendingSaleLine(productName: 'Coca Cola', unitType: 'Single', quantity: 1, unitPrice: 5),
  ],
}) =>
    PendingSale(
      queueId: id,
      payload: {'idempotencyKey': id, 'items': const <dynamic>[]},
      attempts: heldUp ? 3 : 0,
      heldUp: heldUp,
      lastError: lastError,
      total: total,
      lines: lines,
    );

/// Records what the widget asked the bloc to do, so "tapping does nothing" is checkable.
class Recorder {
  final List<String> retried = [];
  final List<String> discarded = [];
  final List<String> reentered = [];

  bool get isEmpty => retried.isEmpty && discarded.isEmpty && reentered.isEmpty;
}

Widget harness({
  required bool isOnline,
  required List<PendingSale> queue,
  bool isOwner = false,
  Recorder? recorder,
}) {
  final rec = recorder ?? Recorder();
  return ScreenUtilInit(
    designSize: const Size(1280, 800),
    builder: (_, _) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: ConnectionQueueIndicators(
            isOnline: isOnline,
            queue: queue,
            isOwner: isOwner,
            onRetry: rec.retried.add,
            onDiscard: rec.discarded.add,
            onReenter: rec.reentered.add,
          ),
        ),
      ),
    ),
  );
}

Future<void> openDropdown(WidgetTester tester) async {
  expect(find.byKey(_badge), findsOneWidget, reason: 'precondition: the badge must be there to tap');
  await tester.tap(find.byKey(_badge));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('queue-dropdown')), findsOneWidget,
      reason: 'precondition: the dropdown must have opened');
}

void main() {
  group('when the badge shows', () {
    testWidgets('online with an empty queue renders no badge', (tester) async {
      await tester.pumpWidget(harness(isOnline: true, queue: const []));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connection-indicator-online')), findsOneWidget,
          reason: 'the connection indicator is always shown');
      expect(find.byKey(_badge), findsNothing);
    });

    testWidgets('offline with queued sales shows the badge with the right count', (tester) async {
      await tester.pumpWidget(harness(
        isOnline: false,
        queue: [sale(id: 'a'), sale(id: 'b'), sale(id: 'c')],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connection-indicator-offline')), findsOneWidget);
      expect(find.byKey(_badge), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(_badgeCount)).data, '3');
    });

    testWidgets('back online and still draining keeps the badge', (tester) async {
      // Connectivity has returned but two sales have not gone yet. The badge must not vanish just
      // because the network came back.
      await tester.pumpWidget(harness(
        isOnline: true,
        queue: [sale(id: 'a'), sale(id: 'b')],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connection-indicator-online')), findsOneWidget);
      expect(find.byKey(_badge), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(_badgeCount)).data, '2');
    });

    testWidgets('a fully drained queue removes the badge', (tester) async {
      await tester.pumpWidget(harness(isOnline: true, queue: [sale(id: 'a')]));
      await tester.pumpAndSettle();
      expect(find.byKey(_badge), findsOneWidget, reason: 'precondition: badge present while queued');

      await tester.pumpWidget(harness(isOnline: true, queue: const []));
      await tester.pumpAndSettle();

      expect(find.byKey(_badge), findsNothing);
    });

    testWidgets('a held-up sale keeps the badge even when online, with the triangle',
        (tester) async {
      // The badge sitting there while online IS the signal. Hiding it on reconnect would restore
      // the original failure: takings stranded while the till looks normal.
      await tester.pumpWidget(harness(
        isOnline: true,
        queue: [sale(id: 'a', heldUp: true, lastError: '400: no stock')],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('connection-indicator-online')), findsOneWidget);
      expect(find.byKey(_badge), findsOneWidget);
      expect(find.byKey(_badgeTriangle), findsOneWidget);
    });

    testWidgets('a queue with nothing held up shows no triangle', (tester) async {
      await tester.pumpWidget(harness(isOnline: false, queue: [sale(id: 'a')]));
      await tester.pumpAndSettle();

      expect(find.byKey(_badge), findsOneWidget, reason: 'precondition');
      expect(find.byKey(_badgeTriangle), findsNothing);
    });
  });

  group('the triangle appears at both levels', () {
    testWidgets('on the collapsed order row and on the affected line when expanded',
        (tester) async {
      await tester.pumpWidget(harness(
        isOnline: true,
        queue: [
          sale(
            id: 'a',
            heldUp: true,
            // The server names the product it refused, so the line can be identified.
            lastError: '400: Insufficient stock for Bottled Water - 500ml',
          )
        ],
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);

      // Level one: the collapsed order row.
      expect(find.byKey(_orderTriangle), findsOneWidget);
      expect(find.byKey(_lineTriangle), findsNothing,
          reason: 'precondition: lines are not rendered until the row is expanded');

      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      // Level two: the affected line item, and only that one.
      expect(find.byKey(_lineTriangle), findsOneWidget);
      expect(find.text('Bottled Water'), findsOneWidget);
      expect(find.text('Coca Cola'), findsOneWidget,
          reason: 'the unaffected line is still listed, just unmarked');
    });

    testWidgets('when the reason names no line, every line is marked rather than none',
        (tester) async {
      await tester.pumpWidget(harness(
        isOnline: true,
        queue: [sale(id: 'a', heldUp: true, lastError: 'HTTP 500')],
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);
      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      // Saying nothing would contradict the badge that sent the cashier looking.
      expect(find.byKey(_lineTriangle), findsNWidgets(2));
    });

    testWidgets('an order that is merely waiting carries no triangle anywhere', (tester) async {
      await tester.pumpWidget(harness(isOnline: false, queue: [sale(id: 'a')]));
      await tester.pumpAndSettle();
      await openDropdown(tester);

      expect(find.byKey(_orderTriangle), findsNothing);

      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      expect(find.byKey(_lineTriangle), findsNothing);
    });
  });

  group('permissions', () {
    testWidgets('a cashier sees Discard and Re-enter greyed, disabled and labelled Admin only',
        (tester) async {
      final rec = Recorder();
      await tester.pumpWidget(harness(
        isOnline: false,
        queue: [sale(id: 'a')],
        isOwner: false,
        recorder: rec,
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);
      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      // Shown, not hidden — a cashier must be able to see the options exist.
      expect(find.byKey(_discard), findsOneWidget);
      expect(find.byKey(_reenter), findsOneWidget);

      // Disabled at the button, not merely guarded inside the callback.
      expect(tester.widget<TextButton>(find.byKey(_discard)).onPressed, isNull);
      expect(tester.widget<TextButton>(find.byKey(_reenter)).onPressed, isNull);

      // And labelled, so the cashier knows who to ask rather than assuming a broken till.
      expect(find.byTooltip('Admin only'), findsNWidgets(2));

      // Tapping does nothing at all.
      await tester.tap(find.byKey(_discard), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_reenter), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(rec.discarded, isEmpty);
      expect(rec.reentered, isEmpty);
      expect(find.byKey(_confirmDialog), findsNothing,
          reason: 'no confirmation may even be offered to a cashier');
    });

    testWidgets('a cashier can still retry, which cannot double-charge', (tester) async {
      final rec = Recorder();
      await tester.pumpWidget(harness(
        isOnline: true,
        queue: [sale(id: 'a', heldUp: true, lastError: 'HTTP 500')],
        isOwner: false,
        recorder: rec,
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);
      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(find.byKey(_retry)).onPressed, isNotNull,
          reason: 'retry is safe for everyone — the payload keeps its idempotency key');

      await tester.tap(find.byKey(_retry));
      await tester.pumpAndSettle();

      expect(rec.retried, ['a']);
    });

    testWidgets('an owner sees Discard and Re-enter enabled and unlabelled', (tester) async {
      await tester.pumpWidget(harness(
        isOnline: false,
        queue: [sale(id: 'a')],
        isOwner: true,
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);
      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(find.byKey(_discard)).onPressed, isNotNull);
      expect(tester.widget<TextButton>(find.byKey(_reenter)).onPressed, isNotNull);
      expect(find.byTooltip('Admin only'), findsNothing);
    });

    testWidgets('an owner re-entering removes it and asks for a manual re-ring', (tester) async {
      final rec = Recorder();
      await tester.pumpWidget(harness(
        isOnline: false,
        queue: [sale(id: 'a')],
        isOwner: true,
        recorder: rec,
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);
      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_reenter));
      await tester.pumpAndSettle();

      expect(rec.reentered, ['a']);
    });
  });

  group('discarding requires confirmation that names the amount', () {
    testWidgets('nothing happens until the confirmation is accepted', (tester) async {
      final rec = Recorder();
      await tester.pumpWidget(harness(
        isOnline: false,
        queue: [sale(id: 'a', total: 240)],
        isOwner: true,
        recorder: rec,
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);
      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_discard));
      await tester.pumpAndSettle();

      // The dialog is up and the sale is untouched.
      expect(find.byKey(_confirmDialog), findsOneWidget);
      expect(rec.discarded, isEmpty, reason: 'opening the dialog must not act');

      // The amount is named inside the CONFIRMATION, not merely somewhere on screen — scoped to
      // the dialog because the order card behind it shows the total too, and the requirement is
      // that the thing being agreed to states what is being destroyed.
      expect(
        find.descendant(
          of: find.byKey(_confirmDialog),
          matching: find.textContaining('GHC 240.00'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(_confirmAccept));
      await tester.pumpAndSettle();

      expect(rec.discarded, ['a']);
    });

    testWidgets('declining the confirmation leaves the sale alone', (tester) async {
      final rec = Recorder();
      await tester.pumpWidget(harness(
        isOnline: false,
        queue: [sale(id: 'a', total: 99.5)],
        isOwner: true,
        recorder: rec,
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);
      await tester.tap(find.byKey(_orderHeader));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_discard));
      await tester.pumpAndSettle();
      expect(find.byKey(_confirmDialog), findsOneWidget, reason: 'precondition');
      expect(
        find.descendant(
          of: find.byKey(_confirmDialog),
          matching: find.textContaining('GHC 99.50'),
        ),
        findsOneWidget,
        reason: 'the amount must be the real total, to the pesewa, not a rounded one',
      );

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(rec.discarded, isEmpty);
    });
  });

  group('the dropdown lists the queue', () {
    testWidgets('one card per queued sale, held-up ones summarised in the header', (tester) async {
      await tester.pumpWidget(harness(
        isOnline: true,
        queue: [
          sale(id: 'a', heldUp: true, lastError: 'HTTP 500'),
          sale(id: 'b'),
          sale(id: 'c'),
        ],
      ));
      await tester.pumpAndSettle();
      await openDropdown(tester);

      expect(find.byKey(_orderHeader), findsNWidgets(3));
      expect(find.textContaining('need attention'), findsOneWidget);
    });
  });
}
