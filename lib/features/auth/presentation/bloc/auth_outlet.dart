import 'package:flutter_bloc/flutter_bloc.dart';

import '../views/login_page.dart';
import 'auth_bloc.dart';

BlocProvider get authOutlet {
  return BlocProvider<AuthBloc>(
    create: (context) => AuthBloc(),
    child: const APLoginPage(),
  );
}
