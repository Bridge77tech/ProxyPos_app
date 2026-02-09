import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';

import '../../../../core/exceptions/auth_exception.dart';
import '../../data/model/user_model.dart';

class SaveCashierInfo {
  APUserModel userInfo;
  final _log = getLogger('SaveCashierInfo');

  SaveCashierInfo(this.userInfo);

  Future<void> call(UserModel user) async {
    try {
      if (user.token == null) {
        throw const AuthException("User profile is null");
      }
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}