import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/app_constants/ap_colors.dart';
import '../../core/utils/utils.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/home/presentation/presentation/dashboard/presentation/bloc/dashboard_state.dart';

/// Renders the dropdown list of product suggestions using DashboardBloc state.
class SearchSuggestionsDropdown extends StatelessWidget {
  const SearchSuggestionsDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // Hide dropdown while a selection modal is being shown
        if ((state.selectedName?.isNotEmpty ?? false)) {
          return const SizedBox.shrink();
        }
        final active = (state.lastQuery?.trim().isNotEmpty ?? false);
        final suggestions = state.searchResults;
        if (!active || suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 365.w, maxHeight: 220.h),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: InvAPColors.kBorderColor.withValues(alpha: 0.5)),
            itemBuilder: (context, index) {
              final p = suggestions[index];
              return ListTile(
                dense: true,
                tileColor: InvAPColors.kWhiteColor,
                title: Text(
                  p.name ?? '-',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: InvAPColors.kBlackColor),
                ),
                subtitle: (p.category != null && p.category!.isNotEmpty)
                    ? Text(
                        p.category!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: InvAPColors.kSecondaryTextColor),
                      )
                    : null,
                onTap: () {
                  final name = p.name ?? '';
                  debugPrint('Selected suggestion: $name');
                  final rootCtx = Navigator.of(context, rootNavigator: true).context;
                  Utils.showOverlayDialog<void>(
                    rootCtx,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Selected: ${state.lastQuery!}'),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
