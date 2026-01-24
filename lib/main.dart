import 'package:flutter/material.dart';

void main() {
  runApp(InventoryApp());
}


class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
    );
  }
}
