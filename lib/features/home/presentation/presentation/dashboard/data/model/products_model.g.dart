// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'products_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) =>
    ProductModel(
        products: (json['products'] as List<dynamic>?)
            ?.map((e) => Products.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..message = json['message'] as String?
      ..statusCode = (json['statusCode'] as num?)?.toInt()
      ..token = json['token'] as String?;

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'statusCode': instance.statusCode,
      'token': instance.token,
      'products': instance.products?.map((e) => e.toJson()).toList(),
    };
