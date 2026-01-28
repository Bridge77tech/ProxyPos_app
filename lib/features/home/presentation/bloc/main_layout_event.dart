import 'package:equatable/equatable.dart';
import 'main_layout_state.dart';

abstract class MainLayoutEvent extends Equatable {
  const MainLayoutEvent();

  @override
  List<Object> get props => [];
}

class SelectTab extends MainLayoutEvent {
  final MainLayoutTab tab;
  const SelectTab(this.tab);

  @override
  List<Object> get props => [tab];
}
