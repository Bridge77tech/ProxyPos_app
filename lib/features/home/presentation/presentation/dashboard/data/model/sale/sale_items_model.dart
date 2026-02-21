import 'package:json_annotation/json_annotation.dart';


part 'sale_items_model.g.dart';


@JsonSerializable()
class SaleItemsModel {
  final String? id;
  final String? saleId;
  final String? productId;
  final String? variantId;
  final String? productName;
  final int? quantity;
  final String? unit;
  final String? unitPrice;
  final String? costPrice;
  final String? subtotal;
  final String? profit;
  final String? createdAt;
  final String? updatedAt;

  SaleItemsModel({
    this.id,
    this.saleId,
    this.productId,
    this.variantId,
    this.productName,
    this.quantity,
    this.unit,
    this.unitPrice,
    this.costPrice,
    this.subtotal,
    this.profit,
    this.createdAt,
    this.updatedAt,
  });

  factory SaleItemsModel.fromJson(Map<String, dynamic> json) => _$SaleItemsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleItemsModelToJson(this);
}