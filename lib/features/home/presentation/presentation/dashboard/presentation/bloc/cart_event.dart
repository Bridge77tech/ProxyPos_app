import 'package:equatable/equatable.dart';
import '../../data/model/product_model.dart';
import '../../data/model/variant.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartSelectVariant extends CartEvent {
  final Products product;
  final Variants variant;
  const CartSelectVariant({required this.product, required this.variant});
  @override
  List<Object?> get props => [product, variant];
}

class CartChangeQuantity extends CartEvent {
  final int delta; // +1 or -1
  const CartChangeQuantity(this.delta);
  @override
  List<Object?> get props => [delta];
}

class CartSetQuantity extends CartEvent {
  final int quantity;
  const CartSetQuantity(this.quantity);
  @override
  List<Object?> get props => [quantity];
}

class CartAddItem extends CartEvent {
  final Products product;
  final Variants variant;
  final int quantity;
  const CartAddItem({required this.product, required this.variant, required this.quantity});
  @override
  List<Object?> get props => [product, variant, quantity];
}

class CartRemoveItem extends CartEvent {
  final int index;
  const CartRemoveItem(this.index);
  @override
  List<Object?> get props => [index];
}

class CartUpdateItemQuantity extends CartEvent {
  final int index;
  final int delta;
  const CartUpdateItemQuantity(this.index, this.delta);
  @override
  List<Object?> get props => [index, delta];
}

class CartClear extends CartEvent {
  const CartClear();
}

// Reset current selection (variant + quantity) after add to cart
class CartResetSelection extends CartEvent {
  const CartResetSelection();
}

class SubmitOrder extends CartEvent {
  final Products products;
  final Variants variant;
  final int quantity;

  const SubmitOrder({
    required this.products,
    required this.variant,
    required this.quantity,
  });

  @override
  List<Object?> get props => [products, variant, quantity];
}
