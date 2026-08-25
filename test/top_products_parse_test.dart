import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/product_model.dart';

/// `pos/products/top-products` adds two fields the plain product list does not
/// carry: totalSold and salesCount. Both come from Postgres aggregates — SUM()
/// and COUNT() over integer columns return bigint, and node-postgres renders
/// bigint as a JSON *string* to avoid losing precision on values no shop will
/// ever reach.
///
/// The generated parser read them as `as num?`, so a real response threw
/// "type 'String' is not a subtype of type 'num?'" and took the whole product
/// list down with it. The dashboard reported that as a failed load while the
/// products sat there perfectly fine, and search kept working because the
/// all-products endpoint has neither field.
///
/// The only fixture in this suite is an all-products response, which is how it
/// went unseen.
void main() {
  Map<String, dynamic> product(Object? totalSold, Object? salesCount) => {
        'id': 'p1',
        'name': 'Carnation Milk',
        'category': 'Beverages',
        'currentStock': 40,
        'isActive': true,
        'variants': const [],
        'totalSold': totalSold,
        'salesCount': salesCount,
      };

  test('reads the bigint aggregates Postgres sends as strings', () {
    final parsed = Products.fromJson(product('1234', '56'));
    expect(parsed.totalSold, 1234);
    expect(parsed.salesCount, 56);
  });

  test('still reads them when they arrive as plain numbers', () {
    final parsed = Products.fromJson(product(1234, 56));
    expect(parsed.totalSold, 1234);
    expect(parsed.salesCount, 56);
  });

  test('tolerates them being absent, as on the all-products endpoint', () {
    final parsed = Products.fromJson(product(null, null));
    expect(parsed.totalSold, isNull);
    expect(parsed.salesCount, isNull);
  });
}
