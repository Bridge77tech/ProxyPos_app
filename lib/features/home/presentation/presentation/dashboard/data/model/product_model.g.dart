// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Products _$ProductsFromJson(Map<String, dynamic> json) => Products(
  id: json['id'] as String?,
  name: json['name'] as String?,
  category: json['category'] as String?,
  variants: (json['variants'] as List<dynamic>?)
      ?.map((e) => Variants.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentStock: (json['currentStock'] as num?)?.toInt(),
  minStockLevel: (json['minStockLevel'] as num?)?.toInt(),
  isActive: json['isActive'] as bool?,
  totalSold: _countFromJson(json['totalSold']),
  salesCount: _countFromJson(json['salesCount']),
);

Map<String, dynamic> _$ProductsToJson(Products instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category': instance.category,
  'variants': instance.variants?.map((e) => e.toJson()).toList(),
  'currentStock': instance.currentStock,
  'minStockLevel': instance.minStockLevel,
  'isActive': instance.isActive,
  'totalSold': instance.totalSold,
  'salesCount': instance.salesCount,
};
