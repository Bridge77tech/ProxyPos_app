import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'app_version.dart';
import 'update_endpoints.dart';
import 'update_manifest.dart';

/// Outcome of a download attempt. Only [UpdateDownload.ready] may be executed.
enum DownloadOutcome {
  /// Verified against the manifest hash and safe to run.
  ready,

  /// The connection died, stalled, or the host refused. The part file is kept so
  /// the next attempt resumes rather than starting over.
  interrupted,

  /// What arrived was not what the manifest described. The file is deleted.
  corrupt,

  /// The owner closed the dialog. Not an error.
  cancelled,
}

class UpdateDownload {
  const UpdateDownload(this.outcome, [this.file]);

  final DownloadOutcome outcome;

  /// Only non-null when [outcome] is [DownloadOutcome.ready].
  final File? file;

  bool get isReady => outcome == DownloadOutcome.ready && file != null;
}

/// Finds, fetches and verifies a newer build. Decides nothing about *when*; that is
/// the caller's job, and the caller only ever asks at launch.
///
/// ## The one rule
///
/// Nothing in [check] may ever throw, and nothing in [check] may ever produce
/// something the owner can see. The till is sold into shops with bad connections; a
/// failed update check is the normal case, not the exceptional one. Offline is not an
/// error, it is Tuesday.
///
/// Everything below — the timeouts, the private Dio, each swallowed exception — exists
/// to keep that true. The service is pure Dart with no Flutter dependency so the
/// offline paths can be driven against real sockets in tests rather than mocked.
class UpdateService {
  UpdateService({
    required this.currentVersion,
    Dio? httpClient,
    List<String>? pointerUrls,
    Directory? downloadDirectory,
    Duration? pointerTimeout,
    void Function(String message)? onDiagnostic,
  })  : _pointerUrls = pointerUrls ?? UpdateEndpoints.pointerUrls,
        _downloadDirectory = downloadDirectory,
        _log = onDiagnostic ?? _ignore,
        _dio = httpClient ??
            _bareClient(pointerTimeout ?? UpdateEndpoints.pointerTimeout);

  /// What this build is, read from the executable's version resource at startup.
  final AppVersion currentVersion;

  final List<String> _pointerUrls;
  final Directory? _downloadDirectory;
  final void Function(String) _log;
  final Dio _dio;

  static void _ignore(String _) {}

  /// A Dio of its own, deliberately not the app's.
  ///
  /// Three reasons, each of which has teeth:
  ///
  ///   * The app's client carries an `Authorization` header. This client talks to
  ///     GitHub, not to the ProxyPOS backend. Reusing it would hand a third party the
  ///     shop's session token on every launch.
  ///   * The app's client is wrapped in [ConnectivityInterceptor], which refuses
  ///     requests when the *backend's* health probe fails. A shop whose connection
  ///     reaches GitHub but not the backend would never see an update.
  ///   * The app's client raises errors into the app's error handling. This one must
  ///     raise nothing anywhere.
  static Dio _bareClient(Duration timeout) => Dio(
        BaseOptions(
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          // Status codes are inspected rather than thrown on, so a 404 from a
          // retired pointer falls through to the next one instead of unwinding.
          validateStatus: (_) => true,
          followRedirects: true,
          maxRedirects: 5,
          responseType: ResponseType.plain,
        ),
      );

  /// Asks each pointer in turn whether there is something newer than [currentVersion].
  ///
  /// Returns the manifest when there is, and null in every other case — no update, no
  /// network, no DNS, a hijacked captive-portal response, a truncated file, a 500, a
  /// manifest from a future schema. The caller cannot distinguish "up to date" from
  /// "could not ask", and must not: both mean *carry on and sell things*.
  Future<UpdateManifest?> check() async {
    for (final url in _pointerUrls) {
      final manifest = await _readPointer(url);
      if (manifest == null) continue;

      if (manifest.version.isNewerThan(currentVersion)) {
        _log('update available: $currentVersion -> ${manifest.version}');
        return manifest;
      }

      // A pointer answered and the answer was "you are current". Believe it and stop;
      // asking the fallback would only find the same thing or something staler.
      _log('up to date at $currentVersion (offered ${manifest.version})');
      return null;
    }

    _log('no pointer answered; carrying on offline');
    return null;
  }

  Future<UpdateManifest?> _readPointer(String url) async {
    try {
      final response = await _dio.get<String>(url);

      if (response.statusCode != 200) {
        _log('pointer $url returned ${response.statusCode}');
        return null;
      }

      final body = response.data;
      if (body == null || body.isEmpty) return null;

      // A captive portal answers 200 with a login page. jsonDecode throws on it, and
      // that throw belongs here rather than anywhere further up.
      final manifest = UpdateManifest.tryParse(jsonDecode(body));
      if (manifest == null) _log('pointer $url was not a usable manifest');
      return manifest;
    } catch (error) {
      // Everything: SocketException, DNS failure, TLS failure, timeout, FormatException
      // from a non-JSON body. All of them mean the same thing to the till.
      _log('pointer $url unreachable: $error');
      return null;
    }
  }

