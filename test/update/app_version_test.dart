import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/core/update/app_version.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('reads a plain version', () {
      expect(AppVersion.tryParse('1.2.3'), const AppVersion(1, 2, 3));
    });

    test('ignores the build counter pubspec appends', () {
      // package_info_plus splits on '+' before we see it, but that is its behaviour
      // rather than a contract, so the parser does not rely on it having happened.
      expect(AppVersion.tryParse('1.1.0+1'), const AppVersion(1, 1, 0));
    });

    test('tolerates a leading v, which a hand-edited manifest will eventually have',
        () {
      expect(AppVersion.tryParse('v2.0.1'), const AppVersion(2, 0, 1));
    });

    test('treats a missing patch as zero', () {
      expect(AppVersion.tryParse('1.4'), const AppVersion(1, 4, 0));
    });

    test('drops a pre-release tag', () {
      expect(AppVersion.tryParse('1.5.0-beta.2'), const AppVersion(1, 5, 0));
    });

    test('returns null rather than throwing on rubbish', () {
      // Each of these is something a captive portal, a proxy error page or a
      // half-written manifest can realistically produce.
      for (final input in [
        null, '', '   ', 'latest', '1.2.3.4', '1..3', 'a.b.c', '-1.0.0', '<html>',
      ]) {
        expect(AppVersion.tryParse(input), isNull, reason: 'input: $input');
      }
    });
  });

  group('ordering', () {
    test('compares major, then minor, then patch', () {
      expect(const AppVersion(2, 0, 0).isNewerThan(const AppVersion(1, 9, 9)), isTrue);
      expect(const AppVersion(1, 10, 0).isNewerThan(const AppVersion(1, 9, 0)), isTrue);
      expect(const AppVersion(1, 2, 3).isNewerThan(const AppVersion(1, 2, 2)), isTrue);
    });

    test('an equal version is not newer', () {
      expect(const AppVersion(1, 1, 0).isNewerThan(const AppVersion(1, 1, 0)), isFalse);
    });

    test('an older version is not newer', () {
      expect(const AppVersion(1, 0, 0).isNewerThan(const AppVersion(1, 1, 0)), isFalse);
    });

    test('10 sorts above 9, which string comparison would get wrong', () {
      // The bug this guards against ships silently: every till stops updating at
      // 1.9.0 and nobody notices until someone asks why 1.10.0 never arrived.
      expect(const AppVersion(1, 10, 0).isNewerThan(const AppVersion(1, 9, 0)), isTrue);
      expect('1.10.0'.compareTo('1.9.0') > 0, isFalse); // why we do not do that
    });
  });
}
