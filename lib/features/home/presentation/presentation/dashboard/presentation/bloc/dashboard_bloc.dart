import 'package:bloc/bloc.dart';
import 'package:inventory_app_pos/data/local_storage_service.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ILocalStorageService _storage;

  DashboardBloc(this._storage)
    : super(const DashboardState()) {

  }


}
