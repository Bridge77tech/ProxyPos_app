import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/local_storage_service_impl.dart';
import '../../data/storage_box.dart';
import 'app_version.dart';
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
      return AppVersion.tryParse(info.version);
    } catch (_) {
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
      if (current == null) return;

      final updater = service ?? UpdateService(currentVersion: current);

      final manifest = await updater.check();
      if (manifest == null) return;

      if (await _wasPostponed(manifest.version)) return;

      // Awaited work happened above, so the tree may be gone — the owner can close a
      // till between launch and the manifest arriving over a slow connection.
      if (!context.mounted) return;

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

      if (decision == UpdateDecision.postponed) {
        // Remembered so the same version is not offered at every launch. A *newer*
        // version will still be offered: the comparison below is on equality, not
        // "has been asked before".
        await _postpone(manifest.version);
      }
    } catch (error) {
      // Includes anything thrown by the storage calls or by showDialog itself. The
      // till carries on; an update that cannot be offered is not an incident.
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
