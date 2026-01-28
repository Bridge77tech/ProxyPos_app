import 'package:flutter/material.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';

class APTextStyle {
  APTextStyle._();

  static TextStyle titleBig = const TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: InvAPColors.kPrimaryTextColor,
  );

  static TextStyle titleMedium = const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: InvAPColors.kPrimaryTextColor,
  );

  static TextStyle titleSmall = const TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w500,
    color: InvAPColors.kPrimaryTextColor,
  );

  static TextStyle headerSmall = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: InvAPColors.kPrimaryTextColor,
  );

  static TextStyle bodyBig = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: InvAPColors.kPrimaryTextColor,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: InvAPColors.kPrimaryTextColor,
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: InvAPColors.kPrimaryTextColor,
  );
}