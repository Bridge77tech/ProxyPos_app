import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/exceptions/auth_exception.dart';
import 'package:inventory_app_pos/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase<T> {
  final AuthRepository<T> _authRepository;
  final _log = getLogger('LoginUseCase');

  LoginUseCase(this._authRepository);

  Future<T> call(Map<String, dynamic> params) async {
    try {
      return await _authRepository.login(params);
    } on AuthException catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}
