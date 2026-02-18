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
      final dynamic result = await _api.createNewSale(token, payload);

      // Parse result into ProductSaleModel robustly
      late final ProductSaleModel model;
      if (result is ProductSaleModel) {
        model = result;
      } else if (result is Map<String, dynamic>) {
        model = ProductSaleModel.fromJson(result);
      } else if (result is Response) {
        final data = result.data;
        if (data is Map<String, dynamic>) {
          model = ProductSaleModel.fromJson(data);
        } else {
          throw Exception('Unexpected response body for create sale');
        }
      } else {
        // Fallback: construct minimal model
        model = ProductSaleModel(sale: null);
      }

      _log.i('Create sale success; caching locally');
      await _storage.saveSale(model);
      return model;
    } on DioException catch (e, st) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      _log.e('Create sale failed (status: $status, body: $data)', error: e, stackTrace: st);
      // Rethrow so upper layers can make routing decisions (queue vs surface)
      rethrow;
    } catch (e, st) {
      _log.e('Create sale failed (unexpected)', error: e, stackTrace: st);
      rethrow;
    }
  }
}
