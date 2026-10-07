import 'dart:io';

/// A file the update check writes to, because on Windows nothing else is visible.
///
/// A released Flutter Windows app is a GUI process with no console attached, so
/// `debugPrint` and every logger that writes to stdout go nowhere at all. The updater
/// is also written to fail silently on purpose — an unreachable host must never become
/// something a shopkeeper sees — and the two together meant a check could decline to
/// run on every launch, for weeks, leaving no trace anywhere.
///
/// That is exactly what happened: the prompt never appeared on a till whose manifest,
/// URL and hash were all verified correct, and there was no way to tell from the
/// outside whether the check had failed, decided there was nothing to do, or never run.
///
/// So: one short file, appended to on every launch, which answers "what did the check
/// actually do?" without changing anything the owner sees.
///
///     %LOCALAPPDATA%\ProxyPOS\update.log
///
/// Nothing here may throw. A logger that can break the launch path is worse than no
/// logger, and this one exists only to explain a silence.
class UpdateLog {
  UpdateLog._();

  /// Kept small deliberately. It is a diagnostic, not an audit trail, and a till runs
  /// for years — an uncapped log on a shop machine nobody administers is a slow leak.
  static const int _maxBytes = 64 * 1024;

  static File? _resolve() {
    try {
      // LOCALAPPDATA is where a Windows app's own data belongs, and it is somewhere a
      // shopkeeper can be talked to over the phone. Elsewhere (tests, a developer's
      // Mac) the temp directory is fine; nobody is reading it there.
      final base = Platform.environment['LOCALAPPDATA'];
      final directory = Directory(
        base != null && base.isNotEmpty
            ? '$base${Platform.pathSeparator}ProxyPOS'
            : '${Directory.systemTemp.path}${Platform.pathSeparator}ProxyPOS',
      );
      if (!directory.existsSync()) directory.createSync(recursive: true);
      return File('${directory.path}${Platform.pathSeparator}update.log');
    } catch (_) {
      return null;
    }
  }

  /// Appends one timestamped line. Silent on every failure, including its own.
  static void write(String message) {
    try {
      final file = _resolve();
      if (file == null) return;

      // Truncate rather than rotate: a second file is a second thing to explain over
      // the phone, and nothing older than the last few launches is worth keeping.
      if (file.existsSync() && file.lengthSync() > _maxBytes) {
        file.writeAsStringSync('');
      }

      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()}  $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // A diagnostic that throws on a till is a bug with a worse blast radius than the
      // one it was added to find.
    }
  }

  /// Where the file is, for telling somebody over the phone. Null if it cannot be
  /// worked out.
  static String? get path => _resolve()?.path;
}
