import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:flutter/cupertino.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/all_product_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/repos/product_repo_impl.dart';

import '../../../../../../auth/data/data_source/local/auth_session_storage_impl.dart';
import '../../data/data_source/local/top_products_storage.dart';
import '../../data/model/product_model.dart';
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
}
