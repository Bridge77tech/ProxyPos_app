// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Products _$ProductsFromJson(Map<String, dynamic> json) => Products(
  id: json['id'] as String?,
  name: json['name'] as String?,
  barcode: json['barcode'] as String?,
  category: json['category'] as String?,
  variants: (json['variants'] as List<dynamic>?)
      ?.map((e) => Variants.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentStock: json['currentStock'] as String?,
  miniStockLevel: (json['miniStockLevel'] as num?)?.toInt(),
  imagePath: json['imagePath'] as String?,
  isActive: json['isActive'] as bool?,
  totalSold: json['totalSold'] as String?,
  salesCount: json['salesCount'] as String?,
);

Map<String, dynamic> _$ProductsToJson(Products instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'barcode': instance.barcode,
  'category': instance.category,
  'variants': instance.variants?.map((e) => e.toJson()).toList(),
  'currentStock': instance.currentStock,
  'miniStockLevel': instance.miniStockLevel,
  'imagePath': instance.imagePath,
  'isActive': instance.isActive,
  'totalSold': instance.totalSold,
  'salesCount': instance.salesCount,
};
