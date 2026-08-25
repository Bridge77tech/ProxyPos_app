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

  @JsonKey(name: 'totalSold', fromJson: _countFromJson)
  final int? totalSold;

  @JsonKey(name: 'salesCount', fromJson: _countFromJson)
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

/// Reads a count that may arrive as a number or as a string.
///
/// totalSold and salesCount are Postgres aggregates — SUM() and COUNT() over
/// integer columns return bigint, and node-postgres renders bigint as a JSON
/// string rather than risk losing precision. The generated `as num?` cast threw
/// on every real top-products response, and because one bad field aborts the
/// whole list parse, the dashboard reported "products unavailable" for a
/// catalogue that was entirely intact.
///
/// The backend now casts these to integer, so this is the belt to that braces:
/// a till in the field ships through an app store and has to keep reading
/// whatever a not-yet-updated backend sends it.
int? _countFromJson(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  return null;
}
