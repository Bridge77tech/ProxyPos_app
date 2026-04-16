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
  static const _scannerTimeout = Duration(milliseconds: 150);

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
        // Consume this Enter so it does NOT activate whatever widget currently
        // has focus (e.g. the profile PopupMenuButton).  We only consume when
        // barcode is non-empty — an empty buffer means it is a real user Enter
        // (navigation, form submit, etc.) so we leave it alone.
        return true;
      }
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

    return false;
  }

  void _onBarcodeScanned(BarcodeScanned event, Emitter<BarcodeState> emit) {
    // Emit the barcode so all BlocListeners fire (null → value transition).
    emit(BarcodeState(scannedBarcode: event.barcode));
    // Immediately reset to null so the NEXT scan — even the same barcode —
    // produces another null → value transition and re-triggers every listener.
    emit(const BarcodeState());
  }

  @override
  Future<void> close() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    return super.close();
  }
}
