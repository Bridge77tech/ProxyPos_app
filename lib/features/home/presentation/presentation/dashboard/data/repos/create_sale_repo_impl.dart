import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:dio/dio.dart';

// Correct relative paths from data/repos to siblings/parents
import '../data_source/remote/create_new_sale_api.dart';
import '../data_source/local/create_new_sale_storage.dart';
import '../model/sale/product_sale_model.dart';
import '../../domain/repo/create_sale_repo.dart';

/// Concrete repository that creates a sale via remote API and caches the result locally.
class CreateSaleRepoImpl implements CreateSaleRepository {
  final _log = getLogger('CreateSaleRepoImpl');
  final CreateNewSaleApi _api;
  final CreateNewSaleStorage _storage;

  CreateSaleRepoImpl(this._api, this._storage);

  /// Convenience helper using provided Dio and default storage instance
  static CreateSaleRepoImpl withDio(Dio dio) =>
      CreateSaleRepoImpl(CreateNewSaleApi(dio), CreateNewSaleStorageImpl.instance);

  @override
  Future<ProductSaleModel> createSale({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    _log.i('Creating new sale with payload keys: ${payload.keys.toList()}');
    try {
      // Retrofit will return ProductSaleModel directly on success (201)
      final result = await _api.createNewSale(token, payload);

      _log.i('Create sale success: ${result.message}');

      // Skipping local cache per requirement.
      return result;
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      _log.e('Create sale failed (status: $status, body: $data)', error: e, stackTrace: st);
      // Rethrow DioException so upper layers can distinguish network vs client errors
      rethrow;
    } catch (e, st) {
      // Catch parsing errors or other unexpected exceptions
      _log.e('Create sale failed (unexpected): ${e.toString()}', error: e, stackTrace: st);
      rethrow;
    }
  }
}
