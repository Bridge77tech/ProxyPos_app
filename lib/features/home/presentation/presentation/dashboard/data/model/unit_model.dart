import 'package:json_annotation/json_annotation.dart';

part 'unit_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UnitModel {
  final String type;
  final String barcode;
  final double sellingPrice;
  final double individualPieces;

  UnitModel(this.type, this.barcode, this.sellingPrice, this.individualPieces);

  factory UnitModel.fromJson(Map<String, dynamic> json) => _$UnitModelFromJson(json);

  Map<String, dynamic> toJson() => _$UnitModelToJson(this);
}