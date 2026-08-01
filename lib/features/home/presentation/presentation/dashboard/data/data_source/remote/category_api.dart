import 'package:dio/dio.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../../../../../../../network/api_service.dart';
import '../../../../../../../../network/constants/api_endpoint_const.dart';

/// Fetches the shop's categories.
///
/// These used to be a hard-coded list in the category strip, which meant the POS
/// and the portal disagreed: the POS showed categories that didn't exist in the
/// database, and anything created in the portal never appeared here. The shop's
/// real categories are now the single source of truth for both.
///
/// Plain Dio rather than a Retrofit method on purpose: regenerating the .g.dart
/// files would discard hand-maintained code in them (see unit_model.g.dart), and
/// this is a single GET. The auth interceptor attaches the bearer token, since the
/// route is registered in APIEndpointConst.privateAPIEndpoint.
class CategoryApi {
  CategoryApi._();
  static final instance = CategoryApi._();

  final _log = getLogger('CategoryApi');

  /// Category names in the order the shop defined them.
  /// Returns an empty list on failure — the strip falls back gracefully rather
  /// than blocking checkout over a cosmetic lookup.
  Future<List<String>> fetchNames() async {
    try {
      final response = await APIService().dioInstance.get<Map<String, dynamic>>(
        APIEndpointConst.apCategories,
      );
      final raw = response.data?['categories'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((c) => (c['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (e) {
      _log.w('Category fetch failed (${e.response?.statusCode}): ${e.message}');
      return const [];
    } catch (e) {
      _log.w('Category fetch failed: $e');
      return const [];
    }
  }
}
