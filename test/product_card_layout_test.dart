// Does the product tile lay out at all when it has something to say about stock?
//
// It did not. The price row put the stock indicator — itself a Row — in as a plain child, and a
// Row hands its non-flex children UNBOUNDED main-axis constraints regardless of how wide the Row
// itself is. The inner Row defaulted to mainAxisSize.max, so it was asked to fill infinity, and
// its Flexible note had nothing to flex within.
//
// The result was a render box with no size. Hit testing a sizeless box throws, and the failure
// cascaded into mouse_tracker: clicks stopped working across the WHOLE till, not just this card.
// It surfaced after adding something to the cart, because that relaid the grid out.
//
// Two things this suite is careful about:
//
// The parent here is BOUNDED, deliberately — the same bounded tile the GridView gives each card.
// The fault was internal to the widget, and a test that reproduced it by using an unbounded parent
// would be testing a situation the app never creates.
//
// And the card must carry a stock note. Without one the inner Row has no Flexible child and the
// failure is quieter, so a card in the healthy-stock case is not evidence that the row is sound.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/app_theme/inv_theme.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/product_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/unit_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/variant.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/widgets/product_container_card.dart';

/// A 12-pack, as the grid would hand it in.
UnitModel _pack({double perPack = 12}) => UnitModel('unit-1', 'Pack', null, 55.0, perPack);
UnitModel _single() => UnitModel('unit-2', 'Single', null, 5.0, 1);

Variants _variant({
  required double stock,
  double threshold = 0,
  DateTime? expires,
}) =>
    Variants(
      id: 'variant-1',
      name: 'Bel Aqua',
      size: '500ml',
      type: 'Bottle',
      currentStock: stock,
      lowThresholdAlert: threshold,
      expiringDate: expires,
      units: [],
    );

Products _product() => Products(id: 'product-1', name: 'Bel Aqua', category: 'Beverages');

/// The card in the bounded tile a GridView gives it, at the size the till opens at.
Widget _harness({required Variants variant, required UnitModel unit}) {
  return ScreenUtilInit(
    designSize: const Size(1025, 768),
    useInheritedMediaQuery: true,
    builder: (context, _) => MaterialApp(
      theme: themeData(),
      home: Scaffold(
        body: Center(
          // The tile the GridView actually gives a card:
          // SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150.w,
          // childAspectRatio: 0.62). `.w`, not raw pixels — at the 800x600 the till opens at
          // against a 1025 design width that is about 117, which is narrower than 150 and so the
          // case that actually breaks.
          child: SizedBox(
            width: 150.w,
            height: 150.w / 0.62,
            child: ProductContainerCard(
              key: const Key('card'),
              product: _product(),
              variants: variant,
              unit: unit,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Laid out, with a real size, and nothing thrown while getting there.
void _expectLaidOut(WidgetTester tester) {
  expect(tester.takeException(), isNull);

  final size = tester.getSize(find.byKey(const Key('card')));
  expect(size.width, isNot(0));
  expect(size.height, isNot(0));
  expect(size.width.isFinite, isTrue);
  expect(size.height.isFinite, isTrue);

  // The specific failure: a render box that laid out with no size at all.
  final box = tester.renderObject<RenderBox>(find.byKey(const Key('card')));
  expect(box.hasSize, isTrue);
  expect(box.size.isEmpty, isFalse);
}

void main() {
  testWidgets('lays out when the stock is low, so the card carries a note', (tester) async {
    await tester.pumpWidget(_harness(
      // 24 bottles against a threshold of 240: low in this unit as well as in base units.
      variant: _variant(stock: 24, threshold: 240),
      unit: _pack(),
    ));
    await tester.pumpAndSettle();

    _expectLaidOut(tester);
    _expectLaidOut(tester);
  });

  testWidgets('lays out when the stock is expiring, which is the longest note', (tester) async {
    await tester.pumpWidget(_harness(
      variant: _variant(
        stock: 240,
        threshold: 12,
        expires: DateTime.now().add(const Duration(days: 3)),
      ),
      unit: _pack(),
    ));
    await tester.pumpAndSettle();

    _expectLaidOut(tester);
  });

  testWidgets('lays out when the stock is simply fine and there is no note', (tester) async {
    await tester.pumpWidget(_harness(
      variant: _variant(stock: 240, threshold: 12),
      unit: _pack(),
    ));
    await tester.pumpAndSettle();

    _expectLaidOut(tester);
  });

  testWidgets('lays out for a Single, where the count is the base pool', (tester) async {
    await tester.pumpWidget(_harness(
      variant: _variant(stock: 3, threshold: 10),
      unit: _single(),
    ));
    await tester.pumpAndSettle();

    _expectLaidOut(tester);
  });

  testWidgets('the card can be hit tested — the failure that killed clicks everywhere', (tester) async {
    await tester.pumpWidget(_harness(
      variant: _variant(stock: 24, threshold: 240, expires: DateTime.now().add(const Duration(days: 2))),
      unit: _pack(),
    ));
    await tester.pumpAndSettle();

    // A sizeless render box throws on hit test, and that throw is what cascaded into
    // mouse_tracker and took the rest of the UI's clicks with it. So press the card.
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('card'))));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
