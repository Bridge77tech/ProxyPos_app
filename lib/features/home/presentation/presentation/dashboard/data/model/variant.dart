import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/unit_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'variant.g.dart';

@JsonSerializable(explicitToJson: true)
class Variants {
  @JsonKey(name: 'id')
  final String? id;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'size')
  final String? size;

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'units')
  final List<UnitModel>? units;

  @JsonKey(name: 'currentStock')
  final double? currentStock;

  Variants({
    this.id,
    this.name,
    this.size,
    this.type,
    this.units,
    this.currentStock,
  });

  factory Variants.fromJson(Map<String, dynamic> json) =>
      _$VariantsFromJson(json);

  Map<String, dynamic> toJson() => _$VariantsToJson(this);

  // Use the first unit's price as the default selling price.
  double? get sellingPrice => (units != null && units!.isNotEmpty)
      ? units!.first.sellingPrice
      : null;
}