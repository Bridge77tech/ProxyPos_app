import 'package:equatable/equatable.dart';

class BarcodeState extends Equatable {
  final String? scannedBarcode;

  const BarcodeState({this.scannedBarcode});

  BarcodeState copyWith({String? scannedBarcode}) {
    return BarcodeState(scannedBarcode: scannedBarcode ?? this.scannedBarcode);
  }

  @override
  List<Object?> get props => [scannedBarcode];
}
