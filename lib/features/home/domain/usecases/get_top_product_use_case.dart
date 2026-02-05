import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/home/domain/repositories/home_repository.dart';

class GetTopProductUseCase {
  final HomeRepository _repo;
  final _log = getLogger('GetTopProductUseCase');

  GetTopProductUseCase(this._repo);

  Future<List<dynamic>> call(Map<String, dynamic> params) async {
    try {
      final res = await _repo.getTopProducts(params);
      _log.i('Top products fetched (raw), count=${res.length}');
      return res;
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}