import 'package:inventory_app_pos/features/home/presentation/presentation/history/data/model/sales_list_model.dart';

abstract class SalesHistoryRepo {
  Future<SalesListModel> getSalesHistory(
    String token, {
    String? search,
    int? page,
  });
}
