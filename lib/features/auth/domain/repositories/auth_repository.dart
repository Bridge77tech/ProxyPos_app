import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';

/// Minimal repository interface used by auth use-cases.
abstract class AuthRepository {
  Future<Map<String, dynamic>> login(Map<String, dynamic> payload);
}
