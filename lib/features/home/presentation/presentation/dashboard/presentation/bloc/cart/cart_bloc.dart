import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import 'package:inventory_app_pos/core/routing/navigation_helper.dart';
import 'package:inventory_app_pos/core/services/background_sync_scope.dart';
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
import 'cart_state.dart' show CartState, CartItem, PaymentMethodWire;

/// Random v4-style identifier, used as a sale's idempotency key.
///
/// Generated once per sale — before the first submit attempt — and reused on every
/// retry, so replaying a queued offline sale is recognised by the server instead
/// of creating a second sale. Uses Random.secure() to make collisions between
/// devices a non-issue. Hand-rolled rather than adding a `uuid` dependency for
/// one call site.
String _generateIdempotencyKey() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
      '-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class CartBloc extends Bloc<CartEvent, CartState> {
  final _log = getLogger('CartBloc');
  final CreateSaleUseCase _createSale;
  final PendingSalesStorage _pendingStorage;
  StreamSubscription<bool>? _connectivitySub;

  // TextEditingController for amount input
  late final TextEditingController amountController;

  // In-memory product cache — avoids Hive disk read + full JSON parse on every scan.
  List<Products>? _productsCache;

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

  /// Individual items one line consumes.
  ///
  /// `individualPieces` is already 1 for a Single and the pack size for a Pack, so
  /// this is uniform. Stock is only ever counted in individual items, which is why
  /// a pack of 12 draws 12 — the same arithmetic the server applies when it
  /// deducts stock.
  int _baseUnits(UnitModel unit, int quantity) {
    final per = unit.individualPieces <= 0 ? 1.0 : unit.individualPieces;
    return (per * quantity).round();
  }

  /// Individual items of [variant] already committed across the whole cart.
  ///
  /// Summed across units rather than per unit: a Single line and a Pack line of the
  /// same variant draw on one shared pool, so checking either in isolation would
  /// let the two together oversell.
  int _committedBaseUnits(Variants variant, {int? ignoreIndex}) {
    var total = 0;
    for (var i = 0; i < state.items.length; i++) {
      if (i == ignoreIndex) continue;
      final it = state.items[i];
      if (it.variant.id != variant.id) continue;
      total += _baseUnits(it.unit, it.quantity);
    }
    return total;
  }

  /// Why [quantity] of [unit] cannot be added, or null when it can.
  ///
  /// The cart used to accept any quantity up to 999 with no reference to stock, so
  /// a clerk could ring up 4 bottles when 2 remained and only find out at checkout,
  /// where the server refuses the sale with the customer already waiting.
  String? _stockShortfall(
    String productName,
    Variants variant,
    UnitModel unit,
    int quantity, {
    int? ignoreIndex,
  }) {
    final available = (variant.currentStock ?? 0).round();
    final committed = _committedBaseUnits(variant, ignoreIndex: ignoreIndex);
    final wanted = _baseUnits(unit, quantity);
    if (committed + wanted <= available) return null;

    final label = (variant.name != null && variant.name!.trim().isNotEmpty)
        ? '$productName — ${variant.name!.trim()}'
        : productName;
    final left = (available - committed).clamp(0, available);

    final parts = <String>[
      committed > 0
          ? 'Only $left of $label left ($available in stock, $committed already in the cart).'
          : 'Only $available of $label in stock.',
    ];
    if (wanted > quantity) {
      // A pack draws more than its line quantity, which is not obvious.
      parts.add('$quantity × ${unit.type} needs $wanted.');
    }
    return parts.join(' ');
  }

  void _onAddItem(CartAddItem event, Emitter<CartState> emit) {
    try {
      final productId = event.product.id?.toString() ?? '';
      final productName = event.product.name ?? '';
      final v = event.variant;
      final u = event.unit;

      final shortfall = _stockShortfall(productName, v, u, event.quantity);
      if (shortfall != null) {
        _log.w('Refused add to cart — $shortfall');
        emit(state.copyWith(error: shortfall));
        return;
      }

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
      // 1. Lazily populate in-memory cache from Hive once.
      //    Subsequent scans search RAM only — no disk I/O, no JSON parse.
      if (_productsCache == null) {
        final allModel = await AllProductsStorageImpl.instance.getAllProducts();
        _productsCache = allModel?.products ?? const [];
        _log.i('Products cache loaded: ${_productsCache!.length} items');
      }

      var hit = _findUnitByBarcode(_productsCache!, barcode);

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
            _productsCache = [..._productsCache!, ...remoteProducts];
            await AllProductsStorageImpl.instance.saveAllProducts(remoteModel);
            emit(state.copyWith(pendingBarcodeProduct: p));
            return;
          }
        }

        if (hit != null) {
          // Merge new products into the in-memory cache so the next scan of
          // any product in this batch is also instant.
          _productsCache = [..._productsCache!, ...remoteProducts];
          await AllProductsStorageImpl.instance.saveAllProducts(remoteModel);
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
        // Identifies the exact unit sold. Required once a variant carries more
        // than one pack size, where saleType alone can't tell a 12-pack from a
        // 24-pack, and the server refuses rather than guess. Omitted entirely
        // (not sent as null) when absent, since product data cached by an older
        // build has no unit ids and the server validates the field when present.
        if (it.unit.id != null && it.unit.id!.isNotEmpty)
          'variantUnitId': it.unit.id,
        // Always sent: it's the fallback the server uses when there's no unit id.
        'saleType': it.unit.type,
      }).toList(),
      'amountPaid': state.amountReceived,
      'paymentMethod': state.paymentMethod?.wireValue,
      'deviceId': "POS-TABLET-001",
      // Generated once here and stored with the queued payload, so every retry
      // carries the SAME key. Without it, a crash between a successful submit and
      // dequeuing would replay the sale and charge the customer twice.
      'idempotencyKey': _generateIdempotencyKey(),
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
        // Success — clear cart and invalidate product cache so the next
        // barcode scan fetches updated stock counts.
        _productsCache = null;
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
        // Marked as background so an expired token reports a failure instead of
        // logging the clerk out — see BackgroundSyncScope.
        await BackgroundSyncScope.run(() => _createSale.call(payload));
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

      // Only when going up: reducing a line can never oversell. The line itself is
      // excluded from the committed total, since nextQty replaces it.
      if (event.delta > 0) {
        final shortfall = _stockShortfall(
          existing.productName,
          existing.variant,
          existing.unit,
          nextQty,
          ignoreIndex: event.index,
        );
        if (shortfall != null) {
          emit(state.copyWith(error: shortfall));
          return;
        }
      }

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
