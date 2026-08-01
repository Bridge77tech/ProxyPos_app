// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnitModel _$UnitModelFromJson(Map<String, dynamic> json) => UnitModel(
  json['id'] as String?,
  json['type'] as String,
  // Barcode is optional server-side; coerce null to '' so a unit without one
  // (loose goods) can't crash the catalogue parse.
  json['barcode'] as String? ?? '',
  _parseDouble(json['sellingPrice']),
  _parseDouble(json['individualPieces']),
);

Map<String, dynamic> _$UnitModelToJson(UnitModel instance) => <String, dynamic>{
  'id': instance.id,
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
