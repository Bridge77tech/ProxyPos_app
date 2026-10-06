@Timeout(Duration(seconds: 120))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/update/app_version.dart';
import 'package:inventory_app_pos/core/update/update_endpoints.dart';
import 'package:inventory_app_pos/core/update/update_manifest.dart';
import 'package:inventory_app_pos/core/update/update_service.dart';

/// Against the real internet. Skipped unless you ask for it:
///
///     PROXYPOS_LIVE_TESTS=1 flutter test test/update/update_live_network_test.dart
///
/// Opt-in by environment variable rather than by tag, because a tag excluded in
/// dart_test.yaml cannot then be re-included from the command line — `--tags live`
/// and `exclude_tags: live` simply cancel out and nothing runs, silently. A test that
/// quietly never runs is worse than no test.
///
/// The loopback tests prove the logic. These prove the parts a loopback socket cannot
/// reach and that an updater is most likely to be quietly wrong about: that the URL
/// compiled into every shipped build is the URL that actually exists, that GitHub's
/// cross-host redirect to its asset store is followed, and that a resumed download
/// over that redirect comes back byte-identical.
///
/// An updater that passes its unit tests and fails against a real release is the exact
/// failure this product cannot carry, because by the time it shows up it is already
/// installed on a till in another town.
void main() {
  // Null when they should run; a reason when they should not. Passed to each group so
  // a skipped run says why rather than just reporting zero tests.
  final skip = Platform.environment['PROXYPOS_LIVE_TESTS'] == '1'
      ? null
      : 'needs the internet; run with PROXYPOS_LIVE_TESTS=1';

  late Directory downloads;

  setUp(() async {
    downloads = await Directory.systemTemp.createTemp('proxypos-live');
  });

  tearDown(() async {
    if (await downloads.exists()) await downloads.delete(recursive: true);
  });

  group('the address compiled into every build', skip: skip, () {
    test('is the one that is configured, spelled exactly', () {
      // If this ever has to change, read update_endpoints.dart first. The entry below
      // is not a detail — it is the thing a shipped update cannot fix.
      expect(UpdateEndpoints.pointerUrls, [
        'https://raw.githubusercontent.com/Bridge77tech/POS-Release/main/v1/pos/windows/latest.json',
      ]);
    });

    test('resolves over real DNS and TLS, and a missing manifest is a no-op',
        () async {
      // Run before any release has been published, this exercises the live 404 path
      // at the real address: the till finds nothing and carries on. Run after one has
      // been published, it parses the real manifest instead. Both are passes, and the
      // assertion is written to mean the same thing either way — the till is never
      // harmed by what it finds here.
      final service = UpdateService(
        currentVersion: const AppVersion(1, 1, 0),
        downloadDirectory: downloads,
      );

      // The claim is that it returns rather than throwing, whatever is at the far end.
      Object? thrown;
      UpdateManifest? manifest;
      try {
        manifest = await service.check();
      } catch (error) {
        thrown = error;
      }

      expect(thrown, isNull, reason: 'the live check must never throw');
      // Before the first release: null, from a real 404. After one: a parsed manifest.
      if (manifest != null) {
        expect(manifest.sha256, hasLength(64));
        expect(Uri.parse(manifest.url).scheme, 'https');
      }
    });

    test('the host serves anonymously, with no credential', () async {
      // The repository behind this address is public for exactly this reason. If it
      // were private, every till would need a token, and the day that token expired
      // every till would stop updating at once.
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(
        'https://raw.githubusercontent.com/Bridge77tech/POS-Release/main/README.md',
      ));
      final response = await request.close();
      await response.drain<void>();
      client.close();

      expect(response.statusCode, 200);
    });
  });

  group('the published test manifest', skip: skip, () {
    test('parses, and names an asset that is really there', () async {
      // End to end over the published fixture: raw.githubusercontent serves the
      // pointer, the parser accepts it, and the file it names downloads and hashes to
      // what the pointer promised. Everything the production path does except that the
      // payload is a text file rather than an installer.
      final service = UpdateService(
        currentVersion: const AppVersion(1, 1, 0),
        pointerUrls: const [
          'https://raw.githubusercontent.com/Bridge77tech/POS-Release/main/v1/pos/windows/test/latest.json',
        ],
        downloadDirectory: downloads,
      );

      final manifest = await service.check();
      expect(manifest, isNotNull, reason: 'the published test manifest should parse');
      expect(manifest!.version, const AppVersion(99, 0, 0));

      final result = await service.download(manifest);
      expect(result.outcome, DownloadOutcome.ready);
      expect(await result.file!.length(), manifest.size);
    });
  });

  group('a real published release asset', skip: skip, () {
    // ProxyPOS's own release asset, in ProxyPOS's own repository — published to
    // POS-Release as `test-fixture-v0`. Not an installer: this machine is a Mac and
    // cannot produce one. But it is fetched exactly as an installer will be, from the
    // same host, through the same cross-host redirect to GitHub's asset store, with no
    // credential — which is the part that has to be true for a till in a shop.
    const url =
        'https://github.com/Bridge77tech/POS-Release/releases/download/test-fixture-v0/proxypos-updater-test-fixture.txt';
    const sha = 'e34e96a1a1e9ba91f313d697257a74ba1fb36070eff681394873b14b36126ca8';
    const size = 84;

    UpdateManifest manifestFor(String hash) => UpdateManifest(
          version: const AppVersion(9, 9, 9),
          url: url,
          sha256: hash,
          size: size,
        );

    test('downloads through the redirect and verifies', () async {
      final service = UpdateService(
        currentVersion: const AppVersion(1, 1, 0),
        downloadDirectory: downloads,
      );

      final result = await service.download(manifestFor(sha));

      expect(result.outcome, DownloadOutcome.ready);
      expect(await result.file!.length(), size);
    });

    test('resumes a partial download across the redirect', () async {
      // GitHub's asset store answers 206 to a Range request after the redirect —
      // checked live. This is what makes a dropped connection on a shop's line cost
      // the remainder rather than the whole installer.
      final part = File('${downloads.path}/inventory_pos-9.9.9.exe.part');
      final whole = await File('${downloads.path}/seed').writeAsBytes(const []);
      await whole.delete();

      // Seed a genuine prefix by fetching the file once and truncating it.
      final seeded = UpdateService(
        currentVersion: const AppVersion(1, 1, 0),
        downloadDirectory: downloads,
      );
      final first = await seeded.download(manifestFor(sha));
      expect(first.outcome, DownloadOutcome.ready);
      final bytes = await first.file!.readAsBytes();
      await first.file!.delete();
      await part.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));

      final result = await UpdateService(
        currentVersion: const AppVersion(1, 1, 0),
        downloadDirectory: downloads,
      ).download(manifestFor(sha));

      expect(result.outcome, DownloadOutcome.ready);
      expect(await result.file!.length(), size);
      // Byte-identical to the unresumed fetch, which is the only claim that matters:
      // a resume that silently produces a different file would be caught here and
      // nowhere else.
      expect(await result.file!.readAsBytes(), bytes);
    });

    test('a wrong hash is refused against a real download, not just a fake one',
        () async {
      final result = await UpdateService(
        currentVersion: const AppVersion(1, 1, 0),
        downloadDirectory: downloads,
      ).download(manifestFor('f' * 64));

      expect(result.outcome, DownloadOutcome.corrupt);
      expect(result.file, isNull);
    });
  });
}
