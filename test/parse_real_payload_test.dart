/// Parses a real production payload through ProductModel.
///
/// This existed because the app could not read its own server. UnitModel declared
///
///     final String barcode;
///
/// while the field's own comment said "Optional: loose or unpackaged goods have no barcode" — and
/// the server has always sent null for anything unscanned. json_serializable generated
/// `json['barcode'] as String`, which throws under sound null safety, so the first unit without a
/// barcode took the entire product list down with it.
///
/// It was invisible because the search handler catches everything and emits an empty result set, so
/// a total parse failure looked exactly like "no matches". At the time it was found, all thirteen
/// of one shop's units had null barcodes and three of another's four did.
///
/// The fixture is a genuine response, captured from production, rather than something written to
/// suit the model — a hand-made fixture would have had a barcode in it and proved nothing.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';

void main() {
  test('a real payload parses, nulls and all', () {
    final file = File('test/fixtures/pos_products_response.json');
    expect(file.existsSync(), isTrue, reason: 'payload.json fixture is missing');

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final model = ProductModel.fromJson(json);
    final products = model.products ?? const [];

    expect(products, isNotEmpty, reason: 'the server returned products; the model must keep them');

    // The specific shape that used to throw: a unit whose barcode is null.
    final units = products
        .expand((p) => p.variants ?? [])
        .expand((v) => v.units ?? [])
        .toList();
    expect(units, isNotEmpty);
    expect(
      units.any((u) => u.barcode == null),
      isTrue,
      reason: 'the fixture must contain a null barcode, or it is not testing the bug',
    );

    // The other shape that used to throw: a price the server sends as a string.
    //
    // Postgres returns DECIMAL as a string to preserve precision, so sellingPrice arrives as
    // "150.00". The model declared double and the generated cast demanded a num, which threw
    // "type 'String' is not a subtype of type 'num'".
    final raw = (((json['products'] as List).first
        as Map<String, dynamic>)['variants'] as List).first as Map<String, dynamic>;
    final rawPrice = (raw['units'] as List).first['sellingPrice'];
    expect(rawPrice, isA<String>(),
        reason: 'the fixture must carry a string price, or it is not testing the bug');

    final parsedPrice = products.first.variants!.first.units!.first.sellingPrice;
    // Parsed, not merely survived — a converter that silently returned 0 would pass a
    // "does it throw" test while pricing every sale at nothing.
    expect(parsedPrice, double.parse(rawPrice as String));
    expect(parsedPrice, greaterThan(0));

    // And the rest survives the round trip.
    for (final p in products) {
      expect(p.name, isNotNull);
      for (final v in p.variants ?? []) {
        expect(v.currentStock, isNotNull);
      }
    }
  });
}
