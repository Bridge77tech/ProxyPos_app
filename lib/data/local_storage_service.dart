import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

abstract class ILocalStorageService {
  Future<void> init();

  Future<Box<T>> openBox<T>(StorageBox boxType);

  Box<T> getBox<T>(String boxName);

  bool isBoxOpen(String boxName);

  Future<void> closeBox(String boxName);

  Future<void> dispose();
}