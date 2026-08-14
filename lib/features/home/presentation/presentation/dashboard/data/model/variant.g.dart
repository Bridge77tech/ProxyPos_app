// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Variants _$VariantsFromJson(Map<String, dynamic> json) => Variants(
  id: json['id'] as String?,
  name: json['name'] as String?,
  size: json['size'] as String?,
  type: json['type'] as String?,
  imagePath: json['image'] as String?,
  units: (json['units'] as List<dynamic>?)
      ?.map((e) => UnitModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentStock: (json['currentStock'] as num?)?.toDouble(),
  lowThresholdAlert: (json['lowThresholdAlert'] as num?)?.toDouble(),
  expiringDate: json['expiringDate'] == null
      ? null
      : DateTime.parse(json['expiringDate'] as String),
  stockStatus: json['stockStatus'] as String?,
);

Map<String, dynamic> _$VariantsToJson(Variants instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'size': instance.size,
  'type': instance.type,
  'image': instance.imagePath,
  'units': instance.units?.map((e) => e.toJson()).toList(),
  'currentStock': instance.currentStock,
  'lowThresholdAlert': instance.lowThresholdAlert,
  'expiringDate': instance.expiringDate?.toIso8601String(),
  'stockStatus': instance.stockStatus,
};
