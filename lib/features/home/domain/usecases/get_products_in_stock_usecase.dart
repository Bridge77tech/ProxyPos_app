import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/network/models/api_response.dart';

import '../repositories/home_repository.dart';

class GetProductsInStockUseCase {
  final HomeRepository _repo;
  final _log = getLogger('GetProductsInStockUseCase');

  GetProductsInStockUseCase(this._repo);

  Future<ApiResponse<dynamic>> call(Map<String, dynamic> params) async {
    try {
      final res = await _repo.getProductsInStock(params);
      _log.i('Products fetched (raw), status=${res.response.statusCode}');
      return res;
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }
}
