import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/local_storage_service_impl.dart';
import '../../data/storage_box.dart';
import 'app_version.dart';
import 'update_log.dart';
import 'update_prompt_dialog.dart';
import 'update_service.dart';

/// Runs the update check once, at launch, and asks before doing anything.
///
/// ## Why this is a launch-only, fire-and-forget call
///
/// A till is a device somebody is standing at with a customer waiting. Two rules
/// follow, and both are enforced here rather than left to good intentions:
///
///   * **It must never interrupt a sale.** [maybePrompt] is called once, from the
///     first frame of the app, and there is no timer, no stream and no retry that
///     could bring the dialog back later. The absence of a scheduler in this file is
///     the feature.
///   * **It must never delay or break startup.** Nothing awaits this. The method
///     catches everything, including its own bugs, because a crash on the launch path
///     of a point-of-sale system is worse than never updating again.
class UpdateCoordinator {
  UpdateCoordinator._();

  /// Key under which a postponed version is remembered.
  static const _dismissedVersionKey = 'dismissed_version';

  /// How often to look for the Navigator.
  static const _navigatorPollInterval = Duration(milliseconds: 200);

  /// How many times, before giving up on this launch — 20 seconds' worth.
  ///
  /// Generous because what is being waited for is the route guard reading a token out
  /// of secure storage, which on a cold till is slow; cheap because each attempt is a
  /// null check on a GlobalKey, not work.
  ///
  /// Counted rather than timed against the clock. A till's clock is not reliable —
  /// these machines sit in shops without NTP and get set by hand — and a deadline
  /// computed from DateTime.now() would be defeated by any adjustment that happened
  /// to land during startup. Counting ticks cannot be.
  static const _navigatorPollLimit = 100;

  /// Starts the one update check this process will ever make.
  ///
  /// ## Why this waits instead of checking once
  ///
  /// This used to be a single post-frame callback that read
  /// `rootNavigatorKey.currentContext` and returned if it was null. It was always
  /// null, so the check never ran — on any till, on any launch, for the entire life
  /// of 1.1.0 and 1.2.0.
  ///
  /// The reason is the route guard. `InvRouters` redirects through
  /// `TokenValidator.hasValidToken()`, which is async, so go_router has no
  /// configuration to build on the first frame and the Navigator does not exist yet.
  /// The callback fired, found nothing, and gave up permanently — silently, because
  /// silence is the correct behaviour for every *other* reason this check can stop.
  /// A verified manifest at a verified URL with a verified hash, and no prompt, and
  /// nothing anywhere saying why.
  ///
  /// So it now waits for the Navigator to appear, up to [_navigatorWait], and gives
  /// up loudly — into [UpdateLog] — rather than quietly.
  ///
  /// ## This is still launch-only
  ///
  /// The timer below exists to find the Navigator, not to re-check for updates. It is
  /// cancelled the moment the check starts and never rearmed, so there is still
  /// exactly one check per process and the prompt still cannot appear in the middle
  /// of a sale. A till that takes 20 seconds to show its login screen gets no update
  /// prompt this launch, which is the right trade: the next launch will.
  static void scheduleAtLaunch(
    GlobalKey<NavigatorState> navigatorKey, {
    UpdateService? service,
  }) {
    UpdateLog.write('launch: waiting for the navigator');
    var attempts = 0;

    Timer.periodic(_navigatorPollInterval, (timer) {
      final context = navigatorKey.currentContext;

      if (context != null && context.mounted) {
        timer.cancel();
        unawaited(maybePrompt(context, service: service));
        return;
      }

      if (++attempts >= _navigatorPollLimit) {
        timer.cancel();
        // Never seen in practice once the guard resolves, so this line in the log
        // means something is wrong with routing rather than with updating.
        UpdateLog.write(
          'no navigator after $attempts attempts; no update check this launch',
        );
      }
    });
  }

