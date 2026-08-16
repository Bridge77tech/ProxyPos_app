import 'package:json_annotation/json_annotation.dart';

part 'unit_model.g.dart';

/// Reads a number that may arrive as a number or as a string.
///
/// Money is DECIMAL in Postgres, and Postgres returns DECIMAL as a *string* so that precision
/// survives the wire — `"150.00"`, not `150.0`. Sequelize passes that through untouched, so
/// sellingPrice has always been a string in the response while this model declared `double` and
/// json_serializable generated `(json['sellingPrice'] as num).toDouble()`.
///
/// That throws: "type 'String' is not a subtype of type 'num' in type cast". It took the whole
/// product list with it, and the search handler quietly turned the failure into an empty result
/// set — so the till showed no products and said nothing about why.
///
/// Fixed here rather than on the server: sending money as a string is the correct thing for the
/// server to do, and a client that accepts either representation is robust to both.
double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

@JsonSerializable(explicitToJson: true)
class UnitModel {
  /// Server-side id of this specific unit. Sent back on a sale as
  /// `variantUnitId` so the server knows exactly which unit was sold — needed
  /// once a variant carries more than one pack size, where `type` alone can't
  /// distinguish a 12-pack from a 24-pack.
  ///
  /// Nullable because product data cached by an older build won't contain it.
  final String? id;
  final String type;

  /// Optional: loose or unpackaged goods have no barcode.
  ///
  /// Nullable, which it always should have been — the comment said "optional" while the type said
  /// otherwise, and json_serializable generated `json['barcode'] as String`. In sound null safety
  /// that throws on null, so parsing a single unit without a barcode threw a TypeError that took
  /// the whole product list with it.
  ///
  /// The server has always sent null here for anything unscanned. At the time this was found,
  /// every one of Shop Test 2's thirteen units had a null barcode and three of My Shop's four did,
  /// so the failure was total rather than occasional — and invisible, because the search handler
  /// catches everything and emits an empty result set.
  final String? barcode;
  @JsonKey(fromJson: _toDouble)
  final double sellingPrice;
  // Same treatment, for the same reason: it costs nothing and the field is a count that a
  // future column change could just as easily deliver as a string.
  @JsonKey(fromJson: _toDouble)
  final double individualPieces;

  UnitModel(this.id, this.type, this.barcode, this.sellingPrice, this.individualPieces);

  factory UnitModel.fromJson(Map<String, dynamic> json) => _$UnitModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnitModelToJson(this);
}
