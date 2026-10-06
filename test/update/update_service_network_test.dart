@Timeout(Duration(seconds: 60))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/update/app_version.dart';
import 'package:inventory_app_pos/core/update/update_manifest.dart';
import 'package:inventory_app_pos/core/update/update_service.dart';

/// These tests talk to a real HttpServer over a real socket on localhost.
///
/// Nothing here is mocked, and that is the entire point. An updater that degrades
/// politely against a stubbed client and then hangs the launch of a till on a shop's
/// actual connection is the failure this product cannot afford. A mock cannot refuse
/// a connection, accept one and then say nothing, hang up halfway through a body, or
/// answer a manifest request with a login page — which is the complete list of what
/// these shops' connections do every day.
void main() {
  const current = AppVersion(1, 1, 0);
  late Directory downloads;

  setUp(() async {
    downloads = await Directory.systemTemp.createTemp('proxypos-update-test');
  });

  tearDown(() async {
    if (await downloads.exists()) await downloads.delete(recursive: true);
  });

  /// Serves one canned response and reports what was asked of it.
  Future<HttpServer> serve(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(server.forEach((request) async {
      try {
        await handler(request);
      } catch (_) {
        // A handler that blows up after hanging up is not the test's concern.
      }
    }));
    addTearDown(() => server.close(force: true));
    return server;
  }

  String origin(HttpServer server) => 'http://127.0.0.1:${server.port}';

  String manifestJson({
    required String version,
    required String url,
    required String sha256,
    int? size,
  }) =>
      jsonEncode({
        'schema': 1,
        'version': version,
        'url': url,
        'sha256': sha256,
        if (size != null) 'size': size,
      });

  UpdateService serviceFor(
    List<String> pointers, {
    Duration timeout = const Duration(milliseconds: 600),
  }) =>
      UpdateService(
        currentVersion: current,
        pointerUrls: pointers,
        downloadDirectory: downloads,
        pointerTimeout: timeout,
      );

  group('check() never fails loudly', () {
    test('a refused connection is a silent no-op', () async {
      // Bind and immediately release a port so the number is real but nothing is
      // listening — a host that is down, rather than one that does not exist.
      final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = probe.port;
      await probe.close();

      final service = serviceFor(['http://127.0.0.1:$deadPort/latest.json']);

      expect(await service.check(), isNull);
    });

    test('a host that does not resolve is a silent no-op', () async {
      final service = serviceFor([
        'https://this-host-does-not-exist.proxypos-invalid/latest.json',
      ]);

      expect(await service.check(), isNull);
    });

    test('a connection that opens and then says nothing times out quietly',
        () async {
      // The worst real-world case and the one a mock cannot reproduce: the TCP
      // handshake succeeds, so nothing reports an error, and the socket then sits
      // there. Without a receive timeout this is where a launch hangs forever.
      final server = await serve((request) async {
        // Never respond. Never close.
      });

      final service = serviceFor(['${origin(server)}/latest.json']);

      final stopwatch = Stopwatch()..start();
      expect(await service.check(), isNull);
      stopwatch.stop();

      // Bounded by the timeout, not by the server's patience.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('a captive portal login page is a silent no-op', () async {
      // 200 OK with HTML. The status code says everything is fine; the body is a
      // hotel wifi sign-in form.
      final server = await serve((request) async {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('<html><body>Please sign in to continue</body></html>');
        await request.response.close();
      });

      expect(await serviceFor(['${origin(server)}/latest.json']).check(), isNull);
    });

    test('a 500 is a silent no-op', () async {
      final server = await serve((request) async {
        request.response.statusCode = 500;
        await request.response.close();
      });

      expect(await serviceFor(['${origin(server)}/latest.json']).check(), isNull);
    });

    test('a truncated body is a silent no-op', () async {
      final server = await serve((request) async {
        request.response
          ..statusCode = 200
          ..write('{"schema":1,"version":"1.9.0","url":"https://e.test/a.e');
        await request.response.close();
      });

      expect(await serviceFor(['${origin(server)}/latest.json']).check(), isNull);
    });
  });

  group('check() decision logic', () {
    test('a newer version is offered', () async {
      final server = await serve((request) async {
        request.response
          ..statusCode = 200
          ..write(manifestJson(
            version: '1.2.0',
            url: 'https://example.test/inventory_pos-1.2.0.exe',
            sha256: 'b' * 64,
          ));
        await request.response.close();
      });

      final manifest = await serviceFor(['${origin(server)}/latest.json']).check();

      expect(manifest, isNotNull);
      expect(manifest!.version, const AppVersion(1, 2, 0));
    });

    test('the same version offers nothing', () async {
      final server = await serve((request) async {
        request.response
          ..statusCode = 200
          ..write(manifestJson(
            version: '1.1.0',
            url: 'https://example.test/a.exe',
            sha256: 'b' * 64,
          ));
        await request.response.close();
      });

      expect(await serviceFor(['${origin(server)}/latest.json']).check(), isNull);
    });

    test('an older version offers nothing', () async {
      // A rollback must not be delivered as an update. If a bad release has to be
      // withdrawn, tills stay where they are until a higher number is published.
      final server = await serve((request) async {
        request.response
          ..statusCode = 200
          ..write(manifestJson(
            version: '1.0.0',
            url: 'https://example.test/a.exe',
            sha256: 'b' * 64,
          ));
        await request.response.close();
      });

      expect(await serviceFor(['${origin(server)}/latest.json']).check(), isNull);
    });
  });

  group('the fallback list is what keeps a till from being stranded', () {
    test('a dead primary falls through to the secondary', () async {
      // This is the domain-stability design under test. If the first pointer is
      // gone — lapsed domain, moved host, rebrand — the till still finds its update.
      final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final deadPort = probe.port;
      await probe.close();

      final secondary = await serve((request) async {
        request.response
          ..statusCode = 200
          ..write(manifestJson(
            version: '1.3.0',
            url: 'https://example.test/a.exe',
            sha256: 'b' * 64,
          ));
        await request.response.close();
      });

      final manifest = await serviceFor([
        'http://127.0.0.1:$deadPort/latest.json',
        '${origin(secondary)}/latest.json',
      ]).check();

      expect(manifest?.version, const AppVersion(1, 3, 0));
    });

    test('a 404 on the primary falls through too', () async {
      // A retired pointer that still has a server behind it answers 404, not a
      // refused connection. Both have to fall through.
      final primary = await serve((request) async {
        request.response.statusCode = 404;
        await request.response.close();
      });
      final secondary = await serve((request) async {
        request.response
          ..statusCode = 200
          ..write(manifestJson(
            version: '1.4.0',
            url: 'https://example.test/a.exe',
            sha256: 'b' * 64,
          ));
        await request.response.close();
      });

      final manifest = await serviceFor([
        '${origin(primary)}/latest.json',
        '${origin(secondary)}/latest.json',
      ]).check();

      expect(manifest?.version, const AppVersion(1, 4, 0));
    });

    test('an answering primary is believed, and the secondary is not consulted',
        () async {
      var secondaryHits = 0;
      final primary = await serve((request) async {
        request.response
          ..statusCode = 200
          ..write(manifestJson(
            version: '1.1.0', // same as current: "you are up to date"
            url: 'https://example.test/a.exe',
            sha256: 'b' * 64,
          ));
        await request.response.close();
      });
      final secondary = await serve((request) async {
        secondaryHits++;
        request.response.statusCode = 200;
        await request.response.close();
      });

      expect(
        await serviceFor([
          '${origin(primary)}/latest.json',
          '${origin(secondary)}/latest.json',
        ]).check(),
        isNull,
      );
      expect(secondaryHits, 0);
    });
  });

  group('download()', () {
    final payload = Uint8List.fromList(
      List<int>.generate(64 * 1024, (i) => i % 251),
    );
    final payloadHash = sha256.convert(payload).toString();

    test('a good download is verified and kept', () async {
      final server = await serve((request) async {
        if (request.uri.path == '/latest.json') {
          request.response
            ..statusCode = 200
            ..write(manifestJson(
              version: '1.2.0',
              url: 'https://REPLACED',
              sha256: payloadHash,
              size: payload.length,
            ));
        } else {
          request.response
            ..statusCode = 200
            ..add(payload);
        }
        await request.response.close();
      });

      final service = serviceFor(['${origin(server)}/latest.json']);
      // The manifest requires https, so the download URL is supplied directly here
      // rather than through the parser; TLS enforcement is covered in the manifest
      // tests, and binding a certificate to loopback would test dart:io, not us.
      final manifest = await service.check();
      expect(manifest, isNotNull);

      final result = await service.download(
        _withUrl(manifest!, '${origin(server)}/inventory_pos-1.2.0.exe'),
      );

      expect(result.outcome, DownloadOutcome.ready);
      expect(await result.file!.length(), payload.length);
    });

    test('a file that does not match its hash is discarded, not run', () async {
      final server = await serve((request) async {
        request.response
          ..statusCode = 200
          ..add(Uint8List.fromList([1, 2, 3, 4]));
        await request.response.close();
      });

      final service = serviceFor([]);
      final result = await service.download(
        _manifest(
          version: '1.2.0',
          url: '${origin(server)}/inventory_pos-1.2.0.exe',
          sha256: payloadHash, // deliberately not the hash of what is served
        ),
      );

      expect(result.outcome, DownloadOutcome.corrupt);
      expect(result.file, isNull);
      // Deleted rather than kept: resuming onto a known-bad prefix would fail
      // forever, and the point of failing is to be able to try again.
      expect(
        await File('${downloads.path}/inventory_pos-1.2.0.exe.part').exists(),
        isFalse,
      );
    });

    test('a connection dropped mid-download leaves the till working and resumable',
        () async {
      // Serves half the bytes, then hangs up — a stall on a shop's connection.
      final flaky = await serve((request) async {
        request.response
          ..statusCode = 200
          ..headers.contentLength = payload.length
          ..add(payload.sublist(0, payload.length ~/ 2));
        await request.response.flush();
        await request.response.close();
      });

      final service = serviceFor([]);
      final result = await service.download(
        _manifest(
          version: '1.2.0',
          url: '${origin(flaky)}/inventory_pos-1.2.0.exe',
          sha256: payloadHash,
          size: payload.length,
        ),
      );

      // Not "ready", and above all not a half-written application.
      expect(result.isReady, isFalse);
      expect(result.outcome, DownloadOutcome.interrupted);

      // The part file survives, which is what makes the retry cheap.
      final part = File('${downloads.path}/inventory_pos-1.2.0.exe.part');
      expect(await part.exists(), isTrue);
      expect(await part.length(), lessThan(payload.length));
    });

    test('a retry resumes from the part file instead of starting over', () async {
      final part = File('${downloads.path}/inventory_pos-1.2.0.exe.part');
      final alreadyHave = payload.length ~/ 2;
      await part.writeAsBytes(payload.sublist(0, alreadyHave));

      String? rangeSeen;
      final server = await serve((request) async {
        rangeSeen = request.headers.value(HttpHeaders.rangeHeader);
        final from = int.parse(rangeSeen!.split('=')[1].split('-')[0]);
        request.response
          ..statusCode = 206
          ..headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $from-${payload.length - 1}/${payload.length}',
          )
          ..add(payload.sublist(from));
        await request.response.close();
      });

      final result = await serviceFor([]).download(
        _manifest(
          version: '1.2.0',
          url: '${origin(server)}/inventory_pos-1.2.0.exe',
          sha256: payloadHash,
          size: payload.length,
        ),
      );

      expect(rangeSeen, 'bytes=$alreadyHave-');
      expect(result.outcome, DownloadOutcome.ready);
      expect(await result.file!.length(), payload.length);
    });

    test('a host that ignores Range still produces a correct file', () async {
      // Plenty of servers answer 200 with the whole body regardless. Appending to
      // what we already had would silently build a corrupt installer.
      final part = File('${downloads.path}/inventory_pos-1.2.0.exe.part');
      await part.writeAsBytes(payload.sublist(0, payload.length ~/ 2));

      final server = await serve((request) async {
        request.response
          ..statusCode = 200
          ..add(payload);
        await request.response.close();
      });

      final result = await serviceFor([]).download(
        _manifest(
          version: '1.2.0',
          url: '${origin(server)}/inventory_pos-1.2.0.exe',
          sha256: payloadHash,
          size: payload.length,
        ),
      );

      expect(result.outcome, DownloadOutcome.ready);
      expect(await result.file!.length(), payload.length);
    });

    test('an already-verified file from a previous launch is reused', () async {
      var hits = 0;
      final server = await serve((request) async {
        hits++;
        request.response
          ..statusCode = 200
          ..add(payload);
        await request.response.close();
      });

      final manifest = _manifest(
        version: '1.2.0',
        url: '${origin(server)}/inventory_pos-1.2.0.exe',
        sha256: payloadHash,
        size: payload.length,
      );

      expect((await serviceFor([]).download(manifest)).outcome,
          DownloadOutcome.ready);
      expect((await serviceFor([]).download(manifest)).outcome,
          DownloadOutcome.ready);

      // The second launch does not pay for the download again.
      expect(hits, 1);
    });
  });
}

/// Builds a manifest directly.
///
/// The https requirement lives in [UpdateManifest.tryParse], which is where a
/// manifest off the wire goes; the constructor is unrestricted, so a download can be
/// pointed at a loopback server without standing up a certificate authority to test
/// code that is not ours.
UpdateManifest _manifest({
  required String version,
  required String url,
  required String sha256,
  int? size,
}) =>
    UpdateManifest(
      version: AppVersion.tryParse(version)!,
      url: url,
      sha256: sha256,
      size: size,
    );

UpdateManifest _withUrl(UpdateManifest manifest, String url) => UpdateManifest(
      version: manifest.version,
      url: url,
      sha256: manifest.sha256,
      size: manifest.size,
    );
