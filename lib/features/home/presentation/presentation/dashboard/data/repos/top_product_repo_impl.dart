import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/exceptions/get_product_expection.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/remote/top_product_api_service.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/products_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/repo/top_product_repo.dart';

import '../../../../../../../network/exceptions/bad_request_exception.dart';

class TopProductRepoImpl<T> implements TopProductRepo<T> {
  final _log = getLogger("TopProductRepoImpl");
  final TopProductAPIService _topProductAPIService;

  TopProductRepoImpl(this._topProductAPIService);

  @override
  Future<ProductModel> getTopProducts(String token) async {
    try {
      final ProductModel res = await _topProductAPIService.getTopProducts(token);
      _log.i("testing ${res.toString()}");
      return res;
    } on DioException catch (e) {
      _log.e(e.toString());

      // Prefer specific error message if available
      String? message;
      if (e.error is BadRequestException) {
        message = (e.error as BadRequestException).message;
      }
      // fallback to Dio's message or a generic
      message ??= e.message ?? 'Request failed';

      throw GetProductExpection(message);
    } catch (e) {
      _log.e(e.toString());
      rethrow;
    }
  }

}