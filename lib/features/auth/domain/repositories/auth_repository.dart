
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';

/// Minimal repository interface used by auth use-cases.
abstract class LoginRepository<T> {
  Future<UserModel> login(Map<String, dynamic> payload);
}
