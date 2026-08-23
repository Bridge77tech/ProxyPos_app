import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/core/services/connectivity_service.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/cashier_info_storage_impl.dart';

import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_event.dart';
import '../../bloc/cart/cart_state.dart';
import 'connection_queue_indicators.dart';

/// Wires ConnectionQueueIndicators to the cart bloc, connectivity and the signed-in role.
///
/// Kept separate so the widget that actually draws the badge takes plain values and can be tested
/// without Hive, a bloc, or a connectivity singleton — the states this has to get right are the
/// whole point of the feature, and they are not worth testing through three layers of plumbing.
class CartQueueIndicators extends StatefulWidget {
  const CartQueueIndicators({super.key});

  @override
  State<CartQueueIndicators> createState() => _CartQueueIndicatorsState();
}

class _CartQueueIndicatorsState extends State<CartQueueIndicators> {
  late bool _isOnline;
  bool _isOwner = false;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService.instance.isOnline;
    _sub = ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
    _loadRole();
    // The queue lives on disk, so state has to be primed — otherwise the badge only appears after
    // the first sync attempt, which is exactly when a cashier has stopped looking.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartBloc>().add(const CartRefreshQueue());
    });
  }

  Future<void> _loadRole() async {
    final user = await CashierInfoStorageImpl.instance.getStorageData();
    final role = user?.role?.toLowerCase().trim();
    if (mounted) setState(() => _isOwner = role == 'owner');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (a, b) => a.pendingSales != b.pendingSales,
      builder: (context, state) {
        final bloc = context.read<CartBloc>();
        return ConnectionQueueIndicators(
          isOnline: _isOnline,
          queue: state.pendingSales,
          isOwner: _isOwner,
          onRetry: (id) => bloc.add(CartRetryPending(id)),
          onDiscard: (id) => bloc.add(CartDiscardPending(id)),
          onReenter: (id) => bloc.add(CartReenterPending(id)),
        );
      },
    );
  }
}
