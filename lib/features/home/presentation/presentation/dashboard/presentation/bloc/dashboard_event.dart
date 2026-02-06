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
