import 'package:bloc/bloc.dart';
import 'package:fasaha_utils/utils_export/fasaha_huas_logger_export.dart';
import '../../data/model/variant.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final _log = getLogger('CartBloc');

  CartBloc() : super(const CartState()) {
    on<CartSelectVariant>(_onSelectVariant);
    on<CartChangeQuantity>(_onChangeQuantity);
    on<CartSetQuantity>(_onSetQuantity);
    on<CartAddItem>(_onAddItem);
    on<CartRemoveItem>(_onRemoveItem);
    on<CartUpdateItemQuantity>(_onUpdateItemQuantity);
    on<CartClear>(_onClear);
    on<CartResetSelection>(_onResetSelection);
  }

  void _onSelectVariant(CartSelectVariant event, Emitter<CartState> emit) {
    emit(state.copyWith(currentProduct: event.product, selectedVariant: event.variant));
    _log.i('Selected variant: ${event.variant.type} (${event.variant.size}) of ${event.product.name}');
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

      // Merge with existing if same productId + variant signature
      final items = List<CartItem>.from(state.items);
      final idx = items.indexWhere((it) => it.productId == productId && _sameVariant(it.variant, v));
      if (idx >= 0) {
        final existing = items[idx];
        items[idx] = CartItem(
          productId: existing.productId,
          productName: existing.productName,
          variant: existing.variant,
          quantity: (existing.quantity + event.quantity).clamp(1, 999),
        );
      } else {
        items.add(CartItem(
          productId: productId,
          productName: productName,
          variant: v,
          quantity: event.quantity,
        ));
      }
      emit(state.copyWith(items: items, selectedQuantity: 0, selectedVariant: null, currentProduct: null));
      _log.i('Added to cart: $productName (${v.type} ${v.size}) x${event.quantity}');
    } catch (e, st) {
      _log.e('Add to cart failed', error: e, stackTrace: st);
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onSubmitOrder(CartEvent event, Emitter<CartState> emit) {
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
        quantity: nextQty,
      );
      emit(state.copyWith(items: items));
    }
  }

  void _onClear(CartClear event, Emitter<CartState> emit) {
    emit(state.copyWith(items: []));
  }

  void _onResetSelection(CartResetSelection event, Emitter<CartState> emit) {
    // Reset selected quantity and variant back to initial
    emit(state.copyWith(selectedQuantity: 0, selectedVariant: null, currentProduct: null));
    _log.i('Selection reset after add-to-cart');
  }

  bool _sameVariant(Variants a, Variants b) {
    return a.type == b.type && a.size == b.size && a.sellingPrice == b.sellingPrice;
  }
}
