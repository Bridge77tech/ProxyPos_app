import 'package:flutter/cupertino.dart';

class APNavigatorKeys {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final shellNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: "shell router key",
  );
}
