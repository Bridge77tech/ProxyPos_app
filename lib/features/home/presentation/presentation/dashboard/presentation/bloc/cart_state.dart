import 'package:equatable/equatable.dart';
import '../../data/model/product_model.dart';
import '../../data/model/variant.dart';

enum PaymentMethod { mobileMoney, cash }

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final Variants variant;
  final int quantity;
  const CartItem({required this.productId, required this.productName, required this.variant, required this.quantity});
  @override
  List<Object?> get props => [productId, productName, variant, quantity];
}

class CartState extends Equatable {
  final List<CartItem> items;
  final Products? currentProduct;
  final Variants? selectedVariant;
  final int selectedQuantity;
  final String? error;
  final String? successMessage;
  final PaymentMethod? paymentMethod;
  final double amountReceived;
  final bool submitting;

  const CartState({
    this.items = const [],
    this.currentProduct,
    this.selectedVariant,
    this.selectedQuantity = 1,
    this.error,
    this.successMessage,
    this.paymentMethod,
    this.amountReceived = 0.0,
    this.submitting = false,
  });

  double get subTotal => items.fold(0.0, (sum, it) => sum + ((it.variant.sellingPrice ?? 0) * it.quantity));
  double get vat => 0.0; // hook up if needed
  double get discount => 0.0; // hook up if needed
  double get total => subTotal + vat - discount;

  double get remaining => (total - amountReceived).clamp(0.0, double.infinity);
  double get change => (amountReceived - total).clamp(0.0, double.infinity);

  CartState copyWith({
    List<CartItem>? items,
    Products? currentProduct,
    Variants? selectedVariant,
    int? selectedQuantity,
    String? error,
    String? successMessage,
    PaymentMethod? paymentMethod,
    double? amountReceived,
    bool? submitting,
  }) {
    return CartState(
      items: items ?? this.items,
      currentProduct: currentProduct ?? this.currentProduct,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      error: error,
      successMessage: successMessage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      submitting: submitting ?? this.submitting,
    );
  }

  @override
  List<Object?> get props => [items, currentProduct, selectedVariant, selectedQuantity, error, successMessage, paymentMethod, amountReceived, submitting];
}
