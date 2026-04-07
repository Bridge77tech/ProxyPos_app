import 'dart:async';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:logger/logger.dart';

import '../usecases/all_product_use_case.dart';

class AllProductsSyncService {
  AllProductsSyncService(
    this._useCase, {
    Duration interval = const Duration(minutes: 30),
    this.onError,
  })  : _interval = interval,
        _log = getLogger('AllProductsSyncService');

  final GetAndCacheAllProductsUseCase _useCase;
  final Duration _interval;

  /// Optional callback invoked whenever a sync fails, so callers can react
  /// (e.g. show a banner, retry with back-off, etc.).
  final void Function(Object error, StackTrace st)? onError;

  final Logger _log;
  Timer? _timer;
  bool _isSyncing = false;

  bool get isRunning => _timer != null;

  /// Starts the periodic sync.
  ///
  /// If [runImmediately] is true an initial sync is awaited before the first
  /// timer tick fires, so callers can be sure the cache is warm on return.
  Future<void> start({
    bool runImmediately = true,
    String? search,
    String? category,
  }) async {
    if (_timer != null) return;

    _timer = Timer.periodic(
      _interval,
      (_) => _syncOnce(search: search, category: category),
    );
    _log.i('Sync started — interval: ${_interval.inMinutes}m');

    if (runImmediately) {
      await _syncOnce(search: search, category: category);
    }
  }

  /// Triggers an immediate out-of-band sync (e.g. after login or a barcode
  /// cache miss) without affecting the periodic schedule.
  Future<void> syncNow({String? search, String? category}) =>
      _syncOnce(search: search, category: category);

  Future<void> _syncOnce({String? search, String? category}) async {
    // Prevent overlapping syncs if a tick fires while one is still running.
    if (_isSyncing) {
      _log.w('Sync already in progress — skipping tick');
      return;
    }

    _isSyncing = true;
    try {
      _log.i('Syncing all products from remote...');
      await _useCase.call(search: search, category: category);
      _log.i('Sync completed successfully');
    } catch (e, st) {
      _log.e('Sync failed', error: e, stackTrace: st);
      onError?.call(e, st);
    } finally {
      _isSyncing = false;
    }
  }

  /// Cancels the timer and releases resources.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _log.i('Sync disposed');
  }
}
