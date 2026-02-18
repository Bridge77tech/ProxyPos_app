// CreateSaleUseCase: orchestrates token retrieval and sale creation via repository
import 'package:meta/meta.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../repo/create_sale_repo.dart';
import '../../data/model/sale/product_sale_model.dart';

/// Contract for reading the current auth token (shared with other use cases).
abstract class CreateSaleAuthReader {
  Future<String?> getToken();
}

@immutable
class CreateSaleUseCase {
  final _log = getLogger('CreateSaleUseCase');
  final CreateSaleAuthReader _auth;
  final CreateSaleRepository _repo;

  CreateSaleUseCase(this._auth, this._repo);

  /// Creates a new sale using the stored session token and provided payload.
  /// Throws if token is missing.
  Future<ProductSaleModel> call(Map<String, dynamic> payload) async {
    final token = await _auth.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token for creating sale');
    }
    final bearer = 'Bearer $token';
    _log.i('CreateSaleUseCase | call  - Dispatching create sale');
    final res = await _repo.createSale(token: bearer, payload: payload);
    _log.i('CreateSaleUseCase | call  - Create sale completed');
    return res;
  }
}
