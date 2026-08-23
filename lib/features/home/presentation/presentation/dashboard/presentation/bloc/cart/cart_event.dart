import 'package:equatable/equatable.dart';
import '../../../data/model/product_model.dart';
import '../../../data/model/variant.dart';
import '../../../data/model/unit_model.dart';
import 'cart_state.dart' show PaymentMethod;

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
  final UnitModel unit;
  final int quantity;
  const CartAddItem({
    required this.product,
    required this.variant,
    required this.unit,
    required this.quantity,
  });
  @override
  List<Object?> get props => [product, variant, unit, quantity];
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

/// Look up a product by barcode and add it directly to the cart.
class CartAddByBarcode extends CartEvent {
  final String barcode;
  const CartAddByBarcode(this.barcode);
  @override
  List<Object?> get props => [barcode];
}

/// Clear the pending barcode product (after picker dialog is shown).
class CartClearPendingBarcodeProduct extends CartEvent {
  const CartClearPendingBarcodeProduct();
}

/// Clear the barcode error (after snackbar is shown).
class CartClearBarcodeError extends CartEvent {
  const CartClearBarcodeError();
}

// Submit the current cart as a new sale
class CartSubmitOrder extends CartEvent {
  const CartSubmitOrder();
}

// Trigger syncing of any pending offline sales
class CartSyncPending extends CartEvent {
  const CartSyncPending();
}

class CartSelectPayment extends CartEvent {
  final PaymentMethod method;
  const CartSelectPayment(this.method);
  @override
  List<Object?> get props => [method];
}

class CartSetAmountReceived extends CartEvent {
  final double amount;
  const CartSetAmountReceived(this.amount);
  @override
  List<Object?> get props => [amount];
}

class CartSelectUnit extends CartEvent {
  final Products product;
  final Variants variant;
  final UnitModel unit;
  const CartSelectUnit({required this.product, required this.variant, required this.unit});
  @override
  List<Object?> get props => [product, variant, unit];
}

/// Re-read the pending queue onto state, so the till's queue badge reflects disk.
class CartRefreshQueue extends CartEvent {
  const CartRefreshQueue();
}

/// Retry one queued sale, clearing its held-up flag first.
///
/// Available to every role. The payload keeps the idempotency key it was created with, so the
/// worst outcome is the server returning the sale it already recorded — a retry cannot produce a
/// second sale. That is why this needs no permission check while discard and re-enter do.
class CartRetryPending extends CartEvent {
  final String queueId;
  const CartRetryPending(this.queueId);
  @override
  List<Object?> get props => [queueId];
}

/// Remove a queued sale without ever sending it. Owner-only, enforced at the UI.
class CartDiscardPending extends CartEvent {
  final String queueId;
  const CartDiscardPending(this.queueId);
  @override
  List<Object?> get props => [queueId];
}

/// Remove a queued sale from the queue so the cashier can ring it again by hand. Owner-only.
///
/// Deliberately does NOT repopulate the cart from the stored snapshot. That snapshot holds the
/// prices as they were when the sale was queued, which may be days old; re-ringing at today's
/// prices is the correct sale, and silently restoring stale ones would be a quieter kind of wrong.
class CartReenterPending extends CartEvent {
  final String queueId;
  const CartReenterPending(this.queueId);
  @override
  List<Object?> get props => [queueId];
}
