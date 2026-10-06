import 'package:equatable/equatable.dart';

/// A three-part version, compared the way releases actually order.
///
/// Deliberately tolerant about its input, because the same number arrives from three
/// places that each spell it slightly differently:
///
///   * `pubspec.yaml` writes `1.1.0+1`.
///   * `package_info_plus` on Windows reads the executable's ProductVersion resource
///     and splits it on `+`, handing back `1.1.0` — but that split is its behaviour,
///     not a contract, so this parser does not depend on it having happened.
///   * A hand-edited manifest, sooner or later, will say `v1.2.0`.
///
/// All three mean the same release. Build metadata after `+` is ignored: it is a
/// build counter, not a version, and treating `1.1.0+2` as newer than `1.1.0+1`
/// would prompt tills to "update" to a rebuild of what they already run.
class AppVersion extends Equatable implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  /// Returns null rather than throwing for anything unparseable.
  ///
  /// Null is a real answer here and the call sites depend on it. A manifest that has
  /// been corrupted, truncated by a captive portal, or replaced by an ISP's error
  /// page must result in the till doing nothing at all — not in an exception
  /// surfacing on the launch path.
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;

    var text = raw.trim();
    if (text.isEmpty) return null;

    // `v1.2.0` → `1.2.0`
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }

    // Drop build metadata (`+1`) and any pre-release tag (`-beta.2`). Neither
    // participates in the comparison; see the class comment on why.
    final plus = text.indexOf('+');
    if (plus != -1) text = text.substring(0, plus);
    final dash = text.indexOf('-');
    if (dash != -1) text = text.substring(0, dash);

    final parts = text.split('.');
    if (parts.isEmpty || parts.length > 3) return null;

    // `1.2` is accepted as `1.2.0`; a missing patch is a shorthand, not an error.
    final numbers = <int>[];
    for (final part in parts) {
      if (part.isEmpty) return null;
      final value = int.tryParse(part);
      if (value == null || value < 0) return null;
      numbers.add(value);
    }
    while (numbers.length < 3) {
      numbers.add(0);
    }

    return AppVersion(numbers[0], numbers[1], numbers[2]);
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  List<Object?> get props => [major, minor, patch];

  @override
  String toString() => '$major.$minor.$patch';
}
