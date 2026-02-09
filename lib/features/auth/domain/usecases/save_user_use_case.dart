import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/exceptions/auth_exception.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_user_token_use_case.dart';
import 'package:inventory_app_pos/features/auth/domain/usecases/save_cashier_info_use_case.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/usecases/top_products_use_case.dart';

class SaveUserInfoUseCase {
  final _log = getLogger('SaveUserUseCase');

  final SaveUserTokenUseCase _saveUserToken;
  final SaveCashierInfoUseCase _saveUserInfo;
  final GetAndCacheTopProductsUseCase _getTopProducts;



  SaveUserInfoUseCase(
      this._saveUserToken,
      this._saveUserInfo,
      this._getTopProducts,
      );

  Future<void> call(UserModel user) async {
    try {
      // Ensure token and user are present
      if (user.token == null || user.user == null){
        throw const AuthException("User token is null");
      }
      // Save token and cashier info in parallel
      await Future.wait([
        _saveUserToken(user.token!),
        _saveUserInfo(user.getUser),
        _getTopProducts(),
      ]);
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}