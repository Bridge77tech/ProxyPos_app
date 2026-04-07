import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/auth_session_storage_impl.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/history/data/repos/sales_history_repo_impl.dart';

import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final _log = getLogger('HistoryBloc');

  HistoryBloc() : super(const HistoryState()) {
    on<LoadHistory>(_onLoadHistory);
    on<SearchHistory>(_onSearchHistory);
    on<RefreshHistory>(_onRefreshHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) {
        emit(state.copyWith(loading: false, error: 'Missing auth token'));
        return;
      }
      final result = await SalesHistoryRepoImpl.instance.getSalesHistory(token);
      emit(state.copyWith(loading: false, sales: result.sales ?? []));
    } catch (e, st) {
      _log.e('LoadHistory failed', error: e, stackTrace: st);
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onSearchHistory(
    SearchHistory event,
    Emitter<HistoryState> emit,
  ) async {
    final query = event.query.trim();
    emit(state.copyWith(loading: true, searchQuery: query, clearError: true));
    try {
      final token = await AuthSessionStorageImpl.instance.getStorageData();
      if (token is! String || token.isEmpty) {
        emit(state.copyWith(loading: false, error: 'Missing auth token'));
        return;
      }
      final result = await SalesHistoryRepoImpl.instance.getSalesHistory(
        token,
        search: query.isEmpty ? null : query,
      );
      emit(state.copyWith(loading: false, sales: result.sales ?? []));
    } catch (e, st) {
      _log.e('SearchHistory failed', error: e, stackTrace: st);
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onRefreshHistory(
    RefreshHistory event,
    Emitter<HistoryState> emit,
  ) async {
    add(const LoadHistory());
  }
}
