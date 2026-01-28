import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/bloc/main_layout_bloc.dart';

/// A reusable provider widget for MainLayoutBloc.
///
/// Usage:
/// - Wrap a subtree: `MainLayoutProvider(child: APMainLayoutPage())`
/// - Or pass an existing bloc instance: `MainLayoutProvider(bloc: myBloc, child: child)`
class MainLayoutProvider extends StatelessWidget {
  const MainLayoutProvider({
    super.key,
    this.bloc,
    required this.child,
  });

  /// If provided, the existing bloc will be used via `BlocProvider.value`.
  /// Otherwise a new [MainLayoutBloc] will be created and provided.
  final MainLayoutBloc? bloc;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider.value(
        value: bloc!,
        child: child,
      );
    }

    return BlocProvider<MainLayoutBloc>(
      create: (_) => MainLayoutBloc(),
      child: child,
    );
  }
}
