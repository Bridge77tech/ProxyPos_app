import 'package:flutter/material.dart';
import 'package:inventory_app_pos/core/services/connectivity_service.dart';
import 'package:inventory_app_pos/data/local_storage_service_impl.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageServiceImpl.instance.init();
  await ConnectivityService.instance.initialize();
  runApp(InventoryApp());
}