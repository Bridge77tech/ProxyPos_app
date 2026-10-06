import 'package:equatable/equatable.dart';

import 'app_version.dart';

/// The pointer document: what the newest build is, and where it lives.
///
/// Written by `installers/build_installer.ps1` from the installer it has just
/// produced, so the hash and size describe the artefact that actually exists rather
/// than one somebody meant to upload. Published to the location named in
/// [UpdateEndpoints.pointerUrls].
///
///     {
///       "schema": 1,
///       "version": "1.2.0",
///       "url": "https://github.com/.../inventory_pos-1.2.0.exe",
///       "sha256": "9f2c...",
///       "size": 24117248,
///       "notes": "Expiry warnings on the till."
///     }
///
/// There is no "mandatory" or "silent" field, and that is a decision rather than an
/// omission. A till must never update itself while a sale is open, so there is no
/// mechanism here for a future manifest to force one. Adding such a field later
/// would be adding a way to break the one rule the product cannot break.
class UpdateManifest extends Equatable {
  const UpdateManifest({
    required this.version,
    required this.url,
    required this.sha256,
    this.size,
    this.notes,
  });

  /// The version offered. Already parsed — a manifest whose version cannot be read
  /// is not a manifest, so [tryParse] rejects it rather than carrying a null around.
  final AppVersion version;

  /// Where the installer is. The whole reason the build host can move without a
  /// release: this is data the server controls, not a constant in the app.
  final String url;

  /// Lower-case hex SHA-256 of the installer.
  ///
  /// Checked after the download completes and before anything is executed. This is
  /// what makes a resumed or truncated download safe: a file assembled from two
  /// partial attempts, or one that is actually a proxy's error page wearing an .exe
  /// name, fails here and is deleted instead of run.
  final String sha256;

  /// Bytes, when the publisher recorded it. Used to spot a download that finished
  /// early before spending time hashing it, and to show honest progress.
  final int? size;

  /// Shown to the owner in the prompt. Optional; the prompt reads fine without it.
  final String? notes;

  /// The only schema this build understands.
  ///
  /// A manifest declaring a higher schema is ignored rather than guessed at. That
  /// keeps a future format change from making old tills behave unpredictably: they
  /// simply stop seeing updates, which is visible in their reported version, instead
  /// of acting on fields they have misread.
  static const int supportedSchema = 1;

  /// Returns null for anything that is not a manifest this build can act on.
  ///
  /// Every rejection path here is a silent no-op upstream. The parser is given the
  /// decoded JSON rather than a string so that malformed JSON fails in one place
  /// (the caller) and malformed *content* fails here.
  static UpdateManifest? tryParse(Object? decoded) {
    if (decoded is! Map) return null;

    // Absent is treated as 1 so the very first manifest need not carry the field;
    // present but wrong is refused.
    final schema = decoded['schema'];
    if (schema != null && schema != supportedSchema) return null;

    final version = AppVersion.tryParse(decoded['version']?.toString());
    if (version == null) return null;

    final url = decoded['url']?.toString().trim();
    if (url == null || url.isEmpty) return null;

    // Plain http would let anyone on a shop's network hand the till an executable.
    // The hash check below is the real defence, but the hash arrives over the same
    // connection, so an attacker who can rewrite one can rewrite both. Requiring
    // TLS is what makes the hash mean anything.
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.scheme != 'https' || parsed.host.isEmpty) {
      return null;
    }

    final sha256 = decoded['sha256']?.toString().trim().toLowerCase();
    if (sha256 == null || !_isSha256Hex(sha256)) return null;

    final rawSize = decoded['size'];
    final size = rawSize is int
        ? rawSize
        : (rawSize is num ? rawSize.toInt() : int.tryParse('$rawSize'));

    final notes = decoded['notes']?.toString().trim();

    return UpdateManifest(
      version: version,
      url: url,
      sha256: sha256,
      size: size != null && size > 0 ? size : null,
      notes: notes == null || notes.isEmpty ? null : notes,
    );
  }

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');

  static bool _isSha256Hex(String value) => _hex64.hasMatch(value);

  @override
  List<Object?> get props => [version, url, sha256, size, notes];
}
