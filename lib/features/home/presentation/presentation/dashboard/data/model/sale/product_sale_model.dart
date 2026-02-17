import 'sale_model.dart';
import 'package:inventory_app_pos/network/models/api_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_sale_model.g.dart';

/// Model representing the API response for a product sale.
///
/// Wraps a nullable [SaleModel] returned from the dashboard sale endpoint.
/// The [sale] field may be `null` when there is no sale data available or
/// when the response does not include a sale object, so callers must always
/// check for `null` before using it.
@JsonSerializable(explicitToJson: true)
class ProductSaleModel extends APIResponse<ProductSaleModel> {
  @JsonKey(name: 'sale')
  final SaleModel? sale;

  /// Creates a [ProductSaleModel] with an optional [sale] payload.
  ///
  /// The [sale] parameter is nullable to account for responses where sale
  /// details are not present. Consumers should handle the case where [sale]
  /// is `null` to avoid null dereference errors.
  ProductSaleModel({this.sale});

  factory ProductSaleModel.fromJson(Map<String, dynamic> json) => _$ProductSaleModelFromJson(json);

  @override
  ProductSaleModel fromJson(Map<String, dynamic> json) => ProductSaleModel.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProductSaleModelToJson(this);
}