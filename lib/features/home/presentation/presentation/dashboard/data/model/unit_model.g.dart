// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => UnitModel(
  json['id'] as String?,
  json['type'] as String,
  json['barcode'] as String?,
  _toDouble(json['sellingPrice']),
  _toDouble(json['individualPieces']),
);

Map<String, dynamic> _$UnitModelToJson(UnitModel instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'barcode': instance.barcode,
  'sellingPrice': instance.sellingPrice,
  'individualPieces': instance.individualPieces,
};
