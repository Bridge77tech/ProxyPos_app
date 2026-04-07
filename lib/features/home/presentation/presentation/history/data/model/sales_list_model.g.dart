// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesListModel _$SalesListModelFromJson(Map<String, dynamic> json) =>
    SalesListModel(
        sales: (json['sales'] as List<dynamic>?)
            ?.map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      ..message = json['message'] as String?
      ..statusCode = (json['statusCode'] as num?)?.toInt()
      ..token = json['token'] as String?;

Map<String, dynamic> _$SalesListModelToJson(SalesListModel instance) =>
    <String, dynamic>{
      'message': instance.message,
      'statusCode': instance.statusCode,
      'token': instance.token,
      'sales': instance.sales?.map((e) => e.toJson()).toList(),
    };
