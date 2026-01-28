import 'package:flutter/cupertino.dart';
import 'package:inventory_app_pos/features/home/presentation/main_layout.dart';
import 'package:inventory_app_pos/features/home/domain/main_layout_provider.dart';

Widget get mainLayOutlet {
  return MainLayoutProvider(
    child: APMainLayoutPage(),
  );
}