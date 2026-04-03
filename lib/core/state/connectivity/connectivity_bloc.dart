import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:inventory_app_pos/core/services/connectivity_service.dart';

part  'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  ConnectivityBloc({ConnectivityService? connectivityService})
      : _connectivityService = connectivityService ?? ConnectivityService.instance,
        super(
          ConnectivityState(
            isOnline: (connectivityService ?? ConnectivityService.instance).isOnline,
          ),
        ) {
    on<ConnectivitySubscriptionRequested>(_onSubscriptionRequested);
    on<ConnectivityStatusChanged>(_onConnectivityStatusChanged);

    // Kick off the subscription
    add(const ConnectivitySubscriptionRequested());
  }

  Future<void> _onSubscriptionRequested(
    ConnectivitySubscriptionRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    // Emit current cached status immediately so UI paints the right state.
    emit(state.copyWith(isOnline: _connectivityService.isOnline));

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (isOnline) => add(ConnectivityStatusChanged(isOnline: isOnline)),
    );
  }

  Future<void> _onConnectivityStatusChanged(
    ConnectivityStatusChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}