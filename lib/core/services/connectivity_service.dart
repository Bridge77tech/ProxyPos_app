import 'dart:async';

import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:inventory_app_pos/network/constants/api_string_const.dart';
import 'package:logger/logger.dart';

/// Centralized network connectivity service for foreground operations.
///
/// Used by:
/// - SyncManager (foreground sync)
/// - BeneficiaryLookupService (graceful offline degradation)
/// - UI indicators (online/offline status)
///
/// Note: Background sync (WorkManager) does NOT need this service -
/// it uses Constraints(networkType: NetworkType.connected) instead.
class ConnectivityService {
  final Logger _log;
  final InternetConnection _connectionChecker;

  StreamSubscription<InternetStatus>? _subscription;
  final StreamController<bool> _connectivityController =
  StreamController<bool>.broadcast(sync: false);

  bool _isOnline = false;

  /// The question this service actually needs answered.
  ///
  /// The package's defaults probe one.one.one.one, icanhazip.com, jsonplaceholder.typicode.com and
  /// pokeapi.co. None of them is this app's backend, so on a network that reaches ProxyPos but not
  /// those hosts — a filtered shop connection, a captive portal, an ISP blocking them — the till
  /// declares itself offline and ConnectivityInterceptor refuses every request. The shopkeeper
  /// sees "check your connection" while the connection is fine.
  ///
  /// So the backend's own /health goes in the list, first. Checks are non-strict, meaning any one
  /// success counts as online: if the API answers, the app is online by the only definition that
  /// matters to it. The defaults stay as a fallback, which keeps the reverse case honest — when
  /// the backend is down but the internet is up, the app stays "online" and the request fails with
  /// the server's real error rather than being refused as offline.
  static InternetConnection _checker() => InternetConnection.createInstance(
        customCheckOptions: [
          InternetCheckOption(
            uri: Uri.parse('${APIStringConst.apAPIBaseURL.replaceFirst(RegExp(r'/api/v1/?$'), '')}/health'),
            timeout: const Duration(seconds: 5),
          ),
        ],
        useDefaultOptions: true,
      );

  /// Private constructor for singleton
  ConnectivityService._internal()
      : _connectionChecker = _checker(),
        _log = getLogger('ConnectivityService');

  /// Constructor for testing with injectable connectivity
  ConnectivityService.withChecker(InternetConnection connectionChecker)
      : _connectionChecker = connectionChecker,
        _log = getLogger('ConnectivityService');

  /// Singleton instance
  static final instance = ConnectivityService._internal();

  /// Current connectivity status (cached)
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes
  ///
  /// Emits `true` when device comes online, `false` when offline.
  /// Use this for auto-sync triggers when connectivity is restored.
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Initialize the service and start listening to connectivity changes
  ///
  /// Call this once at app startup (e.g., in main.dart)
  Future<void> initialize() async {
    _log.i('Initializing ConnectivityService');

    // Get initial state
    _isOnline = await checkConnectivity();
    _log.i('Initial connectivity status: ${_isOnline ? "Online" : "Offline"}');

    // Start listening to changes
    _subscription = _connectionChecker.onStatusChange.listen(
      _onConnectivityChanged,
      onError: (error) {
        _log.e('Connectivity stream error', error: error);
      },
    );
  }

  /// One-time connectivity check
  ///
  /// Returns `true` if device has any network connection (WiFi, mobile, etc.)
  /// Returns `false` if no network connection
  Future<bool> checkConnectivity() async {
    try {
      final online = await _connectionChecker.hasInternetAccess;
      _isOnline = online;
      return online;
    } catch (e, stackTrace) {
      _log.e('Error checking connectivity', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Handle connectivity changes from the stream
  void _onConnectivityChanged(InternetStatus status) {
    final wasOnline = _isOnline;
    _isOnline = status == InternetStatus.connected;

    if (wasOnline != _isOnline) {
      _log.i('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      _connectivityController.add(_isOnline);
    }
  }

  /// Dispose of resources
  ///
  /// Call this when the app is shutting down or service is no longer needed
  Future<void> dispose() async {
    _log.i('Disposing ConnectivityService');
    await _subscription?.cancel();
    _subscription = null;
    await _connectivityController.close();
  }
}