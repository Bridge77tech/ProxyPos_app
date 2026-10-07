// Do the three boxes in the Add to Cart popup fill the dialog, the way they do in the design?
//
// They did not. Two things made the variant list narrower than the Item Name and Quantity
// boxes above and below it:
//
//   - the Column laid its children out with CrossAxisAlignment.start, so every child took its
//     own width. The other two boxes only looked full because each wraps a Row, and a Row
//     defaults to mainAxisSize.max; the variant list had nothing spanning it and shrank to its
//     longest row.
//   - its white surface was a Material INSIDE a padded Container, while the other two paint
//     their white on the padded Container itself. So even once it stretched, the card would
//     still have sat 10.w short on each side.
//
// The widths are compared to each other rather than to a hard-coded number: the point is that
// the three cards share one left and one right edge, whatever the dialog's width works out to.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/app_theme/inv_theme.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/product_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/product_sale_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/unit_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/variant.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/repo/create_sale_repo.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/usecases/create_sale_use_case.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/cart/cart_bloc.dart';
import 'package:inventory_app_pos/shared/app_bar/inside_overlay_dialog.dart';

/// The popup never submits a sale, so neither of these is ever called — CartBloc simply
/// refuses to be built without them.
class _UnusedAuth implements CreateSaleAuthReader {
  @override
  Future<String?> getToken() async => throw UnimplementedError();
}

class _UnusedRepo implements CreateSaleRepository {
  @override
  Future<ProductSaleModel> createSale({
    required String token,
    required Map<String, dynamic> payload,
  }) => throw UnimplementedError();
}

/// A product with two units on one variant, so the list has rows to lay out.
Products _product() => Products(
  id: 'product-1',
  name: 'Bel Aqua',
  category: 'Beverages',
  variants: [
    Variants(
      id: 'variant-1',
      name: 'Bel Aqua',
      size: '500ml',
      type: 'Bottle',
      currentStock: 240,
      lowThresholdAlert: 12,
      units: [
        UnitModel('unit-1', 'Pack', null, 55.0, 12),
        UnitModel('unit-2', 'Single', null, 5.0, 1),
      ],
    ),
  ],
);

/// The popup body under the constraints Utils.showOverlayDialog gives it: a 0.3.sw-wide
/// box, with the dialog's own scroll view around the content.
Widget _harness(CartBloc cart) => ScreenUtilInit(
  designSize: const Size(1025, 768),
  useInheritedMediaQuery: true,
  builder: (context, _) => MaterialApp(
    theme: themeData(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 0.3.sw,
          height: 0.8.sh,
          child: BlocProvider<CartBloc>.value(
            value: cart,
            child: SingleChildScrollView(
              child: InsideOverlay(products: _product()),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  late CartBloc cart;

  setUp(() {
    cart = CartBloc(
      createSaleUseCase: CreateSaleUseCase(_UnusedAuth(), _UnusedRepo()),
    );
  });

  tearDown(() => cart.close());

  testWidgets('the three cards fill the popup to the same width', (tester) async {
    await tester.pumpWidget(_harness(cart));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final itemName = tester.getRect(find.byKey(const Key('item-name-card')));
    final variants = tester.getRect(find.byKey(const Key('variant-card')));
    final quantity = tester.getRect(find.byKey(const Key('quantity-card')));

    expect(variants.width, itemName.width);
    expect(quantity.width, itemName.width);

    // Same edges, not merely the same width.
    expect(variants.left, itemName.left);
    expect(variants.right, itemName.right);
    expect(quantity.left, itemName.left);
    expect(quantity.right, itemName.right);
  });

  testWidgets('and they fill the dialog, less the popup padding', (tester) async {
    await tester.pumpWidget(_harness(cart));
    await tester.pumpAndSettle();

    final dialog = tester.getRect(
      find.ancestor(
        of: find.byType(InsideOverlay),
        matching: find.byType(SizedBox),
      ).first,
    );
    final card = tester.getRect(find.byKey(const Key('variant-card')));

    // InsideOverlay's own EdgeInsets.symmetric(horizontal: 20.w), and nothing else.
    expect(card.left - dialog.left, closeTo(20.w, 0.5));
    expect(dialog.right - card.right, closeTo(20.w, 0.5));
  });
}
