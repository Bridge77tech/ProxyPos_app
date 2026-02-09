// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Variants _$VariantsFromJson(Map<String, dynamic> json) => Variants(
  id: json['id'] as String?,
  size: json['size'] as String?,
  type: json['type'] as String?,
  unit: json['unit'] as String?,
  barcode: json['barcode'] as String?,
  costPrice: (json['costPrice'] as num?)?.toDouble(),
  packPrice: (json['packPrice'] as num?)?.toDouble(),
  currentStock: (json['currentStock'] as num?)?.toInt(),
  sellingPrice: (json['sellingPrice'] as num?)?.toDouble(),
  piecesPerPack: (json['piecesPerPack'] as num?)?.toInt(),
);

Map<String, dynamic> _$VariantsToJson(Variants instance) => <String, dynamic>{
  'id': instance.id,
  'size': instance.size,
  'type': instance.type,
  'unit': instance.unit,
  'barcode': instance.barcode,
  'costPrice': instance.costPrice,
  'packPrice': instance.packPrice,
  'currentStock': instance.currentStock,
  'sellingPrice': instance.sellingPrice,
  'piecesPerPack': instance.piecesPerPack,
};
