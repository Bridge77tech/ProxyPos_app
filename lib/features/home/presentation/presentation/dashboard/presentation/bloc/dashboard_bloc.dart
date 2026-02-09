import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import '../../data/data_source/local/top_products_storage.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final _log = getLogger('DashboardBloc');


  DashboardBloc()
      : super(const DashboardState()) {
    on<LoadTopProducts>(_onLoadTopProducts);
  }

  Future<void> _onLoadTopProducts(
    LoadTopProducts event,
    Emitter<DashboardState> emit,
  ) async {
    _log.i('Loading top products from local cache...');
    emit(state.copyWith(loading: true, error: null, requested: true));
    try {
      final cache = TopProductsStorageImpl.instance;
      final productModel = await cache.getTopProducts();
      final products = productModel?.products ?? const [];

      if (productModel == null) {
        _log.w('No cached top products found.');
      }

      _log.i('Top products count: ${products.length}');
      if (products.isNotEmpty) {
        _log.i('First product: ${products.first.name}');
      }

      emit(state.copyWith(
        loading: false,
        topProducts: products,
        error: null,
      ));
    } catch (e, st) {
      _log.e('Failed to fetch top products', error: e, stackTrace: st);
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
