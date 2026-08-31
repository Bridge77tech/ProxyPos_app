import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/exceptions/get_product_expection.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/remote/top_product_api_service.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/repo/top_product_repo.dart';
import 'package:inventory_app_pos/network/api_service.dart';
import 'package:logger/logger.dart';

import '../../../../../../../network/exceptions/bad_request_exception.dart';


/// Classify a Dio failure while the exception is still in hand.
///
/// Done here rather than in the UI because this is the last place the type exists: everything
/// above sees only a message, and deciding "was this the network?" from a string is a guess.
ProductFetchFailure _classify(DioException e) {
  final status = e.response?.statusCode;
  if (status == 401 || status == 403) return ProductFetchFailure.unauthorized;
  if (status != null && status >= 500) return ProductFetchFailure.server;

  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ProductFetchFailure.offline;
    case DioExceptionType.cancel:
      // What ConnectivityInterceptor and the auth interceptor use to refuse a request outright.
      return ProductFetchFailure.offline;
    default:
      return status != null ? ProductFetchFailure.server : ProductFetchFailure.unknown;
  }
}

class ProductRepoImpl implements ProductRepository<ProductModel> {
  final Logger _log;
  final ProductAPIService _topProductAPIService;

  ProductRepoImpl._()
      : _topProductAPIService = ProductAPIService(APIService().dioInstance),
        _log = getLogger('TopProductRepoImpl');

  static final ProductRepoImpl instance = ProductRepoImpl._();

  @override
  Future<ProductModel> getTopProducts(String token) async {
    try {
      final res = await _topProductAPIService.getTopProducts(token);
      _log.i("Polling Top Products Success");
      return res;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      // Prefer server-provided message if present
      String message;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.message != null) {
        message = e.message!;
      } else {
        message = 'Request failed';
      }
      _log.e('Top products failed (status: $status, body: $data) -> $message');
      throw GetProductException(message, kind: _classify(e));
    } on GetProductException {
      rethrow;
    } catch (e) {
      // A parse failure lands here: the response arrived and could not be read, which is not a
      // network problem and must not be reported as one.
      _log.e('Top products failed (unexpected): $e');
      throw GetProductException(e.toString(), kind: ProductFetchFailure.malformed);
    }
  }

  @override
  Future<ProductModel> getAllProducts(
      String token, {
        String? search,
        String? category,
      }) async {
    try {
      final res = await _topProductAPIService.getAllProducts(token, search, category);
      _log.i("Polling All Products Success");
      return res;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message;
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.error is BadRequestException) {
        message = (e.error as BadRequestException).message;
      } else {
        message = e.message ?? 'Request failed';
      }
      _log.e('All products failed (status: $status, body: $data) -> $message');
      throw GetProductException(message, kind: _classify(e));
    } on GetProductException {
      rethrow;
    } catch (e) {
      _log.e('All products failed (unexpected): $e');
      throw GetProductException(e.toString(), kind: ProductFetchFailure.malformed);
    }
  }

}