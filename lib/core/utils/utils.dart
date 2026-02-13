import 'package:flutter/material.dart';

class Utils {
  Utils._();
  /// Shows an overlay dialog with the provided child widget.
  /// Returns a Future that completes when the dialog is dismissed.
  static Future<T?> showOverlayDialog<T>(BuildContext context, {required Widget child, bool useRootNavigator = true}) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: useRootNavigator,
      builder: (ctx) {
        return AboutDialog(
          children: [
            child,
          ],
        );
      },
    );
  }
}