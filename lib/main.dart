import 'package:flutter/material.dart';
import 'package:inventory_app_pos/core/services/connectivity_service.dart';
import 'package:inventory_app_pos/data/local_storage_service_impl.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocalStorageServiceImpl.instance.init();
  ConnectivityService.instance.initialize();
  runApp(InventoryApp());
}