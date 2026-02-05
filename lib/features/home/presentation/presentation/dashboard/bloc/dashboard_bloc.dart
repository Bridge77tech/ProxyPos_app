import 'package:bloc/bloc.dart';
import 'package:inventory_app_pos/data/local_storage_service.dart';
import 'package:inventory_app_pos/data/storage_box.dart';
// import 'package:inventory_app_pos/features/auth/data/session/auth_session_storage_hive.dart';
import 'package:inventory_app_pos/features/home/data/model/product_model.dart';
import 'package:inventory_app_pos/features/home/domain/usecases/get_top_product_use_case.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetTopProductUseCase _getTopProductUseCase;
  final ILocalStorageService _storage;

  DashboardBloc(this._getTopProductUseCase, this._storage)
    : super(const DashboardState()) {
    on<LoadTopProducts>(_onLoadTopProducts);
  }

  Future<void> _onLoadTopProducts(
    LoadTopProducts event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));

    try {
      // Ensure local storage is ready
      await _storage.init();

      // Ensure we have a valid access token before making an auth-required call
      // final session = await AuthSessionStorageHive.instance.read();
      // final hasToken = (session?.access?.token?.isNotEmpty ?? false);
      // if (!hasToken) {
      //   emit(state.copyWith(loading: false, error: 'Not authenticated'));
      //   return;
      // }

      // Fetch raw list from API
      final raw = await _getTopProductUseCase.call(event.params);

      // Map raw list to Products model if possible
      final products = raw
          .whereType<Map<String, dynamic>>()
          .map((json) => Products.fromJson(json))
          .toList();

      // Persist to Hive as JSON maps for portability
      await _storage.openBox<List>(StorageBox.topProducts);
      final box = _storage.getBox<List>(StorageBox.topProducts.name);
      await box.put('top_products', products.map((p) => p.toJson()).toList());

      emit(state.copyWith(loading: false, topProducts: products));
    } catch (e) {
      // Fall back to cached data if available
      try {
        if (!_storage.isBoxOpen(StorageBox.topProducts.name)) {
          await _storage.openBox<List>(StorageBox.topProducts);
        }
        final box = _storage.getBox<List>(StorageBox.topProducts.name);
        final cached = box.get('top_products');
        if (cached is List) {
          final products = cached
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .map((json) => Products.fromJson(json))
              .toList();
          emit(
            state.copyWith(
              loading: false,
              topProducts: products,
              error: e.toString(),
            ),
          );
          return;
        }
      } catch (_) {
        // ignore cache errors, surface original
      }
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
