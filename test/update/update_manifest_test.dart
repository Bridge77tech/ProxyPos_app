import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/update/app_version.dart';
import 'package:inventory_app_pos/core/update/update_manifest.dart';

final _hash = 'a' * 64;

Object decode(String json) => jsonDecode(json) as Object;

void main() {
  group('UpdateManifest.tryParse', () {
    test('reads a complete manifest', () {
      final manifest = UpdateManifest.tryParse(decode('''
        {
          "schema": 1,
          "version": "1.2.0",
          "url": "https://example.test/inventory_pos-1.2.0.exe",
          "sha256": "$_hash",
          "size": 1024,
          "notes": "Expiry warnings on the till."
        }
      '''));

      expect(manifest, isNotNull);
      expect(manifest!.version, const AppVersion(1, 2, 0));
      expect(manifest.url, 'https://example.test/inventory_pos-1.2.0.exe');
      expect(manifest.sha256, _hash);
      expect(manifest.size, 1024);
      expect(manifest.notes, 'Expiry warnings on the till.');
    });

    test('accepts a manifest with no schema field', () {
      // The first manifest ever published should not need to know about versioning.
      final manifest = UpdateManifest.tryParse(decode(
        '{"version":"1.2.0","url":"https://e.test/a.exe","sha256":"$_hash"}',
      ));
      expect(manifest, isNotNull);
    });

    test('refuses a schema this build does not understand', () {
      // Old tills stop seeing updates — visible in their reported version — rather
      // than acting on fields they have misread.
      final manifest = UpdateManifest.tryParse(decode(
        '{"schema":2,"version":"9.0.0","url":"https://e.test/a.exe","sha256":"$_hash"}',
      ));
      expect(manifest, isNull);
    });

    test('refuses plain http', () {
      // The hash arrives over the same connection as the file, so anyone who can
      // rewrite one can rewrite both. TLS is what makes the hash mean anything.
      final manifest = UpdateManifest.tryParse(decode(
        '{"version":"1.2.0","url":"http://e.test/a.exe","sha256":"$_hash"}',
      ));
      expect(manifest, isNull);
    });

    test('refuses a manifest with no usable hash', () {
      for (final sha in ['', 'notahash', 'ABC123', 'a' * 63, 'a' * 65]) {
        final manifest = UpdateManifest.tryParse(decode(
          '{"version":"1.2.0","url":"https://e.test/a.exe","sha256":"$sha"}',
        ));
        expect(manifest, isNull, reason: 'sha256: $sha');
      }
    });

    test('normalises an upper-case hash rather than refusing it', () {
      final manifest = UpdateManifest.tryParse(decode(
        '{"version":"1.2.0","url":"https://e.test/a.exe","sha256":"${'A' * 64}"}',
      ));
      expect(manifest?.sha256, 'a' * 64);
    });

    test('refuses anything that is not a manifest at all', () {
      // What a captive portal, a proxy error page and a truncated file actually
      // decode to.
      for (final value in <Object?>[null, 'login required', 42, <Object>[], <String, Object>{}]) {
        expect(UpdateManifest.tryParse(value), isNull, reason: 'value: $value');
      }
    });

    test('drops a size of zero rather than trusting it', () {
      final manifest = UpdateManifest.tryParse(decode(
        '{"version":"1.2.0","url":"https://e.test/a.exe","sha256":"$_hash","size":0}',
      ));
      expect(manifest?.size, isNull);
    });
  });
}
