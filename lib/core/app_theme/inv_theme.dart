import 'package:flutter/material.dart';
import 'package:inventory_app_pos/core/app_constants/ap_colors.dart';

import 'inv_text_style.dart';

ThemeData themeData() {
  return ThemeData(
    brightness: Brightness.light,
    fontFamily: "Satoshi",
    splashFactory: NoSplash.splashFactory,
    primaryColor: InvAPColors.kPrimaryColor,
    scaffoldBackgroundColor: InvAPColors.kAppBackgroundColor,
    colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: InvAPColors.kPrimaryColor,
        onPrimary: InvAPColors.kWhiteColor,
        secondary: InvAPColors.kPrimaryColor,
        onSecondary: InvAPColors.kWhiteColor,
        error: Colors.red,
        onError: InvAPColors.kWhiteColor,
        surface: InvAPColors.kBlack100,
        onSurface: InvAPColors.kWhiteColor,
    ),
    textTheme: TextTheme(
      titleLarge: APTextStyle.titleBig,
      titleMedium: APTextStyle.titleMedium,
      titleSmall: APTextStyle.titleSmall,
      bodyLarge: APTextStyle.bodyBig,
      bodyMedium: APTextStyle.bodyMedium,
      bodySmall: APTextStyle.bodySmall,
    )
  );
}