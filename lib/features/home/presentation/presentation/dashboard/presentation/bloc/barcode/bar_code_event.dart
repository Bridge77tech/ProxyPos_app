import 'package:equatable/equatable.dart';

abstract class BarcodeEvent extends Equatable {
  const BarcodeEvent();
  @override
  List<Object?> get props => [];
}

class BarcodeScanned extends BarcodeEvent {
  final String barcode;
  const BarcodeScanned(this.barcode);
  @override
  List<Object?> get props => [barcode];
}
