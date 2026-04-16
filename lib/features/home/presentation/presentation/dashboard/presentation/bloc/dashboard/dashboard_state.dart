import 'package:equatable/equatable.dart';

import '../../../data/model/product_model.dart';

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
  final Products? barcodeProduct;
  /// Error specifically from a barcode scan — shown as a snackbar and does
  /// NOT replace the "Most Purchased" grid.
  final String? barcodeError;

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
    this.barcodeProduct,
    this.barcodeError,
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
    Products? barcodeProduct,
    bool clearBarcodeProduct = false,
    bool clearSearch = false,
    String? barcodeError,
    bool clearBarcodeError = false,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      topProducts: topProducts ?? this.topProducts,
      error: error,
      requested: requested ?? this.requested,
      searching: searching ?? this.searching,
      searchResults: clearSearch ? const [] : (searchResults ?? this.searchResults),
      lastQuery: clearSearch ? null : (lastQuery ?? this.lastQuery),
      lastCategory: clearSearch ? null : (lastCategory ?? this.lastCategory),
      selectedName: selectedName ?? this.selectedName,
      barcodeProduct: clearBarcodeProduct ? null : (barcodeProduct ?? this.barcodeProduct),
      barcodeError: clearBarcodeError ? null : (barcodeError ?? this.barcodeError),
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
    barcodeProduct,
    barcodeError,
  ];
}
