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
  // Prefer displayImage: the server resolves it to the variant's own picture or,
  // failing that, its category's — so the grid stays recognisable without a photo
  // for every item. Falls back to `image` for older cached payloads; the bundled
  // placeholder asset still covers the case where neither exists.
  imagePath: (json['displayImage'] ?? json['image']) as String?,
  units: (json['units'] as List<dynamic>?)
      ?.map((e) => UnitModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentStock: _parseDoubleOrNull(json['currentStock']),
);

Map<String, dynamic> _$VariantsToJson(Variants instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'size': instance.size,
  'type': instance.type,
  'image': instance.imagePath,
  'units': instance.units?.map((e) => e.toJson()).toList(),
  'currentStock': instance.currentStock,
};

// Handles APIs that return numeric fields as JSON strings.
double? _parseDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
