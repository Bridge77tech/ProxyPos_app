
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/sale_items_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sale_model.g.dart';

@JsonSerializable()
class SaleModel {
  final String? id;
  final String? saleNumber;
  final String? userId;
  final String? customerId;
  final String? totalAmount;
  final String? amountPaid;
  final String? changeGiven;
  final String? paymentMethod;
  final String? status;
  final String? saleDate;
  final String? deviceId;
  final String? syncStatus;
  final String? lastModified;
  final String? createdAt;
  final String? updatedAt;
  final List<SaleItemsModel>? items;

  SaleModel({
    this.id,
    this.saleNumber,
    this.userId,
    this.customerId,
    this.totalAmount,
    this.amountPaid,
    this.changeGiven,
    this.paymentMethod,
    this.status,
    this.saleDate,
    this.deviceId,
    this.syncStatus,
    this.lastModified,
    this.createdAt,
    this.updatedAt,
    this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) => _$SaleModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleModelToJson(this);
}
