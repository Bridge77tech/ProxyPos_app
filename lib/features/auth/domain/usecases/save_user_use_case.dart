import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/exceptions/auth_exception.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_user_token_use_case.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_cashier_info_use_case.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/usecases/top_products_use_case.dart';

import '../../../home/presentation/presentation/dashboard/domain/services/all_products_sync_service.dart';

/// Persists the session, and separately warms the product caches.
///
/// These used to be one `Future.wait`, which was wrong twice over.
///
/// The token write raced the two product fetches that read it: both readers
/// start with `getToken()`, and a read that reaches Hive before the write lands
/// sees nothing and throws "Missing auth token". That aborted the whole login
/// *after* the credentials had been accepted, so the till hung on the spinner
/// while the token sat safely in storage — which is why quitting and reopening
/// the app walked straight into the POS.
///
/// It also put two network round-trips in front of the dashboard for no reason.
/// The dashboard reads Hive and falls back to the network on a miss, so it does
/// not need the caches warm to render; making the clerk wait for them only
/// delayed the till.
class SaveUserInfoUseCase {
  final _log = getLogger('SaveUserUseCase');

  final SaveUserTokenUseCase _saveUserToken;
  final SaveCashierInfoUseCase _saveUserInfo;
  final GetAndCacheTopProductsUseCase _getTopProducts;
  final AllProductsSyncService _allProductsSync;

  SaveUserInfoUseCase(
    this._saveUserToken,
    this._saveUserInfo,
    this._getTopProducts,
    this._allProductsSync,
  );

  /// Writes the session to local storage. Local only, so it returns in
  /// milliseconds — the login flow may navigate as soon as this completes.
  Future<void> call(UserModel user) async {
    try {
      // Ensure token and user are present
      if (user.token == null || user.user == null) {
        throw const AuthException("User token is null");
      }
      // Sequential on purpose: the token must land before warmProductCaches
      // reads it back, and the cashier record is written under the same
      // guarantee rather than left to race the navigation that follows.
      await _saveUserToken(user.token!);
      await _saveUserInfo(user.getUser);
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }

  /// Fetches the product caches and starts the periodic all-products sync.
  ///
  /// Best-effort by contract: call it after [call] has stored the token, do not
  /// await it on the login path, and let a failure stand. Every screen behind it
  /// re-fetches on a cache miss, so a failed warm-up costs one slower first
  /// search, not a login.
  Future<void> warmProductCaches() async {
    try {
      await Future.wait([
        _getTopProducts(),
        // start() runs one sync immediately and then every 30 minutes.
        _allProductsSync.start(runImmediately: true),
      ]);
    } catch (e) {
      _log.w('Product cache warm-up failed; screens will fetch on demand: $e');
    }
  }

  /// Stops the periodic sync. Called on logout so a signed-out till stops
  /// polling with a token it is about to throw away.
  void stopProductSync() => _allProductsSync.dispose();
}
