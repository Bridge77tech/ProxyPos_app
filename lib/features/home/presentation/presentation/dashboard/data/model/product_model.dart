import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/variant.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable(explicitToJson: true)
class Products {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'category')
  final String? category;

  @JsonKey(name: 'variants')
  final List<Variants>? variants;

  @JsonKey(name: 'currentStock')
  final int? currentStock;

  @JsonKey(name: 'minStockLevel')
  final int? minStockLevel;

  @JsonKey(name: 'isActive')
  final bool? isActive;

  @JsonKey(name: 'totalSold')
  final int? totalSold;

  @JsonKey(name: 'salesCount')
  final int? salesCount;

  Products({
    this.id,
    this.name,
    this.category,
    this.variants,
    this.currentStock,
    this.minStockLevel,
    this.isActive,
    this.totalSold,
    this.salesCount,
  });

  factory Products.fromJson(Map<String, dynamic> json) =>
      _$ProductsFromJson(json);

  Map<String, dynamic> toJson() => _$ProductsToJson(this);
}