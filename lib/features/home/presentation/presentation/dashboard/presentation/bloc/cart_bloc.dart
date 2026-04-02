import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/routing/navigation_helper.dart';

import '../../data/data_source/local/pending_sales_storage.dart';
import '../../data/model/variant.dart';
import '../../data/model/unit_model.dart';
import '../../domain/usecases/create_sale_use_case.dart';
import 'cart_event.dart';
import 'cart_state.dart' show CartState, CartItem;

class CartBloc extends Bloc<CartEvent, CartState> {
  final _log = getLogger('CartBloc');
  final CreateSaleUseCase _createSale;
  final PendingSalesStorage _pendingStorage;
  final Connectivity _connectivity;

  // TextEditingController for amount input
  late final TextEditingController amountController;

  CartBloc({
    required CreateSaleUseCase createSaleUseCase,
    PendingSalesStorage? pendingStorage,
    Connectivity? connectivity,
  })  : _createSale = createSaleUseCase,
        _pendingStorage = pendingStorage ?? PendingSalesStorageImpl.instance,
        _connectivity = connectivity ?? Connectivity(),
        super(const CartState()) {
    // Initialize amount controller
    amountController = TextEditingController();

    on<CartSelectVariant>(_onSelectVariant);
    on<CartSelectUnit>(_onSelectUnit);
    on<CartChangeQuantity>(_onChangeQuantity);
    on<CartSetQuantity>(_onSetQuantity);
    on<CartAddItem>(_onAddItem);
    on<CartRemoveItem>(_onRemoveItem);
    on<CartUpdateItemQuantity>(_onUpdateItemQuantity);
    on<CartClear>(_onClear);
    on<CartResetSelection>(_onResetSelection);
    on<CartSubmitOrder>(_onSubmitOrder);
    on<CartSyncPending>(_onSyncPending);
    on<CartSelectPayment>(_onSelectPayment);
    on<CartSetAmountReceived>(_onSetAmountReceived);
  }

  @override
  Future<void> close() {
    amountController.dispose();
    return super.close();
  }

  void _onSelectVariant(CartSelectVariant event, Emitter<CartState> emit) {
    final defaultUnit = (event.variant.units != null && event.variant.units!.isNotEmpty)
        ? event.variant.units!.first
        : null;
    emit(state.copyWith(
      currentProduct: event.product,
      selectedVariant: event.variant,
      selectedUnit: defaultUnit,
    ));
    _log.i('Selected variant: ${event.variant.type} (${event.variant.size}) of ${event.product.name}');
  }

  void _onSelectUnit(CartSelectUnit event, Emitter<CartState> emit) {
    emit(state.copyWith(
      currentProduct: event.product,
      selectedVariant: event.variant,
      selectedUnit: event.unit,
    ));
    _log.i('Selected unit: ${event.unit.type} for ${event.product.name}');
  }

  void _onChangeQuantity(CartChangeQuantity event, Emitter<CartState> emit) {
    final next = (state.selectedQuantity + event.delta).clamp(1, 999);
    emit(state.copyWith(selectedQuantity: next));
    _log.i('Quantity changed to $next');
  }

  void _onSetQuantity(CartSetQuantity event, Emitter<CartState> emit) {
    final next = event.quantity.clamp(1, 999);
    emit(state.copyWith(selectedQuantity: next));
    _log.i('Quantity set to $next');
  }

