// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_items_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleItemsModel _$SaleItemsModelFromJson(Map<String, dynamic> json) =>
    SaleItemsModel(
      id: json['id'] as String?,
      saleId: json['saleId'] as String?,
      productId: json['productId'] as String?,
      variantId: json['variantId'] as String?,
      productName: json['productName'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      saleType: json['saleType'] as String?,
      unitPrice: json['unitPrice'] as String?,
      costPrice: json['costPrice'] as String?,
      subtotal: json['subtotal'] as String?,
      profit: json['profit'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$SaleItemsModelToJson(SaleItemsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'saleId': instance.saleId,
      'productId': instance.productId,
      'variantId': instance.variantId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'saleType': instance.saleType,
      'unitPrice': instance.unitPrice,
      'costPrice': instance.costPrice,
      'subtotal': instance.subtotal,
      'profit': instance.profit,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
