import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {
  const LoadHistory();
}

class SearchHistory extends HistoryEvent {
  final String query;
  const SearchHistory(this.query);
  @override
  List<Object?> get props => [query];
}

class RefreshHistory extends HistoryEvent {
  const RefreshHistory();
}
