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

  @JsonKey(name: 'image')
  final String? imagePath;

  @JsonKey(name: 'units')
  final List<UnitModel>? units;

  @JsonKey(name: 'currentStock')
  final double? currentStock;

  /// The stock level at which this variant should be reordered, in base units.
  ///
  /// Sent by the server on every variant and previously dropped here, so the till had no idea
  /// anything was running low — the shop owner got an email while the person actually standing at
  /// the counter saw nothing.
  @JsonKey(name: 'lowThresholdAlert')
  final double? lowThresholdAlert;

  /// When this variant expires, if it is perishable. Null for anything that is not.
  ///
  /// Also sent and also dropped. Nothing stopped a cashier selling expired stock, and nothing told
  /// them it was expired.
  @JsonKey(name: 'expiringDate')
  final DateTime? expiringDate;

  /// The server's own verdict: 'in_stock', 'low_stock' or 'out_of_stock'.
  ///
  /// Preferred over comparing currentStock to lowThresholdAlert here, so the till and the portal
  /// cannot disagree about what "low" means.
  @JsonKey(name: 'stockStatus')
  final String? stockStatus;

  Variants({
    this.id,
    this.name,
    this.size,
    this.type,
    this.imagePath,
    this.units,
    this.currentStock,
    this.lowThresholdAlert,
    this.expiringDate,
    this.stockStatus,
  });

  factory Variants.fromJson(Map<String, dynamic> json) =>
      _$VariantsFromJson(json);

  Map<String, dynamic> toJson() => _$VariantsToJson(this);

  /// True when this variant is at or below its reorder level.
  ///
  /// Trusts the server's stockStatus when it is present and only falls back to comparing the two
  /// numbers when it is not, so one definition of "low" governs both apps.
  bool get isLowStock {
    if (stockStatus != null) return stockStatus == 'low_stock';
    final stock = currentStock, threshold = lowThresholdAlert;
    if (stock == null || threshold == null) return false;
    return stock <= threshold;
  }

  bool get isOutOfStock {
    if (stockStatus != null) return stockStatus == 'out_of_stock';
    return (currentStock ?? 0) <= 0;
  }

  /// True once the expiry date has passed. False when there is no date, which is most goods.
  bool get isExpired {
    final on = expiringDate;
    return on != null && on.isBefore(DateTime.now());
  }

  /// Within a week of expiring, but not yet expired — worth flagging, not worth blocking.
  bool get isExpiringSoon {
    final on = expiringDate;
    if (on == null || isExpired) return false;
    return on.difference(DateTime.now()).inDays <= 7;
  }

  // Use the first unit's price as the default selling price.
  double? get sellingPrice => (units != null && units!.isNotEmpty)
      ? units!.first.sellingPrice
      : null;
}