import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/routing/navigation_helper.dart';
import 'package:inventory_app_pos/core/services/connectivity_service.dart';

import '../../../../../../../auth/data/data_source/local/auth_session_storage_impl.dart';
import '../../../data/data_source/local/all_product_storage.dart';
import '../../../data/data_source/local/pending_sales_storage.dart';
import '../../../data/model/product_model.dart';
import '../../../data/model/variant.dart';
import '../../../data/model/unit_model.dart';
import '../../../data/repos/product_repo_impl.dart';
import '../../../domain/usecases/create_sale_use_case.dart';
import 'cart_event.dart';
import 'cart_state.dart' show CartState, CartItem;

class CartBloc extends Bloc<CartEvent, CartState> {
  final _log = getLogger('CartBloc');
  final CreateSaleUseCase _createSale;
  final PendingSalesStorage _pendingStorage;
  StreamSubscription<bool>? _connectivitySub;

  // TextEditingController for amount input
  late final TextEditingController amountController;

  CartBloc({
    required CreateSaleUseCase createSaleUseCase,
    PendingSalesStorage? pendingStorage,
  })  : _createSale = createSaleUseCase,
        _pendingStorage = pendingStorage ?? PendingSalesStorageImpl.instance,
        super(const CartState()) {
    // Initialize amount controller
    amountController = TextEditingController();

    on<CartSelectVariant>(_onSelectVariant);
    on<CartSelectUnit>(_onSelectUnit);
    on<CartChangeQuantity>(_onChangeQuantity);
    on<CartSetQuantity>(_onSetQuantity);
    on<CartAddItem>(_onAddItem);
    on<CartAddByBarcode>(_onAddByBarcode);
    on<CartClearPendingBarcodeProduct>(_onClearPendingBarcodeProduct);
    on<CartClearBarcodeError>(_onClearBarcodeError);
    on<CartRemoveItem>(_onRemoveItem);
    on<CartUpdateItemQuantity>(_onUpdateItemQuantity);
    on<CartClear>(_onClear);
    on<CartResetSelection>(_onResetSelection);
    on<CartSubmitOrder>(_onSubmitOrder);
    on<CartSyncPending>(_onSyncPending);
    on<CartSelectPayment>(_onSelectPayment);
    on<CartSetAmountReceived>(_onSetAmountReceived);

    // Auto-sync pending sales whenever the device comes back online.
    _connectivitySub = ConnectivityService.instance.onConnectivityChanged
        .where((isOnline) => isOnline)
        .listen((_) {
      _log.i('Connection restored — triggering pending sales sync');
      add(const CartSyncPending());
    });
  }

  @override
  Future<void> close() async {
    await _connectivitySub?.cancel();
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

  Future<void> _onAddByBarcode(
    CartAddByBarcode event,
    Emitter<CartState> emit,
  ) async {
    final barcode = event.barcode.trim();
    if (barcode.isEmpty) return;

    _log.i('Barcode scanned: $barcode — looking up product');

    try {
      // 1. Search local cache first.
      // barcode is now on UnitModel, so we scan variants → units → barcode.
      final allStorage = AllProductsStorageImpl.instance;
      final allModel = await allStorage.getAllProducts();
      var hit = _findUnitByBarcode(allModel?.products ?? const [], barcode);

      // 2. Cache miss — query API.
      if (hit == null) {
        _log.i('Barcode not in cache, querying API...');
        final token = await AuthSessionStorageImpl.instance.getStorageData();
        if (token is! String || token.isEmpty) {
          emit(state.copyWith(barcodeError: 'Missing auth token'));
          return;
        }
        final remoteModel = await ProductRepoImpl.instance
            .getAllProducts('Bearer $token', search: barcode);
        final remoteProducts = remoteModel.products ?? const [];
        _log.i('API returned ${remoteProducts.length} product(s) for barcode: $barcode');

        hit = _findUnitByBarcode(remoteProducts, barcode);

        // Fallback: server already matched by barcode and returned exactly one
        // product — trust it even if the unit barcode field is missing.
        if (hit == null && remoteProducts.length == 1) {
          final p = remoteProducts.first;
          final allCombos = _flattenCombos(p);
          if (allCombos.length == 1) {
            hit = (product: p, variant: allCombos.first.variant, unit: allCombos.first.unit);
          } else if (allCombos.isNotEmpty) {
            // Multiple combos but exact barcode unknown — show picker
            _log.i('Single API result, multiple combos — showing picker for ${p.name}');
            await allStorage.saveAllProducts(remoteModel);
            emit(state.copyWith(pendingBarcodeProduct: p));
            return;
          }
        }

        if (hit != null) {
          await allStorage.saveAllProducts(remoteModel);
        }
      }

      if (hit == null) {
        _log.w('No product found for barcode: $barcode');
        emit(state.copyWith(barcodeError: 'No product found for barcode: $barcode'));
        return;
      }

      // 3. We know the exact unit — add directly to cart.
      _log.i('Barcode match: ${hit.product.name} (${hit.unit.type}) — adding to cart');
      _onAddItem(
        CartAddItem(
          product: hit.product,
          variant: hit.variant,
          unit: hit.unit,
          quantity: 1,
        ),
        emit,
      );
    } catch (e, st) {
      _log.e('Barcode add failed', error: e, stackTrace: st);
      emit(state.copyWith(barcodeError: 'Barcode lookup failed: ${e.toString()}'));
    }
  }

  /// Searches [products] for the first unit whose barcode matches [barcode].
  /// Returns a record of the owning product, variant, and unit, or null.
  static ({Products product, Variants variant, UnitModel unit})? _findUnitByBarcode(
    List<Products> products,
    String barcode,
  ) {
    for (final p in products) {
      for (final v in p.variants ?? <Variants>[]) {
        for (final u in v.units ?? <UnitModel>[]) {
          if (u.barcode.trim() == barcode) {
            return (product: p, variant: v, unit: u);
          }
        }
      }
    }
    return null;
  }

  /// Flattens all variant+unit combos for a single product.
  static List<({Variants variant, UnitModel unit})> _flattenCombos(Products p) {
    final combos = <({Variants variant, UnitModel unit})>[];
    for (final v in p.variants ?? <Variants>[]) {
      for (final u in v.units ?? <UnitModel>[]) {
        combos.add((variant: v, unit: u));
      }
    }
    return combos;
  }

  void _onClearPendingBarcodeProduct(
    CartClearPendingBarcodeProduct event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(clearPendingBarcodeProduct: true));
  }

  void _onClearBarcodeError(
    CartClearBarcodeError event,
    Emitter<CartState> emit,
  ) {
    emit(state.copyWith(clearBarcodeError: true));
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

    final isOnline = await ConnectivityService.instance.checkConnectivity();

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
    if (!ConnectivityService.instance.isOnline) {
      _log.w('Sync requested but still offline');
      return;
    }

    final queue = await _pendingStorage.getQueue();
    if (queue.isEmpty) {
      _log.i('No pending sales to sync');
      return;
    }

    _log.i('Syncing ${queue.length} pending sales');
    // Always remove at index 0: after each successful removal the next
    // pending item slides into position 0, so the index never drifts.
    for (int i = 0; i < queue.length; i++) {
      final payload = queue[i];
      try {
        await _createSale.call(payload);
        await _pendingStorage.removeAt(0);
        _log.i('Synced pending sale ${i + 1}/${queue.length}');
      } catch (e, st) {
        _log.e('Failed to sync queued sale at index $i', error: e, stackTrace: st);
        // Stop on first failure to preserve ordering; next reconnect will retry
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
