
/// Minimal repository interface used by auth use-cases.
abstract class AuthRepository {
  Future<Map<String, dynamic>> login(Map<String, dynamic> payload);
}