  /// Fetches the installer named by [manifest], resuming a previous partial attempt
  /// where the server allows it, and verifies it before letting anyone run it.
  ///
  /// The installed app is never touched. Until [launchInstaller] is called, the worst
  /// a failure here can do is leave a file in the temp directory — the till keeps the
  /// version it has and the owner can try again next launch.
  Future<UpdateDownload> download(
    UpdateManifest manifest, {
    void Function(int received, int? total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final File target;
    final File part;
    try {
      final directory = await _ensureDownloadDirectory();
      // Named for the version so a part file left behind by an abandoned download of
      // 1.2.0 is never mistaken for a partial 1.3.0 and resumed into a hybrid. Any
      // such mix-up would fail the hash below anyway; this stops it happening at all.
      target = File('${directory.path}/inventory_pos-${manifest.version}.exe');
      part = File('${target.path}.part');
    } catch (error) {
      _log('could not prepare a download directory: $error');
      return const UpdateDownload(DownloadOutcome.interrupted);
    }

    try {
      // A completed, verified download from a previous launch that was never run.
      if (await target.exists() && await _matchesHash(target, manifest.sha256)) {
        return UpdateDownload(DownloadOutcome.ready, target);
      }

      final resumeFrom = await part.exists() ? await part.length() : 0;
      final appended = await _fetchInto(
        part,
        manifest,
        resumeFrom: resumeFrom,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
      if (!appended) {
        return UpdateDownload(
          cancelToken?.isCancelled == true
              ? DownloadOutcome.cancelled
              : DownloadOutcome.interrupted,
        );
      }

      // Cheap check before the expensive one: a size mismatch means the transfer
      // ended early, and there is no point hashing tens of megabytes to learn that.
      if (manifest.size != null && await part.length() != manifest.size) {
        _log('short download: ${await part.length()} of ${manifest.size} bytes');
        return const UpdateDownload(DownloadOutcome.interrupted);
      }

      if (!await _matchesHash(part, manifest.sha256)) {
        // Not a transient failure. The bytes are wrong — a bad resume, a corrupted
        // object, or something that is not the installer at all. Keeping the file
        // would mean resuming onto a known-bad prefix forever, so it goes.
        _log('hash mismatch; discarding the download');
        await _deleteQuietly(part);
        return const UpdateDownload(DownloadOutcome.corrupt);
      }

      await _deleteQuietly(target);
      final verified = await part.rename(target.path);
      return UpdateDownload(DownloadOutcome.ready, verified);
    } catch (error) {
      // The part file is left where it is on purpose: it is the resume point.
      _log('download interrupted: $error');
      return UpdateDownload(
        cancelToken?.isCancelled == true
            ? DownloadOutcome.cancelled
            : DownloadOutcome.interrupted,
      );
    }
  }

  /// Returns true when the transfer completed. Appends to [part] rather than
  /// replacing it, so a connection that drops at 80% costs 20% next time instead of
  /// everything — which on the connections this product is built for is the
  /// difference between an update that lands and one that never does.
  Future<bool> _fetchInto(
    File part,
    UpdateManifest manifest, {
    required int resumeFrom,
    void Function(int received, int? total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get<ResponseBody>(
      manifest.url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: UpdateEndpoints.downloadIdleTimeout,
        headers: resumeFrom > 0 ? {'Range': 'bytes=$resumeFrom-'} : null,
      ),
    );

    final status = response.statusCode ?? 0;

    // 206 means the server honoured the range and is sending the remainder.
    // 200 with a range asked for means it ignored it and is sending the whole file,
    // which is correct but requires throwing away what we already had rather than
    // appending to it.
    final resuming = status == 206 && resumeFrom > 0;
    if (status != 200 && status != 206) {
      _log('installer host returned $status');
      return false;
    }
    if (!resuming && resumeFrom > 0) {
      _log('host ignored the resume request; starting over');
      await _deleteQuietly(part);
    }

    final sink = part.openWrite(
      mode: resuming ? FileMode.append : FileMode.writeOnly,
    );
    var received = resuming ? resumeFrom : 0;

    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, manifest.size);
      }
      await sink.flush();
      return true;
    } finally {
      // Closed in a finally so an aborted transfer still leaves a complete,
      // resumable prefix on disk rather than a handle open on a half-written file.
      await sink.close();
    }
  }

  Future<bool> _matchesHash(File file, String expected) async {
    try {
      // Streamed rather than read whole: the installer is tens of megabytes and a
      // till is not a workstation.
      final digest = await sha256.bind(file.openRead()).first;
      return digest.toString() == expected;
    } catch (error) {
      _log('could not hash ${file.path}: $error');
      return false;
    }
  }

  Future<Directory> _ensureDownloadDirectory() async {
    final directory =
        _downloadDirectory ?? Directory('${Directory.systemTemp.path}/proxypos-update');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A temp file we could not remove is not worth failing an update over.
    }
  }

  /// Hands the verified installer to Inno Setup and lets go.
  ///
  /// This is the line where the thin updater stops and a proven one takes over.
  /// Replacing the files of a running Windows application — closing it, swapping
  /// binaries that are memory-mapped, rolling back a half-written install — is the
  /// genuinely dangerous part of self-updating, and none of it is implemented here.
  /// Inno Setup already does it, it already builds this product's installer, and the
  /// fixed AppId in `inventory_pos.iss` is what makes it upgrade in place rather than
  /// install a second copy alongside.
  ///
  /// Flags:
  ///   /SILENT              progress window, no wizard. The owner has already agreed;
  ///                        making them click Next four times on a till is not consent,
  ///                        it is an obstacle. They still see that something is happening.
  ///   /CLOSEAPPLICATIONS   lets Restart Manager close this process if it is still
  ///                        holding files when the copy starts. Belt and braces: we exit
  ///                        immediately, but "immediately" is not a guarantee.
  ///   /RESTARTAPPLICATIONS brings the till back up afterwards.
  ///   /NOCANCEL            there is no safe place to stop once files are being replaced.
  ///
  /// Detached, because this process is about to end and the installer must outlive it.
  Future<bool> launchInstaller(File installer) async {
    try {
      await Process.start(
        installer.path,
        const ['/SILENT', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS', '/NOCANCEL'],
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (error) {
      // Refused by SmartScreen, blocked by an antivirus, or UAC declined. The till is
      // untouched and still running the version it started with.
      _log('installer would not start: $error');
      return false;
    }
  }
}
