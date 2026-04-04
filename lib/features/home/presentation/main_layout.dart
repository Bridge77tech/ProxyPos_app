import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/presentation/bloc/dashboard/dashboard_outlet.dart';
import 'package:inventory_app_pos/shared/app_bar/inv_app_bar.dart';

import '../../../core/app_constants/ap_colors.dart';
import 'bloc/main_layout_bloc.dart';
import 'bloc/main_layout_state.dart';

class APMainLayoutPage extends StatelessWidget {
  const APMainLayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvAPColors.kAppBackgroundColor,
      appBar: const InvAppBar(),
      body: BlocBuilder<MainLayoutBloc, MainLayoutState>(
        builder: (context, state) {
          switch (state.selectedTab) {
            case MainLayoutTab.dashboard:
              return dashboardOutlet;
            case MainLayoutTab.history:
              return const Center(child: Text('History'));
            case MainLayoutTab.myAccount:
              return const Center(child: Text('My Account'));
          }
        },
      ),
    );
  }
}
