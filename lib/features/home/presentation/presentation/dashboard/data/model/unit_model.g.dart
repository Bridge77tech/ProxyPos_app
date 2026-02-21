// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => UnitModel(
  json['type'] as String,
  json['barcode'] as String,
  (json['sellingPrice'] as num).toDouble(),
  (json['individualPieces'] as num).toDouble(),
);

Map<String, dynamic> _$UnitModelToJson(UnitModel instance) => <String, dynamic>{
  'type': instance.type,
  'barcode': instance.barcode,
  'sellingPrice': instance.sellingPrice,
  'individualPieces': instance.individualPieces,
};
