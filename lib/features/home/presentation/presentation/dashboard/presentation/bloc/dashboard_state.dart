import 'package:equatable/equatable.dart';

import '../../data/model/product_model.dart';

class DashboardState extends Equatable {
  final bool loading;
  final List<Products> topProducts;
  final String? error;
  final bool requested;

  const DashboardState({
    this.loading = false,
    this.topProducts = const [],
    this.error,
    this.requested = false,
  });

  DashboardState copyWith({
    bool? loading,
    List<Products>? topProducts,
    String? error,
    bool? requested,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      topProducts: topProducts ?? this.topProducts,
      error: error,
      requested: requested ?? this.requested,
    );
  }

  @override
  List<Object?> get props => [loading, topProducts, error, requested];
}
