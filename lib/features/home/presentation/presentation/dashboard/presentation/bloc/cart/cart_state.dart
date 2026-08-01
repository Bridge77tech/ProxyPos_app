import 'package:equatable/equatable.dart';
import '../../../data/model/product_model.dart';
import '../../../data/model/variant.dart';
import '../../../data/model/unit_model.dart';

enum PaymentMethod { mobileMoney, cash }

extension PaymentMethodWire on PaymentMethod {
  /// The spelling the API expects.
  ///
  /// Deliberately not `.name`: that returns the Dart identifier, so
  /// `PaymentMethod.mobileMoney` went out as `mobileMoney` and the server
  /// rejected every mobile-money sale with "Invalid payment method". Cash worked
  /// only because its identifier happens to match. Stating the wire value here
  /// stops a rename of the enum from silently breaking sales again.
  String get wireValue => switch (this) {
        PaymentMethod.mobileMoney => 'mobile_money',
        PaymentMethod.cash => 'cash',
      };
}

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final Variants variant;
  final UnitModel unit;
  final int quantity;
  const CartItem({
    required this.productId,
    required this.productName,
    required this.variant,
    required this.unit,
    required this.quantity,
  });
  @override
  List<Object?> get props => [productId, productName, variant, unit, quantity];
}

class CartState extends Equatable {
  final List<CartItem> items;
  final Products? currentProduct;
  final Variants? selectedVariant;
  final UnitModel? selectedUnit;
  final int selectedQuantity;
  final String? error;
  final String? successMessage;
  final PaymentMethod? paymentMethod;
  final double amountReceived;
  final bool submitting;
  /// Set when a barcode scan finds a product with multiple variant/unit combos
  /// so the UI can show a picker dialog.
  final Products? pendingBarcodeProduct;
  /// Set when a barcode scan fails to find a product — shown as a snackbar.
  final String? barcodeError;

  const CartState({
    this.items = const [],
    this.currentProduct,
    this.selectedVariant,
    this.selectedUnit,
    this.selectedQuantity = 1,
    this.error,
    this.successMessage,
    this.paymentMethod,
    this.amountReceived = 0.0,
    this.submitting = false,
    this.pendingBarcodeProduct,
    this.barcodeError,
  });

  double get subTotal => items.fold(0.0, (sum, it) => sum + (it.unit.sellingPrice * it.quantity));
  double get vat => 0.0;
  double get discount => 0.0;
  double get total => subTotal + vat - discount;

  double get remaining => (total - amountReceived).clamp(0.0, double.infinity);
  double get change => (amountReceived - total).clamp(0.0, double.infinity);

  /// Whether the amount entered falls short of the total.
  ///
  /// Defined once here because both the warning under the amount field and the
  /// Submit button have to agree with each other — and with the server, which
  /// rejects an underpaid sale for every payment method.
  ///
  /// The half-pesewa tolerance matters: money is settled to two decimals, but
  /// these are binary doubles, so an exactly-correct payment can leave a residue
  /// like 4e-17 behind. Testing `remaining > 0` would call that short and leave
  /// the clerk unable to submit a sale that is, to the pesewa, paid in full.
  bool get isShortPayment => remaining > 0.005;

  CartState copyWith({
    List<CartItem>? items,
    Products? currentProduct,
    Variants? selectedVariant,
    UnitModel? selectedUnit,
    int? selectedQuantity,
    String? error,
    String? successMessage,
    PaymentMethod? paymentMethod,
    double? amountReceived,
    bool? submitting,
    Products? pendingBarcodeProduct,
    bool clearPendingBarcodeProduct = false,
    String? barcodeError,
    bool clearBarcodeError = false,
  }) {
    return CartState(
      items: items ?? this.items,
      currentProduct: currentProduct ?? this.currentProduct,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      error: error,
      successMessage: successMessage,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
      submitting: submitting ?? this.submitting,
      pendingBarcodeProduct: clearPendingBarcodeProduct ? null : (pendingBarcodeProduct ?? this.pendingBarcodeProduct),
      barcodeError: clearBarcodeError ? null : (barcodeError ?? this.barcodeError),
    );
  }

  @override
  List<Object?> get props => [items, currentProduct, selectedVariant, selectedUnit, selectedQuantity, error, successMessage, paymentMethod, amountReceived, submitting, pendingBarcodeProduct, barcodeError];
}