  /// The version this build is, or null if it could not be read.
  ///
  /// Comes from the executable's ProductVersion resource via package_info_plus, which
  /// Flutter stamps from `pubspec.yaml` at build time (see `windows/runner/Runner.rc`).
  /// There is deliberately no fallback constant: a hardcoded version that drifts from
  /// the installer's would make a till either re-install what it already has forever,
  /// or never see an update again. Unknown is a safer answer than wrong, and unknown
  /// means "do not check".
  static Future<AppVersion?> currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final parsed = AppVersion.tryParse(info.version);
      if (parsed == null) {
        UpdateLog.write('version resource unreadable as a version: "${info.version}"');
      }
      return parsed;
    } catch (error) {
      UpdateLog.write('package_info_plus failed: $error');
      return null;
    }
  }

  /// Checks for a newer build and, if there is one the owner has not already
  /// refused, asks them about it.
  ///
  /// Never throws. Never shows anything when there is no update or no connection.
  /// Call it and ignore the future.
  static Future<void> maybePrompt(
    BuildContext context, {
    UpdateService? service,
  }) async {
    try {
      final current = service?.currentVersion ?? await currentVersion();
      if (current == null) {
        // Means package_info_plus could not read the executable's version resource.
        // Nothing can be compared, so nothing can be offered.
        UpdateLog.write('could not read this build\'s own version; check abandoned');
        return;
      }

      final updater = service ??
          UpdateService(
            currentVersion: current,
            // The service logs each pointer it tries and why each one failed. Without
            // this it keeps those to itself, which is how a check that never ran at
            // all looked identical to one that found no update.
            onDiagnostic: UpdateLog.write,
          );

      UpdateLog.write('installed version $current');

      final manifest = await updater.check();
      if (manifest == null) {
        // Either up to date or unreachable; the service has already logged which.
        UpdateLog.write('nothing to offer');
        return;
      }

      if (await _wasPostponed(manifest.version)) {
        // Not a fault. Clearing it is: delete the app_update_v1 Hive box, or publish
        // a higher version.
        UpdateLog.write('${manifest.version} available, but already declined');
        return;
      }

      // Awaited work happened above, so the tree may be gone — the owner can close a
      // till between launch and the manifest arriving over a slow connection.
      if (!context.mounted) {
        UpdateLog.write('window closed before ${manifest.version} could be offered');
        return;
      }

      UpdateLog.write('offering ${manifest.version}');

      final decision = await showDialog<UpdateDecision>(
        context: context,
        // The owner answers the question rather than clicking past it. Combined with
        // the PopScope inside the dialog, there is no path that starts a download and
        // then loses the window.
        barrierDismissible: false,
        builder: (_) => UpdatePromptDialog(
          manifest: manifest,
          currentVersion: current,
          service: updater,
        ),
      );

      UpdateLog.write('owner chose: ${decision?.name ?? 'nothing'}');

      if (decision == UpdateDecision.postponed) {
        // Remembered so the same version is not offered at every launch. A *newer*
        // version will still be offered: the comparison below is on equality, not
        // "has been asked before".
        await _postpone(manifest.version);
      }
    } catch (error, stackTrace) {
      // Includes anything thrown by the storage calls or by showDialog itself. The
      // till carries on; an update that cannot be offered is not an incident — but it
      // is written down, because the alternative is what this file's history already
      // demonstrates.
      UpdateLog.write('check threw: $error');
      UpdateLog.write('$stackTrace');
      debugPrint('Update check skipped: $error');
    }
  }

  static Future<Box?> _box() async {
    try {
      return await LocalStorageServiceImpl.instance.openBox(StorageBox.appUpdate);
    } catch (_) {
      // A box that will not open costs the owner a repeated prompt, nothing more.
      return null;
    }
  }

  static Future<bool> _wasPostponed(AppVersion version) async {
    final box = await _box();
    final stored = AppVersion.tryParse(box?.get(_dismissedVersionKey)?.toString());
    return stored == version;
  }

  static Future<void> _postpone(AppVersion version) async {
    final box = await _box();
    await box?.put(_dismissedVersionKey, version.toString());
  }
}
