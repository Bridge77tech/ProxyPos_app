// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaleModel _$SaleModelFromJson(Map<String, dynamic> json) => SaleModel(
  id: json['id'] as String?,
  saleNumber: json['saleNumber'] as String?,
  userId: json['userId'] as String?,
  customerId: json['customerId'] as String?,
  totalAmount: json['totalAmount'] as String?,
  amountPaid: json['amountPaid'] as String?,
  changeGiven: json['changeGiven'] as String?,
  paymentMethod: json['paymentMethod'] as String?,
  status: json['status'] as String?,
  saleDate: json['saleDate'] as String?,
  deviceId: json['deviceId'] as String?,
  syncStatus: json['syncStatus'] as String?,
  lastModified: json['lastModified'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => SaleItemsModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SaleModelToJson(SaleModel instance) => <String, dynamic>{
  'id': instance.id,
  'saleNumber': instance.saleNumber,
  'userId': instance.userId,
  'customerId': instance.customerId,
  'totalAmount': instance.totalAmount,
  'amountPaid': instance.amountPaid,
  'changeGiven': instance.changeGiven,
  'paymentMethod': instance.paymentMethod,
  'status': instance.status,
  'saleDate': instance.saleDate,
  'deviceId': instance.deviceId,
  'syncStatus': instance.syncStatus,
  'lastModified': instance.lastModified,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'items': instance.items,
};
