@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/update/app_version.dart';
import 'package:inventory_app_pos/core/update/update_coordinator.dart';
import 'package:inventory_app_pos/core/update/update_manifest.dart';
import 'package:inventory_app_pos/core/update/update_service.dart';

/// What the owner actually experiences at launch.
///
/// The service tests prove the right value comes back when a connection is bad.
/// These prove the consequence that matters: the till opens, nothing is put in front
/// of the shopkeeper, and the screen still works. A no-op that still manages to show
/// a red box or a toast has failed the requirement as surely as a crash would.
///
/// Two kinds of test here, deliberately:
///
///   * Ones that drive a **real socket**, wrapped in `tester.runAsync` because the
///     widget-test binding fakes the event loop and real I/O would never complete
///     inside it. These are the honest offline proofs.
///   * Ones that use a **stubbed check** so the dialog can be pumped under the fake
///     clock. These prove the UI behaviour that a real socket cannot reach from here.
void main() {
  const current = AppVersion(1, 1, 0);

  Widget host({
    required GlobalKey<NavigatorState> navigatorKey,
    required VoidCallback onTap,
  }) {
    return ScreenUtilInit(
      designSize: const Size(1025, 768),
      builder: (context, _) => MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('sell-button'),
              onPressed: onTap,
              child: const Text('New sale'),
            ),
          ),
        ),
      ),
    );
  }

  void expectNothingShown(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    // The words a failed check would leak if it ever surfaced one.
    for (final word in ['rror', 'ailed', 'onnection', 'pdate']) {
      expect(find.textContaining(word), findsNothing, reason: 'leaked "$word"');
    }
  }

  Future<int> deadPort() async {
    final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    return port;
  }

  group('offline, against real sockets', () {
    testWidgets('a refused connection: the till opens, shows nothing, still works',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      var taps = 0;

      await tester.pumpWidget(
        host(navigatorKey: navigatorKey, onTap: () => taps++),
      );
      await tester.pumpAndSettle();

      // The screen is already up and usable before the check is even attempted —
      // which is the structural guarantee app.dart provides by not awaiting it.
      await tester.tap(find.byKey(const Key('sell-button')));
      await tester.pump();
      expect(taps, 1);

      await tester.runAsync(() async {
        final port = await deadPort();
        await UpdateCoordinator.maybePrompt(
          navigatorKey.currentContext!,
          service: UpdateService(
            currentVersion: current,
            pointerUrls: ['http://127.0.0.1:$port/latest.json'],
            pointerTimeout: const Duration(milliseconds: 500),
          ),
        );
      });
      await tester.pumpAndSettle();

      expectNothingShown(tester);

      await tester.tap(find.byKey(const Key('sell-button')));
      await tester.pump();
      expect(taps, 2);
    });

    testWidgets('a host that does not resolve shows nothing', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(host(navigatorKey: navigatorKey, onTap: () {}));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await UpdateCoordinator.maybePrompt(
          navigatorKey.currentContext!,
          service: UpdateService(
            currentVersion: current,
            pointerUrls: [
              'https://this-host-does-not-exist.proxypos-invalid/latest.json',
            ],
            pointerTimeout: const Duration(milliseconds: 500),
          ),
        );
      });
      await tester.pumpAndSettle();

      expectNothingShown(tester);
    });

    testWidgets('a connection that opens and never answers gives up on its own',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(host(navigatorKey: navigatorKey, onTap: () {}));
      await tester.pumpAndSettle();

      late Duration elapsed;
      await tester.runAsync(() async {
        // Accepts the socket and says nothing. Nothing reports an error here —
        // without a receive timeout this is precisely where a launch hangs.
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        unawaited(server.forEach((_) {}));

        final stopwatch = Stopwatch()..start();
        await UpdateCoordinator.maybePrompt(
          navigatorKey.currentContext!,
          service: UpdateService(
            currentVersion: current,
            pointerUrls: ['http://127.0.0.1:${server.port}/latest.json'],
            pointerTimeout: const Duration(milliseconds: 500),
          ),
        );
        elapsed = stopwatch.elapsed;
        await server.close(force: true);
      });
      await tester.pumpAndSettle();

      expect(elapsed, lessThan(const Duration(seconds: 5)));
      expectNothingShown(tester);
    });

    testWidgets('a captive portal login page shows nothing', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(host(navigatorKey: navigatorKey, onTap: () {}));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        unawaited(server.forEach((request) async {
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write('<html><body>Sign in to use this network</body></html>');
          await request.response.close();
        }));

        await UpdateCoordinator.maybePrompt(
          navigatorKey.currentContext!,
          service: UpdateService(
            currentVersion: current,
            pointerUrls: ['http://127.0.0.1:${server.port}/latest.json'],
            pointerTimeout: const Duration(seconds: 2),
          ),
        );
        await server.close(force: true);
      });
      await tester.pumpAndSettle();

      expectNothingShown(tester);
    });
  });

  group('the decision, as the owner sees it', () {
    testWidgets('a newer version asks before doing anything', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(host(navigatorKey: navigatorKey, onTap: () {}));
      await tester.pumpAndSettle();

      final pending = UpdateCoordinator.maybePrompt(
        navigatorKey.currentContext!,
        service: _StubService(
          currentVersion: current,
          manifest: _manifest('1.2.0', notes: 'Expiry warnings on the till.'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('update-dialog-title')), findsOneWidget);
      expect(find.textContaining('1.2.0'), findsWidgets);
      expect(find.text('Expiry warnings on the till.'), findsOneWidget);
      // The owner is told the till will close before they agree, not after.
      expect(find.byKey(const Key('update-dialog-warning')), findsOneWidget);
      // Nothing has been downloaded or run; it is a question, not a notification.
      expect(find.byKey(const Key('update-install-now')), findsOneWidget);
      expect(find.byKey(const Key('update-later')), findsOneWidget);

      await tester.tap(find.byKey(const Key('update-later')));
      await tester.pumpAndSettle();
      await pending;

      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the same version asks nothing', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(host(navigatorKey: navigatorKey, onTap: () {}));
      await tester.pumpAndSettle();

      await UpdateCoordinator.maybePrompt(
        navigatorKey.currentContext!,
        service: _StubService(currentVersion: current, manifest: null),
      );
      await tester.pumpAndSettle();

      expectNothingShown(tester);
    });

    testWidgets('the till stays usable while the check is still outstanding',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      var taps = 0;
      await tester.pumpWidget(
        host(navigatorKey: navigatorKey, onTap: () => taps++),
      );
      await tester.pumpAndSettle();

      final slow = Completer<UpdateManifest?>();
      final pending = UpdateCoordinator.maybePrompt(
        navigatorKey.currentContext!,
        service: _StubService.pending(currentVersion: current, result: slow.future),
      );
      await tester.pump();

      // Mid-check: no dialog, no block, and the shopkeeper can start selling.
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byKey(const Key('sell-button')));
      await tester.pump();
      expect(taps, 1);

      slow.complete(null);
      await pending;
      await tester.pumpAndSettle();
      expectNothingShown(tester);
    });

    testWidgets('a check that throws is swallowed rather than shown',
        (tester) async {
      // Defence in depth. check() is written never to throw, but the coordinator
      // must not rely on that being true forever — a bug there must not put a red
      // screen on a till.
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(host(navigatorKey: navigatorKey, onTap: () {}));
      await tester.pumpAndSettle();

      await UpdateCoordinator.maybePrompt(
        navigatorKey.currentContext!,
        service: _StubService.throwing(currentVersion: current),
      );
      await tester.pumpAndSettle();

      expectNothingShown(tester);
    });
  });
}

UpdateManifest _manifest(String version, {String? notes}) => UpdateManifest(
      version: AppVersion.tryParse(version)!,
      url: 'https://example.test/inventory_pos-$version.exe',
      sha256: 'c' * 64,
      size: 1024,
      notes: notes,
    );

/// Replaces only the network call, so the coordinator and the real dialog are the
/// code under test rather than a reimplementation of them.
class _StubService extends UpdateService {
  _StubService({required super.currentVersion, required UpdateManifest? manifest})
      : _result = Future.value(manifest),
        _throws = false;

  _StubService.pending({
    required super.currentVersion,
    required Future<UpdateManifest?> result,
  })  : _result = result,
        _throws = false;

  _StubService.throwing({required super.currentVersion})
      : _result = Future.value(null),
        _throws = true;

  final Future<UpdateManifest?> _result;
  final bool _throws;

  @override
  Future<UpdateManifest?> check() {
    if (_throws) throw StateError('the check blew up');
    return _result;
  }
}
