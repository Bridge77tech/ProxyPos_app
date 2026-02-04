import 'package:equatable/equatable.dart';
import 'package:inventory_app_pos/features/home/data/model/product_model.dart';

class DashboardState extends Equatable {
  final bool loading;
  final List<Products> topProducts;
  final String? error;

  const DashboardState({
    this.loading = false,
    this.topProducts = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? loading,
    List<Products>? topProducts,
    String? error,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      topProducts: topProducts ?? this.topProducts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, topProducts, error];
}
