import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';
import 'package:inventory_app_pos/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase<T> {
  final LoginRepository<T> _loginRepo;
  final _log = getLogger("LoginUseCase");

  LoginUseCase(this._loginRepo);

  Future<UserModel> call(Map<String, dynamic> payload) async {
    try {
      return await _loginRepo.login(payload);
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}