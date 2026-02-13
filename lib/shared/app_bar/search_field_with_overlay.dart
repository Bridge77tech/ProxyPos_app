// Search field with overlay dropdown for suggestions
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_app_pos/shared/app_bar/search_suggestions_dropdown.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../core/utils/utils.dart'; // used to show modal on selection
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_event.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_state.dart';
import '../../generated/assets.dart';
import 'search_overlay_controller.dart';

class SearchFieldWithOverlay extends StatefulWidget {
  const SearchFieldWithOverlay({super.key});
  @override
  State<SearchFieldWithOverlay> createState() => _SearchFieldWithOverlayState();
}

class _SearchFieldWithOverlayState extends State<SearchFieldWithOverlay> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final SearchOverlayController _overlayController;

  @override
  void initState() {
    super.initState();
    _overlayController = SearchOverlayController(layerLink: _layerLink, verticalOffset: 40);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    final bloc = context.read<DashboardBloc>();
    _overlayController.attachBloc(bloc);
    // Do not show overlay just on focus; we only show during typing when query is non-empty
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) => previous.selectedName != current.selectedName,
      listener: (context, state) {
        // Hide dropdown on explicit selection
        _overlayController.hide();
        // Sync the field text with the selection if not already
        if ((state.selectedName?.isNotEmpty ?? false) && _controller.text != state.selectedName) {
          _controller.text = state.selectedName!;
        }
        // Show dialog modal only for explicit selection
        if ((state.selectedName?.isNotEmpty ?? false)) {
          final rootCtx = Navigator.of(context, rootNavigator: true).context;
          Utils.showOverlayDialog<void>(
            rootCtx,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Selected: ${state.selectedName!}'),
            ),
          );
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;
            return TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              cursorColor: InvAPColors.kBorderColor,
              onFieldSubmitted: (value) {
                final query = value;
                context.read<DashboardBloc>().add(SearchProducts(query));
              },
              onChanged: (value) {
                final query = value.trim();
                context.read<DashboardBloc>().add(SearchProducts(query));
                if (_focusNode.hasFocus && query.isNotEmpty) {
                  if (_overlayController.isShown) {
                    _overlayController.refresh();
                  } else {
                    _overlayController.show(
                      context,
                      width: fieldWidth,
                      child: const SearchSuggestionsDropdown(),
                    );
                  }
                } else {
                  _overlayController.hide();
                }
              },
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: Image.asset(Assets.iconsSearchIcon, scale: 4.5),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: InvAPColors.kBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: InvAPColors.kBorderColor),
                ),
                hintText: 'Search product',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: InvAPColors.kSecondaryTextColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}