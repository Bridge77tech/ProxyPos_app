import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/product_model.dart';
import 'package:inventory_app_pos/network/models/api_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'products_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductModel extends APIResponse<ProductModel>{
  @JsonKey(name: 'products')
  final List<Products>? products;

  ProductModel({this.products});

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  @override
  ProductModel fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}