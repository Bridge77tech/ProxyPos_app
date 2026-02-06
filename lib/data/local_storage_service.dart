import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

abstract class ILocalStorageService {
  Future<Box<T>> openBox<T>(StorageBox boxType);
}