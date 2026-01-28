import 'package:bloc/bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/bloc/main_layout_event.dart';
import 'package:inventory_app_pos/features/home/presentation/bloc/main_layout_state.dart';

class MainLayoutBloc extends Bloc<MainLayoutEvent, MainLayoutState> {
  MainLayoutBloc() : super(const MainLayoutState()) {
    on<SelectTab>((event, emit) {
      emit(state.copyWith(selectedTab: event.tab));
    });
  }
}