import 'dart:async';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import '../usecases/all_product_use_case.dart';

class AllProductsSyncService {
  AllProductsSyncService(this._useCase, {Duration interval = const Duration(minutes: 30)})
      : _interval = interval,
        _log = getLogger('AllProductsSyncService');

  final GetAndCacheAllProductsUseCase _useCase;
  final Duration _interval;
  final _log;

  Timer? _timer;
  bool get isRunning => _timer != null;

  /// Starts the periodic sync. If [runImmediately] is true, performs a sync right away.
  void start({bool runImmediately = true, String? search, String? category}) {
    if (_timer != null) return; // already running

    if (runImmediately) {
      _syncOnce(search: search, category: category);
    }

    _timer = Timer.periodic(_interval, (_) => _syncOnce(search: search, category: category));
    _log.i('All products sync started with interval: ${_interval.inMinutes} minutes');
  }

  Future<void> _syncOnce({String? search, String? category}) async {
    try {
      _log.i('Syncing all products from remote...');
      await _useCase.call(search: search, category: category);
      _log.i('All products sync completed');
    } catch (e, st) {
      _log.e('All products sync failed', error: e, stackTrace: st);
    }
  }

  /// Stops the periodic sync.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _log.i('All products sync stopped');
  }
}
