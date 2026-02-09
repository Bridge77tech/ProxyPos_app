import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/variant.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class Products {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'barcode')
  final String? barcode;

  @JsonKey(name: 'category')
  final String? category;

  @JsonKey(name: 'variants')
  final List<Variants>? variants;

  @JsonKey(name: 'currentStock')
  final String? currentStock;

  @JsonKey(name: 'miniStockLevel')
  final int? miniStockLevel;

  @JsonKey(name: 'imagePath')
  final String? imagePath;

  @JsonKey(name: "isActive")
  bool? isActive;

  @JsonKey(name: "totalSold")
  final String? totalSold;

  @JsonKey(name: "salesCount")
  final String? salesCount;

  Products({
    this.id,
    this.name,
    this.barcode,
    this.category,
    this.variants,
    this.currentStock,
    this.miniStockLevel,
    this.imagePath,
    this.isActive,
    this.totalSold,
    this.salesCount,
  });

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);

  Map<String, dynamic> toJson() => _$ProductsToJson(this);
}