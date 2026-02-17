import 'package:equatable/equatable.dart';

import '../../data/model/product_model.dart';

class DashboardState extends Equatable {
  final bool loading;
  final List<Products> topProducts;
  final String? error;
  final bool requested;
  final bool searching;
  final List<Products> searchResults;
  final String? lastQuery;
  final String? lastCategory;
  final String? selectedName;

  const DashboardState({
    this.loading = false,
    this.topProducts = const [],
    this.error,
    this.requested = false,
    this.searching = false,
    this.searchResults = const [],
    this.lastQuery,
    this.lastCategory,
    this.selectedName,
  });

  DashboardState copyWith({
    bool? loading,
    List<Products>? topProducts,
    String? error,
    bool? requested,
    bool? searching,
    List<Products>? searchResults,
    String? lastQuery,
    String? lastCategory,
    String? selectedName,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      topProducts: topProducts ?? this.topProducts,
      error: error,
      requested: requested ?? this.requested,
      searching: searching ?? this.searching,
      searchResults: searchResults ?? this.searchResults,
      lastQuery: lastQuery ?? this.lastQuery,
      lastCategory: lastCategory ?? this.lastCategory,
      selectedName: selectedName ?? this.selectedName,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    topProducts,
    error,
    requested,
    searching,
    searchResults,
    lastQuery,
    lastCategory,
    selectedName,
  ];
}