  void _onAddItem(CartAddItem event, Emitter<CartState> emit) {
    try {
      final productId = event.product.id?.toString() ?? '';
      final productName = event.product.name ?? '';
      final v = event.variant;
      final u = event.unit;

      // Merge with existing if same productId + variant + unit
      final items = List<CartItem>.from(state.items);
      final idx = items.indexWhere((it) =>
          it.productId == productId && _sameVariantUnit(it.variant, it.unit, v, u));
      if (idx >= 0) {
        final existing = items[idx];
        items[idx] = CartItem(
          productId: existing.productId,
          productName: existing.productName,
          variant: existing.variant,
          unit: existing.unit,
          quantity: (existing.quantity + event.quantity).clamp(1, 999),
        );
      } else {
        items.add(CartItem(
          productId: productId,
          productName: productName,
          variant: v,
          unit: u,
          quantity: event.quantity,
        ));
      }
      emit(state.copyWith(items: items, selectedQuantity: 0, selectedVariant: null, currentProduct: null));
      _log.i('Added to cart: $productName (${u.type}) x${event.quantity}');
    } catch (e, st) {
      _log.e('Add to cart failed', error: e, stackTrace: st);
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSubmitOrder(CartSubmitOrder event, Emitter<CartState> emit) async {
    if (state.items.isEmpty) {
      _log.w('Submit order requested with empty cart');
      return;
    }

    // Mark submitting true for UI overlay
    emit(state.copyWith(submitting: true, error: null, successMessage: null));

    // Minimal payload expected by backend
    final payload = <String, dynamic>{
      'items': state.items.map((it) => {
        'productId': it.productId,
        'variantId': it.variant.id,
        'quantity': it.quantity,
        'saleType': it.unit.type,
      }).toList(),
      'amountPaid': state.amountReceived,
      'paymentMethod': state.paymentMethod?.name,
      "deviceId": "POS-TABLET-001"
    };

    if (state.paymentMethod == null) {
      _log.w('No payment method selected; payload will include null paymentMethod');
    }

    final results = await _connectivity.checkConnectivity();
    final isOnline = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);

    if (isOnline) {
      _log.i('Online: submitting order immediately');
      NavigationHelper.pop();
      try {
        await _createSale.call(payload);
        _log.i('Order submitted successfully');
        // Success - clear cart, amount received, and show success message
        amountController.clear();
        emit(state.copyWith(
          items: [],
          selectedQuantity: 0,
          selectedVariant: null,
          selectedUnit: null,
          currentProduct: null,
          amountReceived: 0.0,
          paymentMethod: null,
          error: null,
          successMessage: 'Order submitted successfully',
          submitting: false,
        ));
      } on DioException catch (e, st) {
        final status = e.response?.statusCode;
        final msg = e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? e.message)
            : e.message;
        _log.e('Immediate submit failed (online error $status): $msg', error: e, stackTrace: st);
        // Do NOT queue on online failures per requirement
        emit(state.copyWith(
          submitting: false,
          error: msg ?? 'Submit failed',
          successMessage: null,
        ));
      } catch (e, st) {
        // Unexpected error - do not queue
        _log.e('Immediate submit failed (unexpected error): ${e.toString()}', error: e, stackTrace: st);
        emit(state.copyWith(
          submitting: false,
          error: 'Unexpected error: ${e.toString()}',
          successMessage: null,
        ));
      } finally {
        NavigationHelper.pop();
      }
    } else {
      _log.w('Offline: queueing order payload for later sync');
      NavigationHelper.pop();
      await _pendingStorage.enqueue(payload);
      amountController.clear();
      emit(state.copyWith(
        items: [],
        selectedQuantity: 0,
        selectedVariant: null,
        selectedUnit: null,
        currentProduct: null,
        amountReceived: 0.0,
        paymentMethod: null,
        successMessage: 'Order queued for sync when online',
        error: null,
        submitting: false,
      ));
    }
  }

  Future<void> _onSyncPending(CartSyncPending event, Emitter<CartState> emit) async {
    final results = await _connectivity.checkConnectivity();
    final isOnline = results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    if (!isOnline) {
      _log.w('Sync requested but still offline');
      return;
    }

    final queue = await _pendingStorage.getQueue();
    if (queue.isEmpty) {
      _log.i('No pending sales to sync');
      return;
    }

    _log.i('Syncing ${queue.length} pending sales');
    for (int i = 0; i < queue.length; i++) {
      final payload = queue[i];
      try {
        await _createSale.call(payload);
        await _pendingStorage.removeAt(i);
      } catch (e, st) {
        _log.e('Failed to sync queued sale at index $i', error: e, stackTrace: st);
        // Stop on first failure to avoid reordering; will retry later
        break;
      }
    }
  }

  void _onRemoveItem(CartRemoveItem event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    if (event.index >= 0 && event.index < items.length) {
      items.removeAt(event.index);
      emit(state.copyWith(items: items));
    }
  }

  void _onUpdateItemQuantity(CartUpdateItemQuantity event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    if (event.index >= 0 && event.index < items.length) {
      final existing = items[event.index];
      final nextQty = (existing.quantity + event.delta).clamp(1, 999);
      items[event.index] = CartItem(
        productId: existing.productId,
        productName: existing.productName,
        variant: existing.variant,
        unit: existing.unit,
        quantity: nextQty,
      );
      emit(state.copyWith(items: items));
    }
  }

  void _onClear(CartClear event, Emitter<CartState> emit) {
    amountController.clear();
    emit(state.copyWith(items: [], selectedVariant: null, selectedUnit: null, amountReceived: 0.0, paymentMethod: null));
  }

  void _onResetSelection(CartResetSelection event, Emitter<CartState> emit) {
    emit(state.copyWith(selectedQuantity: 0, selectedVariant: null, selectedUnit: null, currentProduct: null));
    _log.i('Selection reset after add-to-cart');
  }

  void _onSelectPayment(CartSelectPayment event, Emitter<CartState> emit) {
    emit(state.copyWith(paymentMethod: event.method));
    _log.i('Payment method selected: ${event.method.name}');
  }

  void _onSetAmountReceived(CartSetAmountReceived event, Emitter<CartState> emit) {
    final amt = event.amount >= 0 ? event.amount : 0.0;
    emit(state.copyWith(amountReceived: amt));
    _log.i('Amount received set: $amt');
  }

  bool _sameVariantUnit(Variants aVar, UnitModel aUnit, Variants bVar, UnitModel bUnit) {
    return aVar.type == bVar.type &&
        aVar.size == bVar.size &&
        aUnit.type == bUnit.type &&
        aUnit.sellingPrice == bUnit.sellingPrice;
  }
}
