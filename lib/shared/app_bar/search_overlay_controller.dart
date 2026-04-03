import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_bloc.dart';

/// Controller that manages showing/hiding the search suggestions overlay.
class SearchOverlayController {
  SearchOverlayController({required this.layerLink, this.verticalOffset = 40});

  final LayerLink layerLink;
  final double verticalOffset;

  OverlayEntry? _entry;
  DashboardBloc? _bloc;

  void attachBloc(DashboardBloc bloc) {
    _bloc = bloc;
  }

  bool get isShown => _entry != null;

  void show(BuildContext context, {required Widget child, double? width}) {
    if (_entry != null) return;
    final bloc = _bloc;
    if (bloc == null) return;

    _entry = OverlayEntry(builder: (ctx) {
      final dropdownChild = width != null ? SizedBox(width: width, child: child) : child;
      return Positioned.fill(
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, verticalOffset),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8.r),
                color: InvAPColors.kWhiteColor,
                child: BlocProvider.value(
                  value: bloc,
                  child: dropdownChild,
                ),
              ),
            ),
          ],
        ),
      );
    });

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void refresh() {
    _entry?.markNeedsBuild();
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }

  void dispose() {
    hide();
  }
}