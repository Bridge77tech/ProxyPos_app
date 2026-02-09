import 'package:json_annotation/json_annotation.dart';

part 'variant.g.dart';

@JsonSerializable(explicitToJson: true)
class Variants {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'size')
  final String? size;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'unit')
  final String? unit;

  @JsonKey(name: 'barcode')
  final String? barcode;

  @JsonKey(name: 'costPrice')
  final double? costPrice;

  @JsonKey(name: 'packPrice')
  final double? packPrice;

  @JsonKey(name: 'currentStock')
  final int? currentStock;

  @JsonKey(name: 'sellingPrice')
  final double? sellingPrice;

  @JsonKey(name: 'piecesPerPack')
  final int? piecesPerPack;

  Variants({
    this.id,
    this.size,
    this.type,
    this.unit,
    this.barcode,
    this.costPrice,
    this.packPrice,
    this.currentStock,
    this.sellingPrice,
    this.piecesPerPack,
  });

  factory Variants.fromJson(Map<String, dynamic> json) =>
      _$VariantsFromJson(json);

  Map<String, dynamic> toJson() => _$VariantsToJson(this);
}