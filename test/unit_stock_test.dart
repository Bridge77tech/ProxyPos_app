// Mirror of the server's `tests/unit-stock.test.js`, case for case.
//
// Both suites assert the same numbers because both codebases must agree on them — a till showing
// 21 packs where the portal shows 20 is worse than either being wrong alone. If a case is added
// on one side, add it on the other.
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/utils/unit_stock.dart';

void main() {
  group('itemsPerUnit', () {
    test('a single consumes one base item', () {
      expect(itemsPerUnit(1), 1);
    });

    test('a pack consumes its pack size', () {
      expect(itemsPerUnit(12), 12);
    });

    test('cannot say for a pack size that is null, zero, negative or fractional', () {
      expect(itemsPerUnit(null), isNull);
      expect(itemsPerUnit(0), isNull);
      expect(itemsPerUnit(-12), isNull);
      expect(itemsPerUnit(2.5), isNull);
    });

    test('accepts a whole number arriving as a double, which is how the model holds it', () {
      // UnitModel.individualPieces is a double via _toDouble, so 12 arrives as 12.0.
      expect(itemsPerUnit(12.0), 12);
    });
  });

  group('unitsAvailable', () {
    test('240 base units, 12 per pack -> 20', () {
      expect(unitsAvailable(12, 240), 20);
    });

    test('250 base units, 12 per pack -> 20, not 20.83', () {
      expect(unitsAvailable(12, 250), 20);
    });

    test('11 base units, 12 per pack -> 0', () {
      expect(unitsAvailable(12, 11), 0);
    });

    test('one short of two packs is still one', () {
      expect(unitsAvailable(12, 23), 1);
    });

    test('a single is the pool unchanged', () {
      expect(unitsAvailable(1, 240), 240);
      expect(unitsAvailable(1, 11), 11);
      expect(unitsAvailable(1, 0), 0);
    });

    test('the same pool reads differently per unit', () {
      expect(unitsAvailable(1, 240), 240);
      expect(unitsAvailable(6, 240), 40);
      expect(unitsAvailable(12, 240), 20);
    });

    test('an unexpressable pack returns null rather than throwing', () {
      expect(() => unitsAvailable(0, 240), returnsNormally);
      expect(unitsAvailable(0, 240), isNull);
    });

    test('negative, null and non-finite stock floor at 0', () {
      expect(unitsAvailable(12, -5), 0);
      expect(unitsAvailable(12, null), 0);
      expect(unitsAvailable(12, double.nan), 0);
      expect(unitsAvailable(12, double.infinity), 0);
      expect(unitsAvailable(1, -5), 0);
    });
  });

  group('unitLowThreshold — rounded UP', () {
    test('threshold 25, 12 per pack -> 3 packs, not 2', () {
      expect(unitLowThreshold(12, 25), 3);
    });

    test('threshold 5, 12 per pack -> 1 pack', () {
      expect(unitLowThreshold(12, 5), 1);
    });

    test('an exact multiple does not gain a spurious extra pack', () {
      expect(unitLowThreshold(12, 24), 2);
    });

    test('a single is the threshold unchanged', () {
      expect(unitLowThreshold(1, 25), 25);
    });

    test('zero stays zero', () {
      expect(unitLowThreshold(12, 0), 0);
      expect(unitLowThreshold(1, 0), 0);
    });

    test('an unexpressable pack returns null', () {
      expect(unitLowThreshold(null, 25), isNull);
    });
  });

  group('unitStockState — each unit judged in its own terms', () {
    test('a pack does not read low while its variant is comfortably stocked', () {
      // 20 packs against a threshold of 24 BASE units would read low on a full shelf.
      expect(
        unitStockState(individualPieces: 12, baseUnits: 240, baseThreshold: 24),
        UnitStockState.inStock,
      );
      expect(unitsAvailable(12, 240)! < 24, isTrue, reason: 'the naive comparison really was wrong');
    });

    test('a pack is out of stock below one whole pack, while the single is only low', () {
      // Crate Test Water: 11 bottles is zero twelve-packs, but 11 real bottles.
      expect(
        unitStockState(individualPieces: 12, baseUnits: 11, baseThreshold: 12),
        UnitStockState.outOfStock,
      );
      expect(
        unitStockState(individualPieces: 1, baseUnits: 11, baseThreshold: 12),
        UnitStockState.lowStock,
      );
    });

    test('a pack goes low against its own converted threshold', () {
      // Threshold 25 base -> 3 packs. 36 base is exactly 3 packs.
      expect(
        unitStockState(individualPieces: 12, baseUnits: 36, baseThreshold: 25),
        UnitStockState.lowStock,
      );
      expect(
        unitStockState(individualPieces: 12, baseUnits: 48, baseThreshold: 25),
        UnitStockState.inStock,
      );
    });

    test('an empty variant is out of stock in every unit', () {
      expect(
        unitStockState(individualPieces: 1, baseUnits: 0, baseThreshold: 10),
        UnitStockState.outOfStock,
      );
      expect(
        unitStockState(individualPieces: 12, baseUnits: 0, baseThreshold: 10),
        UnitStockState.outOfStock,
      );
    });

    test('with no threshold, only an empty shelf is flagged', () {
      expect(
        unitStockState(individualPieces: 12, baseUnits: 12, baseThreshold: 0),
        UnitStockState.inStock,
      );
      expect(
        unitStockState(individualPieces: 12, baseUnits: 11, baseThreshold: 0),
        UnitStockState.outOfStock,
      );
    });

    test('an unexpressable pack returns null so the caller can fall back', () {
      expect(
        unitStockState(individualPieces: null, baseUnits: 240, baseThreshold: 24),
        isNull,
      );
    });
  });

  group('agrees with the server on every documented case', () {
    // The table from tests/unit-stock.test.js. Kept as data so a divergence names itself.
    const cases = <List<num>>[
      // perPack, pool, expectedCount
      [12, 240, 20],
      [12, 250, 20],
      [12, 11, 0],
      [12, 23, 1],
      [6, 240, 40],
      [1, 240, 240],
      [1, 11, 11],
      [24, 240, 10],
    ];

    for (final c in cases) {
      test('${c[1]} base units at ${c[0]} per pack -> ${c[2]}', () {
        expect(unitsAvailable(c[0], c[1]), c[2]);
      });
    }

    const thresholds = <List<num>>[
      // perPack, baseThreshold, expectedThreshold
      [12, 25, 3],
      [12, 5, 1],
      [12, 24, 2],
      [1, 25, 25],
      [12, 0, 0],
    ];

    for (final c in thresholds) {
      test('threshold ${c[1]} at ${c[0]} per pack -> ${c[2]}', () {
        expect(unitLowThreshold(c[0], c[1]), c[2]);
      });
    }
  });
}
