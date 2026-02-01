import 'dart:convert';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:inventory_app_pos/data/local_storage_service.dart';
import 'package:inventory_app_pos/data/storage_box.dart';

import '../core/exceptions/local_storage_exception.dart';

class LocalStorageServiceImpl implements ILocalStorageService {
  static final instance = LocalStorageServiceImpl._();
  final _log = getLogger('LocalStorageServiceImpl');

  final FlutterSecureStorage _secureStorage;
  final HiveInterface _hive;
  final Map<String, Box> _openBoxes = {};

  LocalStorageServiceImpl._({
    FlutterSecureStorage? secureStorage,
    HiveInterface? hive,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _hive = hive ?? Hive;

  // factory constructor for testing
  factory LocalStorageServiceImpl.forTesting({
    required FlutterSecureStorage secureStorage,
    required HiveInterface hive,
  }) {
    return LocalStorageServiceImpl._(secureStorage: secureStorage, hive: hive);
  }

  List<int>? _encryptionKey;
  // AndroidOptions encryptedSharedPreferences is deprecated; use default options.
  static const AndroidOptions _androidOptions = AndroidOptions();
  static const IOSOptions _iOSOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  @override
  Future<void> init() async {
    final isProductionHive = _hive == Hive;

    if (isProductionHive) {
      await Hive.initFlutter();
      // Note: registerAdapter should be called with specific adapters. Do this in app startup where adapters are known.
    }

    _encryptionKey = await _getOrGenerateEncryptionKey();
  }

  @override
  Future<Box<T>> openBox<T>(StorageBox boxType) async {
    if (_hive.isBoxOpen(boxType.name)) {
      final box = _hive.box<T>(boxType.name);

      _openBoxes[boxType.name] = box;
      _log.i("Reusing box: ${boxType.name} as Box<$T>");
      return box;
    } else {
      final encryptionCipher = boxType.isEncrypted
          ? (_encryptionKey != null ? HiveAesCipher(_encryptionKey!) : null)
          : null;

      final box = await _hive.openBox<T>(
        boxType.name,
        encryptionCipher: encryptionCipher,
      );
      _openBoxes[boxType.name] = box;
      _log.i("Opening box: ${boxType.name} as Box<$T>");
      return box;
    }
  }

  // check if a box is already open
  @override
  bool isBoxOpen(String boxName) {
    // Check Hive's state as the source of truth
    final isOpen = _hive.isBoxOpen(boxName);

    // sync cache if Hive knows about the box but cache doesn't
    if (isOpen && !_openBoxes.containsKey(boxName)) {
      try {
        _openBoxes[boxName] = _hive.box(boxName);
      } catch (e, s) {
        _log.e(e.toString(), stackTrace: s);
      }
    }

    return isOpen;
  }

  // Get an already opened box
  // Throws an exception if the box is not open
  @override
  Box<T> getBox<T>(String boxName) {
    final cached = _openBoxes[boxName];
    if (cached != null) {
      return cached as Box<T>;
    }

    if (!_hive.isBoxOpen(boxName)) {
      _log.e('Box "$boxName" is not open. Call openBox first.');
      throw LocalStorageException(message: 'Box "$boxName" is not open.');
    }

    final box = _hive.box<T>(boxName);
    _openBoxes[boxName] = box;
    return box;
  }

  Future<List<int>?> _getOrGenerateEncryptionKey() async {
    const keyName = 'hive_encryption_key';

    try {
      final base64Key = await _secureStorage.read(
        key: keyName,
        aOptions: _androidOptions,
        iOptions: _iOSOptions,
      );

      if (base64Key != null) {
        try {
          final keyBytes = base64Decode(base64Key);

          const secureKeySize = 32;
          if (keyBytes.length == secureKeySize) {
            return keyBytes;
          } else {
            await _secureStorage.delete(
              key: keyName,
              aOptions: _androidOptions,
              iOptions: _iOSOptions,
            );
          }
        } catch (e) {
          _log.e(e.toString());
          await _secureStorage.delete(
            key: keyName,
            aOptions: _androidOptions,
            iOptions: _iOSOptions,
          );
        }
      }

      final newKeyBytes = Hive.generateSecureKey();
      final newBase64Key = base64Encode(newKeyBytes);

      await _secureStorage.write(
        key: keyName,
        value: newBase64Key,
        aOptions: _androidOptions,
        iOptions: _iOSOptions,
      );

      return newKeyBytes;
    } on PlatformException catch (e) {
      // macOS requires keychain-access-groups entitlement which needs signing
      // Fall back to no encryption if secure storage is not available
      _log.w(
        'Secure storage not available (${e.code}): ${e.message}. '
        'Proceeding without encryption key. '
        'To enable encryption, add keychain entitlements and enable signing.',
      );
      return null;
    }
  }

  /// Cleanup method for app shutdown
  /// Closes all open boxes and clears the cache
  @override
  Future<void> dispose() async {
    for (final box in _openBoxes.values) {
      if (box.isOpen) {
        await box.close();
      }
    }
    _openBoxes.clear();
  }

  /// Close a specific box
  /// Useful for testing or when you need to explicitly close a box
  @override
  Future<void> closeBox(String boxName) async {
    if (_openBoxes.containsKey(boxName)) {
      final box = _openBoxes[boxName];
      if (box?.isOpen ?? false) {
        await box!.close();
      }
      _openBoxes.remove(boxName);
    }
  }
}
