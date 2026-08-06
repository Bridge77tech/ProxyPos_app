import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Covers the till after a period with no input (Figma node 1724:2283).
///
/// Deliberately not a logout. The session runs for eight hours so a cashier who
/// steps away comes back to their work — and, importantly, to any sales still
/// queued from an offline stretch — rather than to a login form. Nothing behind the
/// cover is torn down: no timers cancelled, no cart cleared, no state discarded.
///
/// Wraps the authenticated shell, so it can never appear over the login screen.
class IdleScreensaver extends StatefulWidget {
  const IdleScreensaver({super.key, required this.child});

  final Widget child;

  /// Idle time before the cover appears.
  ///
  /// Any pointer movement or key press clears it instantly and nothing behind it is
  /// disturbed — the session itself runs for eight hours regardless.
  static const Duration idleAfter = Duration(minutes: 5);

  @override
  State<IdleScreensaver> createState() => _IdleScreensaverState();
}

class _IdleScreensaverState extends State<IdleScreensaver> {
  /// Shop types listed beneath the wordmark, in the order the design sets out.
  static const _audiences = <String>[
    'Supermarkets',
    'Retail Shops',
    'Wholesale Shops',
    'Electronics Shops',
    'General Goods Shops',
  ];

  Timer? _timer;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    // A global hook rather than a Focus node: a key press should wake the till
    // whatever happens to hold focus, including nothing at all.
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    super.dispose();
  }

  /// Returns true to swallow the key that dismissed the cover, so the keystroke
  /// that wakes the screen cannot also type into a field the cashier can't see.
  bool _onKey(KeyEvent event) {
    final wasShowing = _showing;
    _wake();
    return wasShowing;
  }

  void _wake() {
    if (_showing) setState(() => _showing = false);
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer(IdleScreensaver.idleAfter, () {
      if (mounted) setState(() => _showing = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _wake(),
      onPointerMove: (_) => _wake(),
      onPointerHover: (_) => _wake(),
      onPointerSignal: (_) => _wake(),
      child: Stack(
        children: [
          widget.child,
          if (_showing) Positioned.fill(child: _cover()),
        ],
      ),
    );
  }

  Widget _cover() {
    // Material, not a ColoredBox. This widget wraps the Scaffold, so the cover sits
    // above every Material in the tree — and without one, WidgetsApp's fallback
    // DefaultTextStyle applies: black text with a double yellow underline, its debug
    // label literally "consider putting your text in a Material". An explicit
    // TextStyle doesn't escape it, because Text merges with the inherited style and
    // so keeps the decoration. Material supplies the proper text style and the
    // theme's Satoshi font as well as an opaque canvas.
    //
    // Opaque hit testing so the tap that dismisses the cover stops here instead of
    // pressing whatever sits beneath it.
    return MouseRegion(
      cursor: SystemMouseCursors.none,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _wake(),
        child: Material(
          color: Colors.white,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/proxypos-wordmark.png',
                      height: 78.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 30.h),
                    _audienceRow(),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40.h,
                child: Text(
                  'A product of Bridge77 Technologies',
                  textAlign: TextAlign.center,
                  style: _labelStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 16px black Satoshi, matching the design. Decoration cleared explicitly.
  TextStyle _labelStyle(BuildContext context) {
    return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
        .copyWith(
          fontSize: 16.sp,
          color: Colors.black,
          decoration: TextDecoration.none,
        );
  }

  Widget _audienceRow() {
    final children = <Widget>[];
    for (var i = 0; i < _audiences.length; i++) {
      children.add(Text(_audiences[i], style: _labelStyle(context)));
      if (i < _audiences.length - 1) {
        // A plain hairline in the design, so a sized box rather than an exported
        // asset — there is no glyph here to reproduce.
        children.add(
          Container(
            width: 1,
            height: 18.h,
            color: Colors.black.withValues(alpha: 0.25),
          ),
        );
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10.w,
      runSpacing: 10.h,
      children: children,
    );
  }
}
