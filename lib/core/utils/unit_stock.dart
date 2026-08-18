/// Stock counted in one unit rather than in base units.
///
/// ## This file is a mirror
///
/// It is a deliberate port of `unitsAvailable`, `unitLowThreshold` and `unitStockStatus` in the
/// server's `src/services/productService.js`. The two implementations must agree on every value,
/// especially the rounding directions, which go in opposite directions on purpose:
///
///   * counts  are FLOORED  — a partial pack cannot be sold
///   * thresholds are CEILED — warning early on stock is the safe error
///
/// `test/unit_stock_test.dart` mirrors `tests/unit-stock.test.js` case for case. If you change
/// anything here, change it there, and in both of those suites.
///
/// ## Why the till computes this at all
///
/// The server does send these figures per unit, but the card also needs the divisor locally to clamp
/// the quantity stepper, and the till runs against a Hive cache when the network is gone. One local
/// implementation used by everything beats a server value in some places and inline arithmetic in
/// others — that split is how three call sites came to read a stale category name.
library;

/// Base items one of this unit consumes: 1 for a single, the pack size for a pack.
///
/// Reads `individualPieces` rather than comparing the unit's type name, and that is load-bearing:
/// the server renames 'Pack' to 'Bulk' for this app (`legacyUnitTypes`), so any check against
/// 'Pack' here would classify every pack as a single and report the base-unit pool again — exactly
/// the bug this file exists to fix. `individualPieces` is already 1 for singles and the pack size
/// for packs, whatever the type is called on the wire.
///
/// Returns null when a pack cannot say, rather than throwing. Throwing would take out the whole
/// product grid to avoid mislabelling one card; the caller shows a dash instead.
int? itemsPerUnit(num? individualPieces) {
  final per = individualPieces;
  if (per == null) return null;
  // A pack size below one, or fractional, is not something to guess at.
  if (per < 1 || per != per.roundToDouble()) return null;
  return per.toInt();
}

/// Whole units that a pool of [baseUnits] can supply, or null when it cannot be expressed.
///
/// Floored: 250 bottles is 20 twelve-packs and 10 loose bottles, not 20.83 packs.
int? unitsAvailable(num? individualPieces, num? baseUnits) {
  final per = itemsPerUnit(individualPieces);
  if (per == null) return null;

  final pool = baseUnits ?? 0;
  if (pool <= 0 || pool.isNaN || pool.isInfinite) return 0;
  return (pool / per).floor();
}

/// A base-unit low threshold expressed in this unit, or null when it cannot be expressed.
///
/// Ceiled, so a threshold of 25 bottles is 3 twelve-packs rather than 2, and any non-zero threshold
/// converts to at least 1 instead of rounding away to 0 and silently disabling the warning.
/// A threshold of 0 stays 0 — that is a shop choosing no warning, not a rounding artefact.
int? unitLowThreshold(num? individualPieces, num? baseThreshold) {
  final per = itemsPerUnit(individualPieces);
  if (per == null) return null;

  final threshold = baseThreshold ?? 0;
  if (threshold <= 0 || threshold.isNaN || threshold.isInfinite) return 0;
  return (threshold / per).ceil();
}

/// The three states a unit's stock can be in, worst first.
enum UnitStockState { outOfStock, lowStock, inStock }

/// State of one unit, judged in that unit's own terms.
///
/// Both sides of the comparison are converted first. Comparing a pack count against a base-unit
/// threshold — 20 packs against a threshold of 24 bottles — reads low on a completely full shelf.
///
/// A pack is out of stock the moment it cannot supply one whole pack, even while the variant still
/// holds loose base units: 11 bottles genuinely is zero twelve-packs. The till says so, and the
/// refusal message is still the place that explains it in bottles.
///
/// Returns null when the unit cannot be expressed, so the caller can fall back to what it knows
/// about the variant rather than being handed a guess.
UnitStockState? unitStockState({
  required num? individualPieces,
  required num? baseUnits,
  required num? baseThreshold,
}) {
  final available = unitsAvailable(individualPieces, baseUnits);
  if (available == null) return null;

  if (available <= 0) return UnitStockState.outOfStock;

  final threshold = unitLowThreshold(individualPieces, baseThreshold) ?? 0;
  if (available <= threshold) return UnitStockState.lowStock;
  return UnitStockState.inStock;
}
