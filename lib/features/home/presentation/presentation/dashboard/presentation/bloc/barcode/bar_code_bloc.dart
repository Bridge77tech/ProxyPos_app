import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';

import 'bar_code_event.dart';
import 'bar_code_state.dart';

class BarcodeBloc extends Bloc<BarcodeEvent, BarcodeState> {
  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastKeyTime;

  /// Barcode scanners fire all characters within a few milliseconds.
  /// If the gap between keystrokes exceeds this threshold, the buffer is
  /// treated as stale manual input and is cleared before accumulating again.
  static const _scannerTimeout = Duration(milliseconds: 50);

  BarcodeBloc() : super(const BarcodeState()) {
    on<BarcodeScanned>(_onBarcodeScanned);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    // Only react to key-down events
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      final barcode = _buffer.toString().trim();
      _buffer.clear();
      _lastKeyTime = null;

      if (barcode.isNotEmpty) {
        add(BarcodeScanned(barcode));
      }
      // Don't consume — let the Enter key work normally elsewhere too
      return false;
    }

    // If too long since last keystroke, assume user typed manually → reset buffer
    if (_lastKeyTime != null && now.difference(_lastKeyTime!) > _scannerTimeout) {
      _buffer.clear();
    }

    final char = event.character;
    if (char != null && char.isNotEmpty) {
      _buffer.write(char);
      _lastKeyTime = now;
    }

    return false; // don't consume — allow normal keyboard input
  }

  void _onBarcodeScanned(BarcodeScanned event, Emitter<BarcodeState> emit) {
    emit(BarcodeState(scannedBarcode: event.barcode));
  }

  @override
  Future<void> close() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    return super.close();
  }
}
