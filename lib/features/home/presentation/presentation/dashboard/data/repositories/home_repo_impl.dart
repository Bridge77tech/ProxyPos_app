// import 'package:dio/dio.dart';
// import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
// import 'package:inventory_app_pos/core/exceptions/get_product_expection.dart';
// import 'package:inventory_app_pos/network/exceptions/bad_request_exception.dart';
//
// import '../../domain/repositories/home_repository.dart';
// import '../remote/home_api_service.dart';
//
// class HomeRepoImpl<T> implements HomeRepository<T> {
//   final HomeAPIService _service;
//   final T Function(Map<String, dynamic>) _fromJson;
//   final _log = getLogger("HomeRepoImpl");
//
//   HomeRepoImpl(this._service, this._fromJson);
//
//   @override
//   Future<> getProductsInStock(Map<String, dynamic> payload) async {
//     try {
//       final getProductsResponse = await _service.getProductsInStock();
//       final data = getProductsResponse.user;
//
//       if (data is T) {
//         return data;
//       }
//
//       if (data != null && data is Map<String, dynamic>) {
//         return _fromJson(data);
//       }
//
//       throw GetProductExpection(
//         getProductsResponse.data.responseDesc ??
//             'API response data cannot be converted to expected type.'
//                 "Expected type: ${T.toString()}, Actual type: ${data.runtimeType}",
//       );
//     } on DioException catch (e) {
//       _log.e(e.toString());
//       if (e.error is BadRequestException) {
//         e.error as BadRequestException;
//         throw GetProductExpection(e.message ?? 'Bad request error');
//       }
//       throw GetProductExpection(e.message);
//     } catch (error) {
//       _log.e(error.toString());
//       rethrow;
//     }
//   }
//
//   @override
//   Future<List<dynamic>> getTopProducts(Map<String, dynamic> payload) async {
//     try {
//       final getTopProductsResponse = await _service.getTopProducts();
//       final data = getTopProductsResponse.data;
//
//       if (data is List<dynamic>) {
//         return data;
//       }
//
//       if (data is List) {
//         return List<dynamic>.from(data);
//       }
//
//       // If API returns a wrapped map containing a list, try to extract common keys.
//       if (data != null && data is Map<String, dynamic>) {
//         final possibleKeys = ['items', 'products', 'data', 'list', 'results'];
//         for (final key in possibleKeys) {
//           final value = data[key];
//           if (value is List) {
//             return List<dynamic>.from(value);
//           }
//         }
//       }
//
//       throw GetProductExpection(
//         getTopProductsResponse.data.responseDesc ??
//             'API response data cannot be converted to expected type.'
//                 "Expected type: List<dynamic>, Actual type: ${data.runtimeType}",
//       );
//     } on DioException catch (e) {
//       _log.e(e.toString());
//       if (e.error is BadRequestException) {
//         e.error as BadRequestException;
//         throw GetProductExpection(e.message ?? 'Bad request error');
//       }
//       // Provide a clearer message on cancelled requests (likely missing token)
//       if (e.type == DioExceptionType.cancel) {
//         throw GetProductExpection(
//           'Request cancelled (unauthorized or session expired)',
//         );
//       }
//       throw GetProductExpection(e.message ?? 'Request failed');
//     } catch (error) {
//       _log.e(error.toString());
//       rethrow;
//     }
//   }
// }
