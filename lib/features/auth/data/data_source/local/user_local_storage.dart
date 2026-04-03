
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter/cupertino.dart';
import 'package:inventory_app_pos/core/exceptions/local_storage_exception.dart';
import 'package:inventory_app_pos/data/local_storage_service_impl.dart';
import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:logger/logger.dart';

/// abstract interface for user local storage operations
abstract class IUserLocalStorage<T> {
  Future<void> clearStorage();

  Future<T?> getStorageData();

  Future<void> saveData(T data);
}

/// Base implementation of user local storage with common logic
/// This class provides reusable storage operations for different user data types
///
/// Type parameter [T] must be a class that can be stored in Hive
///
/// Usage:
/// ```dart
/// class UserProfileStorage extends BaseUserLocalStorage<UserProfile> {
///   UserProfileStorage() : super(
///     boxType: StorageBox.userProfile,
///     storageKey: 'user_profile',
///     loggerName: 'UserProfileStorage',
///   );
/// }
/// ```

abstract class BaseUserLocalStorage<T> implements IUserLocalStorage<T> {
  final StorageBox boxType;
  final String storageKey;
  @protected
  final Logger log;
  @protected
  final LocalStorageServiceImpl localStore;

  BaseUserLocalStorage({
    required this.boxType,
    required this.storageKey,
    required String loggerName,
    LocalStorageServiceImpl? localStoreService,
  }) : localStore = localStoreService ?? LocalStorageServiceImpl.instance,
       log = getLogger(loggerName);

  @override
  Future<void> saveData(T data) async {
    try {
      log.i('Saving data to $storageKey in ${boxType.name}');
      final box = await localStore.openBox<T>(boxType);
      await box.put(storageKey, data);
      log.d("Successfully saved data to $storageKey");
    } catch (e, stackTrace) {
      log.e(
          "Error saving data to $storageKey",
        error: e,
        stackTrace: stackTrace,
      );
      throw LocalStorageException(
        message: 'Error saving data to $storageKey: ${e.toString()}'
      );
    }
  }

  @override
  Future<T?> getStorageData() async {
    try {
      log.i('Getting data from $storageKey in ${boxType.name}');

      //   Open box if not already open (matches savedData and clearStorage behaviour)
      final box = await localStore.openBox<T>(boxType);
      return box.get(storageKey);
    } catch (e, stackTrace) {
      log.e(
        'Error retrieving data from $storageKey',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> clearStorage() async {
    try {
      log.i('Clearing data from $storageKey in ${boxType.name}');
      final box = await localStore.openBox<T>(boxType);
      await box.delete(storageKey);
      log.d("Successfully cleared data from $storageKey");
    } catch (e, stackTrace) {
      log.e(
        "Error clearing data from $storageKey",
        error: e,
        stackTrace: stackTrace,
      );
      throw LocalStorageException(
          message: 'Error clearing data from $storageKey: ${e.toString()}'
      );
    }
  }
}