import 'package:equatable/equatable.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/model/sale/sale_model.dart';

class HistoryState extends Equatable {
  final bool loading;
  final List<SaleModel> sales;
  final String? error;
  final String? searchQuery;

  const HistoryState({
    this.loading = false,
    this.sales = const [],
    this.error,
    this.searchQuery,
  });

  HistoryState copyWith({
    bool? loading,
    List<SaleModel>? sales,
    String? error,
    String? searchQuery,
    bool clearError = false,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      sales: sales ?? this.sales,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [loading, sales, error, searchQuery];
}
