import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter/cupertino.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/all_product_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/repos/product_repo_impl.dart';

import '../../../../../../../auth/data/data_source/local/auth_session_storage_impl.dart';
import '../../../data/data_source/local/top_products_storage.dart';
import '../../../data/model/product_model.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final _log = getLogger('DashboardBloc');
  List<Products>? _allProductsCache; // in-memory cache to speed up search

  DashboardBloc()
      : super(const DashboardState()) {
    on<LoadTopProducts>(_onLoadTopProducts);
    on<SearchProducts>(_onSearchProducts);
    on<SelectSearchSuggestion>(_onSelectSearchSuggestion);
    on<SearchByBarcode>(_onSearchByBarcode);
    on<ClearBarcodeProduct>(_onClearBarcodeProduct);
    on<RefreshTopProducts>(_onRefreshTopProducts);
  }

  Future<void> _onLoadTopProducts(
    LoadTopProducts event,
    Emitter<DashboardState> emit,
  ) async {
    // If there is an active search query or category, skip loading top products
    final hasActiveQuery = (state.lastQuery?.trim().isNotEmpty ?? false) ||
        (state.lastCategory?.trim().isNotEmpty ?? false);
    if (hasActiveQuery) {
      _log.i('Skipping LoadTopProducts due to active search query/category');
      return;
    }

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

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<DashboardState> emit,
  ) async {
    final query = event.query.trim().toLowerCase();
    final category = event.category?.trim().toLowerCase();
    if (query.isEmpty && (category == null || category.isEmpty)) {
      emit(state.copyWith(searching: false, searchResults: const [], lastQuery: null, lastCategory: null));
      return;
    }

    emit(state.copyWith(searching: true, lastQuery: event.query, lastCategory: event.category));

    try {
      // Lazily load and retain in-memory cache for faster subsequent searches
      if (_allProductsCache == null) {
        final allStorage = AllProductsStorageImpl.instance;
        final allModel = await allStorage.getAllProducts();
        _allProductsCache = allModel?.products ?? const [];
      }
      final local = _allProductsCache ?? const [];

      bool matches(Products p) {
        final name = (p.name ?? '').toLowerCase();
        final cat = (p.category ?? '').toLowerCase();
        final qOk = query.isEmpty ? true : name.contains(query);
        final cOk = (category == null || category.isEmpty) ? true : cat.contains(category);
        return qOk && cOk;
      }

      final localResults = local.where(matches).toList();
      if (localResults.isNotEmpty) {
        _log.i('Search hit in-memory cache: ${localResults.length} results');
        emit(state.copyWith(searching: false, searchResults: localResults));
        return;
      }

      // Fallback: hit remote API via repo and update both storage and in-memory cache
      _log.i('Cache miss, searching remote...');
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) {
        emit(state.copyWith(searching: false, error: 'Missing auth token'));
        return;
      }

      final repo = ProductRepoImpl.instance;
      final remoteModel = await repo.getAllProducts('Bearer $token', search: event.query, category: event.category);
      final remoteResults = remoteModel.products ?? const [];

      // Save and refresh in-memory cache
      final allStorage = AllProductsStorageImpl.instance;
      await allStorage.saveAllProducts(remoteModel);
      _allProductsCache = remoteResults; // refresh cache

      _log.i('Remote search returned ${remoteResults.length} results');
      emit(state.copyWith(searching: false, searchResults: remoteResults));
    } catch (e, st) {
      _log.e('Search failed', error: e, stackTrace: st);
      emit(state.copyWith(searching: false, error: e.toString()));
    }
  }

  Future<void> _onSelectSearchSuggestion(
    SelectSearchSuggestion event,
    Emitter<DashboardState> emit,
  ) async {
    final selected = event.name.trim();
    if (selected.isEmpty) return;

    try {
      debugPrint('Selected suggestion: $selected');
      emit(state.copyWith(
        selectedName: selected,
        lastQuery: selected,
        searching: false,
      ));
    } catch (e, st) {
      _log.e('Select suggestion failed', error: e, stackTrace: st);
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSearchByBarcode(
    SearchByBarcode event,
    Emitter<DashboardState> emit,
  ) async {
    final barcode = event.barcode.trim();
    if (barcode.isEmpty) return;

    _log.i('Barcode scanned: $barcode');
    emit(state.copyWith(searching: true));

    try {
      // 1. Lazily load local cache
      if (_allProductsCache == null) {
        final allStorage = AllProductsStorageImpl.instance;
        final allModel = await allStorage.getAllProducts();
        _allProductsCache = allModel?.products ?? const [];
      }

      // 2. Search local cache by barcode field
      Products? match = _allProductsCache!.cast<Products?>().firstWhere(
        (p) => p?.barcode?.trim() == barcode,
        orElse: () => null,
      );

      if (match != null) {
        _log.i('Barcode match found in cache: ${match.name}');
        emit(state.copyWith(searching: false, barcodeProduct: match));
        return;
      }

      // 3. Cache miss — fall back to remote API using barcode as search query
      _log.i('Barcode not in cache, querying API...');
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) {
        emit(state.copyWith(searching: false, error: 'Missing auth token'));
        return;
      }

      final repo = ProductRepoImpl.instance;
      final remoteModel = await repo.getAllProducts('Bearer $token', search: barcode);
      final remoteProducts = remoteModel.products ?? const [];

      // Match by barcode in the remote results
      match = remoteProducts.cast<Products?>().firstWhere(
        (p) => p?.barcode?.trim() == barcode,
        orElse: () => null,
      );

      if (match != null) {
        _log.i('Barcode match found via API: ${match.name}');
        // Merge into cache so subsequent scans are instant
        _allProductsCache = [..._allProductsCache!, ...remoteProducts];
        final allStorage = AllProductsStorageImpl.instance;
        await allStorage.saveAllProducts(remoteModel);
        emit(state.copyWith(searching: false, barcodeProduct: match));
      } else {
        _log.w('No product found for barcode: $barcode');
        emit(state.copyWith(searching: false, error: 'Product not found for barcode: $barcode'));
      }
    } catch (e, st) {
      _log.e('Barcode search failed', error: e, stackTrace: st);
      emit(state.copyWith(searching: false, error: e.toString()));
    }
  }

  void _onClearBarcodeProduct(
    ClearBarcodeProduct event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(clearBarcodeProduct: true));
  }

  Future<void> _onRefreshTopProducts(
    RefreshTopProducts event,
    Emitter<DashboardState> emit,
  ) async {
    _log.i('Refreshing top products after order...');
    try {
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) {
        _log.w('Cannot refresh top products: missing auth token');
        return;
      }

      final repo = ProductRepoImpl.instance;
      final model = await repo.getTopProducts('Bearer $token');
      final products = model.products ?? const [];

      // Persist to local cache so the next cold load is also up-to-date
      await TopProductsStorageImpl.instance.saveTopProducts(model);

      // Also invalidate the in-memory all-products cache so stock counts
      // shown in search results reflect the latest quantities
      _allProductsCache = null;

      _log.i('Top products refreshed: ${products.length} items');
      emit(state.copyWith(topProducts: products));
    } catch (e, st) {
      _log.e('Failed to refresh top products', error: e, stackTrace: st);
    }
  }
}
