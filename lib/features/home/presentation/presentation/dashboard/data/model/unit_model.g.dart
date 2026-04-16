// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => UnitModel(
  json['type'] as String,
  json['barcode'] as String,
  _parseDouble(json['sellingPrice']),
  _parseDouble(json['individualPieces']),
);

Map<String, dynamic> _$UnitModelToJson(UnitModel instance) => <String, dynamic>{
  'type': instance.type,
  'barcode': instance.barcode,
  'sellingPrice': instance.sellingPrice,
  'individualPieces': instance.individualPieces,
};

// Handles APIs that return numeric fields as JSON strings (e.g. "10.50").
double _parseDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
