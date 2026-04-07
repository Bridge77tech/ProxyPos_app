import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/sale_model.dart';
import 'package:inventory_app_pos/network/models/api_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sales_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SalesListModel extends APIResponse<SalesListModel> {
  @JsonKey(name: 'sales')
  final List<SaleModel>? sales;

  SalesListModel({this.sales});

  factory SalesListModel.fromJson(Map<String, dynamic> json) =>
      _$SalesListModelFromJson(json);

  @override
  SalesListModel fromJson(Map<String, dynamic> json) =>
      SalesListModel.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SalesListModelToJson(this);
}
