import 'package:equatable/equatable.dart';

class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadTopProducts extends DashboardEvent {
  final Map<String, dynamic> params;
  const LoadTopProducts({this.params = const {}});

  @override
  List<Object?> get props => [params];
}

class SearchProducts extends DashboardEvent {
  final String query;
  final String? category;
  const SearchProducts(this.query, {this.category});

  @override
  List<Object?> get props => [query, category];
}

class SelectSearchSuggestion extends DashboardEvent {
  final String name;
  const SelectSearchSuggestion(this.name);
  @override
  List<Object?> get props => [name];
}

class SearchByBarcode extends DashboardEvent {
  final String barcode;
  const SearchByBarcode(this.barcode);
  @override
  List<Object?> get props => [barcode];
}

class ClearBarcodeProduct extends DashboardEvent {
  const ClearBarcodeProduct();
}

/// Fetches fresh top products from the API and updates the display.
/// Dispatched after a successful order so stock quantities stay accurate.
class RefreshTopProducts extends DashboardEvent {
  const RefreshTopProducts();
}
