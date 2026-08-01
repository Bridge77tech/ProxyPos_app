import 'package:json_annotation/json_annotation.dart';

part 'unit_model.g.dart';

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
  final String barcode;
  final double sellingPrice;
  final double individualPieces;

  UnitModel(this.id, this.type, this.barcode, this.sellingPrice, this.individualPieces);

  factory UnitModel.fromJson(Map<String, dynamic> json) => _$UnitModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnitModelToJson(this);
}
