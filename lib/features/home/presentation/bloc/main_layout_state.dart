import 'package:equatable/equatable.dart';

enum MainLayoutTab { dashboard, history, myAccount }

class MainLayoutState extends Equatable {
  final MainLayoutTab selectedTab;

  const MainLayoutState({this.selectedTab = MainLayoutTab.dashboard});

  MainLayoutState copyWith({MainLayoutTab? selectedTab}) {
    return MainLayoutState(
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  @override
  List<Object> get props => [selectedTab];
}