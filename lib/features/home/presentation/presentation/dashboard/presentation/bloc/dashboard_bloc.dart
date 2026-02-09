import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final _log = getLogger('DashboardBloc');

  DashboardBloc() : super(const DashboardState()) {
    on<LoadTopProducts>(_onLoadTopProducts);
  }

  Future<void> _onLoadTopProducts(
    LoadTopProducts event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
    //  TODO: call the end top function here
    } catch (e) {
      _log.e('Failed to fetch top products: $e');
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
