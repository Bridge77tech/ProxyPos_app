@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_app_pos/core/update/app_version.dart';
import 'package:inventory_app_pos/core/update/update_coordinator.dart';
import 'package:inventory_app_pos/core/update/update_log.dart' as log;
import 'package:inventory_app_pos/core/update/update_manifest.dart';
import 'package:inventory_app_pos/core/update/update_service.dart';

/// Does the check actually fire?
///
/// Everything else about the updater was tested — the decision logic, the offline
/// paths against real sockets, the download, the hash, a live run against GitHub — and
/// all of it passed while the check never ran once on a real till.
///
/// The gap was the wiring. app.dart read the root Navigator's context in a single
/// post-frame callback and returned if it was null, and it was null every time: the
/// route guard redirects through an async token read, so go_router has nothing to
/// build on the first frame. A verified manifest, at a verified URL, with a verified
/// hash, and no prompt, and nothing anywhere saying why.
///
/// These tests are the ones that would have caught it. They assert the *arrival* of
/// the check rather than its contents.
void main() {
  const current = AppVersion(1, 2, 0);

  /// The real shape of the app's routing: a root navigatorKey plus an async redirect.
  GoRouter routerLike(GlobalKey<NavigatorState> key) => GoRouter(
        navigatorKey: key,
        initialLocation: '/login',
        redirect: (context, state) async {
          // Stands in for TokenValidator.hasValidToken() reading secure storage.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, __) => const Scaffold(body: Center(child: Text('login'))),
          ),
        ],
      );

  Widget app(GlobalKey<NavigatorState> key) => ScreenUtilInit(
        designSize: const Size(1025, 768),
        builder: (context, _) => MaterialApp.router(routerConfig: routerLike(key)),
      );

  testWidgets('the root navigator is NOT available on the first frame', (tester) async {
    // The fact the old wiring depended on, and got wrong. If this ever starts
    // failing, go_router has changed and the waiting below can be simplified — but
    // nothing should go back to reading the context once.
    final key = GlobalKey<NavigatorState>();
    BuildContext? atFirstFrame;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      atFirstFrame = key.currentContext;
    });

    await tester.pumpWidget(app(key));
    await tester.pump();

    expect(atFirstFrame, isNull,
        reason: 'if this is non-null the old wiring would have worked');

    await tester.pumpAndSettle();
    expect(key.currentContext, isNotNull, reason: 'it does arrive, just later');
  });

  testWidgets('scheduleAtLaunch waits, and the check does reach the owner',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    final stub = _StubService(
      currentVersion: current,
      manifest: UpdateManifest(
        version: const AppVersion(1, 2, 1),
        url: 'https://example.test/ProxyPOS-1.2.1.exe',
        sha256: 'd' * 64,
        size: 1024,
      ),
    );

    await tester.pumpWidget(app(key));
    UpdateCoordinator.scheduleAtLaunch(key, service: stub);

    // The navigator is not there yet, so nothing has been asked.
    expect(stub.checked, isFalse);

    // Let the guard resolve and the poll find it.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(stub.checked, isTrue, reason: 'the check must actually fire');
    expect(find.byKey(const Key('update-dialog-title')), findsOneWidget,
        reason: 'and the owner must see the prompt');
    expect(find.textContaining('1.2.1'), findsWidgets);

    await tester.tap(find.byKey(const Key('update-later')));
    await tester.pumpAndSettle();
  });

  testWidgets('it checks once, and does not come back mid-session', (tester) async {
    // The guarantee the fix must not have broken: the poll is for finding the
    // navigator, not for re-checking. Once it fires it is cancelled for good.
    final key = GlobalKey<NavigatorState>();
    final stub = _StubService(currentVersion: current, manifest: null);

    await tester.pumpWidget(app(key));
    UpdateCoordinator.scheduleAtLaunch(key, service: stub);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(stub.checkCount, 1);

    // A long session, with frames happening throughout.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 30));
    }

    expect(stub.checkCount, 1, reason: 'a second check would be a prompt mid-sale');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a navigator that never arrives gives up without breaking anything',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    final stub = _StubService(currentVersion: current, manifest: null);

    // No router at all, so the key is never attached.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('no router'))));
    UpdateCoordinator.scheduleAtLaunch(key, service: stub);

    await tester.pumpAndSettle(const Duration(seconds: 25));

    expect(stub.checked, isFalse);
    expect(tester.takeException(), isNull);
    expect(find.text('no router'), findsOneWidget);
  });

  test('the log writes somewhere real, and never throws', () {
    // It exists because a Windows release build has no console. If it cannot write it
    // must still not break a launch.
    final path = log.UpdateLog.path;
    expect(path, isNotNull);
    log.UpdateLog.write('test line');
    expect(File(path!).existsSync(), isTrue);
  });
}

/// Replaces only the network call, so the wiring and the real dialog are what is
/// under test.
class _StubService extends UpdateService {
  _StubService({required super.currentVersion, required this.manifest});

  final UpdateManifest? manifest;
  int checkCount = 0;
  bool get checked => checkCount > 0;

  @override
  Future<UpdateManifest?> check() async {
    checkCount++;
    return manifest;
  }
}
