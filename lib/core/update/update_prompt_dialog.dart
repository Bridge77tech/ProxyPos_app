import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../app_constants/ap_colors.dart';
import '../../shared/app_buttons/ap_button.dart';
import 'app_version.dart';
import 'update_manifest.dart';
import 'update_service.dart';

/// What the owner decided, reported back so the caller can remember a refusal.
enum UpdateDecision { installed, postponed }

/// "Update available — install now?", and everything that follows if they say yes.
///
/// The dialog owns the whole interaction rather than handing control back between
/// steps, because the steps are not independent: the owner must be able to see a
/// download failing and retry it without being asked from the beginning, and the
/// window must stop being dismissible the moment bytes start landing on disk.
///
/// Shown only at launch, never during a session. Nothing here can be reached from a
/// timer. That is enforced by the only call site — see [UpdateCoordinator].
class UpdatePromptDialog extends StatefulWidget {
  const UpdatePromptDialog({
    required this.manifest,
    required this.currentVersion,
    required this.service,
    super.key,
  });

  final UpdateManifest manifest;
  final AppVersion currentVersion;
  final UpdateService service;

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

enum _Stage { asking, downloading, failed, starting }

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  _Stage _stage = _Stage.asking;
  CancelToken? _cancelToken;
  int _received = 0;
  int? _total;
  String? _failureMessage;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _install() async {
    final cancelToken = CancelToken();
    setState(() {
      _stage = _Stage.downloading;
      _cancelToken = cancelToken;
      _received = 0;
      _total = widget.manifest.size;
      _failureMessage = null;
    });

    final result = await widget.service.download(
      widget.manifest,
      cancelToken: cancelToken,
      onProgress: (received, total) {
        if (!mounted) return;
        setState(() {
          _received = received;
          _total = total ?? _total;
        });
      },
    );

    if (!mounted) return;

    if (!result.isReady) {
      setState(() {
        _stage = _Stage.failed;
        _failureMessage = switch (result.outcome) {
          // Deliberately not "an error occurred". The owner's next action differs in
          // each case, and the till is still working in all of them.
          DownloadOutcome.interrupted =>
            'The download stopped before it finished. Your current version is '
                'untouched — try again when the connection is steadier.',
          DownloadOutcome.corrupt =>
            'The download did not arrive intact and was discarded. Your current '
                'version is untouched. Please try again.',
          DownloadOutcome.cancelled => 'Update cancelled.',
          DownloadOutcome.ready => '',
        };
      });
      return;
    }

    setState(() => _stage = _Stage.starting);

    final started = await widget.service.launchInstaller(result.file!);
    if (!mounted) return;

    if (!started) {
      setState(() {
        _stage = _Stage.failed;
        _failureMessage =
            'Windows would not start the installer. Your current version is '
            'untouched. Try again, or install it by hand.';
      });
      return;
    }

    // The installer is running and will close this app itself. Hand the decision
    // back so the caller can shut down cleanly rather than being killed mid-write.
    Navigator.of(context).pop(UpdateDecision.installed);
  }

  @override
  Widget build(BuildContext context) {
    // Nothing is dismissible once a download has begun, and the Escape key and the
    // Windows back gesture are part of "dismissible".
    return PopScope(
      canPop: _stage == _Stage.asking || _stage == _Stage.failed,
      child: AlertDialog(
        backgroundColor: InvAPColors.kAppBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: InvAPColors.kBlackColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.r),
              topRight: Radius.circular(8.r),
            ),
          ),
          child: Text(
            'Update available',
            key: const Key('update-dialog-title'),
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: InvAPColors.kWhiteColor),
          ),
        ),
        contentPadding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
        content: SizedBox(width: 380.w, child: _content(context)),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        actions: _actions(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final body = Theme.of(context)
        .textTheme
        .bodySmall!
        .copyWith(color: InvAPColors.kPrimaryTextColor);
    final muted = body.copyWith(color: InvAPColors.kSecondaryTextColor);

    switch (_stage) {
      case _Stage.asking:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version ${widget.manifest.version} is ready to install. '
              'This till is on ${widget.currentVersion}.',
              style: body,
            ),
            if (widget.manifest.notes != null) ...[
              Gap(12.h),
              Text(widget.manifest.notes!, style: muted),
            ],
            Gap(12.h),
            Text(
              'The till will close while it installs, then reopen. '
              'Finish any sale in progress first.',
              key: const Key('update-dialog-warning'),
              style: muted,
            ),
          ],
        );

      case _Stage.downloading:
        // Indeterminate when the publisher did not record a size, rather than a bar
        // that invents a position.
        final fraction = (_total != null && _total! > 0)
            ? (_received / _total!).clamp(0.0, 1.0)
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Downloading version ${widget.manifest.version}…', style: body),
            Gap(12.h),
            LinearProgressIndicator(
              key: const Key('update-download-progress'),
              value: fraction,
              color: InvAPColors.kPrimaryColor,
              backgroundColor: InvAPColors.kBorderColor,
            ),
            Gap(8.h),
            Text(_progressLabel(), style: muted),
          ],
        );

      case _Stage.failed:
        return Text(
          _failureMessage ?? 'The update could not be installed.',
          key: const Key('update-dialog-failure'),
          style: body,
        );

      case _Stage.starting:
        return Text('Starting the installer…', style: body);
    }
  }

  String _progressLabel() {
    const mb = 1024 * 1024;
    final done = (_received / mb).toStringAsFixed(1);
    if (_total == null || _total! <= 0) return '$done MB so far';
    return '$done of ${(_total! / mb).toStringAsFixed(1)} MB';
  }

  List<Widget> _actions(BuildContext context) {
    switch (_stage) {
      case _Stage.asking:
        return [
          TextButton(
            key: const Key('update-later'),
            onPressed: () =>
                Navigator.of(context).pop(UpdateDecision.postponed),
            child: Text(
              'Later',
              style: TextStyle(color: InvAPColors.kSecondaryTextColor),
            ),
          ),
          ApButton(
            key: const Key('update-install-now'),
            btnText: 'Install now',
            height: 40.h,
            fontSize: 15,
            onPressed: _install,
          ),
        ];

      case _Stage.downloading:
        return [
          TextButton(
            key: const Key('update-cancel-download'),
            onPressed: () {
              _cancelToken?.cancel();
              Navigator.of(context).pop(UpdateDecision.postponed);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: InvAPColors.kSecondaryTextColor),
            ),
          ),
        ];

      case _Stage.failed:
        return [
          TextButton(
            key: const Key('update-failed-dismiss'),
            onPressed: () =>
                Navigator.of(context).pop(UpdateDecision.postponed),
            child: Text(
              'Not now',
              style: TextStyle(color: InvAPColors.kSecondaryTextColor),
            ),
          ),
          ApButton(
            key: const Key('update-retry'),
            btnText: 'Try again',
            height: 40.h,
            fontSize: 15,
            // Resumes from whatever survived on disk rather than starting over.
            onPressed: _install,
          ),
        ];

      case _Stage.starting:
        return const [];
    }
  }
}
