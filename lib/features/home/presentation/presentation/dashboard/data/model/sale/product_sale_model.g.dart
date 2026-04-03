// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductSaleModel _$ProductSaleModelFromJson(Map<String, dynamic> json) =>
    ProductSaleModel(
        sale: json['sale'] == null
            ? null
            : SaleModel.fromJson(json['sale'] as Map<String, dynamic>),
      )
      ..message = json['message'] as String?
      ..statusCode = (json['statusCode'] as num?)?.toInt()
      ..token = json['token'] as String?;

Map<String, dynamic> _$ProductSaleModelToJson(ProductSaleModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'statusCode': instance.statusCode,
      'token': instance.token,
      'sale': instance.sale?.toJson(),
    };
