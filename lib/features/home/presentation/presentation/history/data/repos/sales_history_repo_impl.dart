import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/data/data_source/remote/sales_history_api.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/data/model/sales_list_model.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/domain/repo/sales_history_repo.dart';
import 'package:inventory_app_pos/network/api_service.dart';

class SalesHistoryRepoImpl implements SalesHistoryRepo {
  final SalesHistoryApi _api;

  SalesHistoryRepoImpl._()
      : _api = SalesHistoryApi(APIService().dioInstance);

  static final SalesHistoryRepoImpl instance = SalesHistoryRepoImpl._();

  @override
  Future<SalesListModel> getSalesHistory(
    String token, {
    String? search,
    int? page,
  }) async {
    final log = getLogger('SalesHistoryRepoImpl');
    try {
      final res = await _api.getSalesHistory('Bearer $token', search, page);
      log.i('Sales history fetched: ${res.sales?.length ?? 0} records');
      return res;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (e.message ?? 'Request failed');
      log.e('Sales history failed: $message');
      rethrow;
    }
  }
}
