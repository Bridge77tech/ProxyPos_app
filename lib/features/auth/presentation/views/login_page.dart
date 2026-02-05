import 'dart:async';

import 'package:fasaha_utils/utils_export/fasaha_haus_state_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/core/routing/route_constants.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';
import 'package:inventory_app_pos/shared/input_fileds/ap_username_field.dart';
import 'package:inventory_app_pos/shared/input_fileds/app_password_field.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../../../../core/app_constants/ap_colors.dart';
import '../../../../core/routing/navigation_helper.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../generated/assets.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/auth_event.dart';
import '../../presentation/bloc/auth_state.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';

class APLoginPage extends StatefulWidget {
  const APLoginPage({super.key});

  @override
  State<APLoginPage> createState() => _APLoginPageState();
}

class _APLoginPageState extends State<APLoginPage> {
  StreamSubscription<bool>? _connectivitySub;
  OverlayEntry? _noInternetOverlay;
  Timer? _autoDismissTimer;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  OverlayEntry? _errorOverlay;
  Timer? _errorDismissTimer;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    // Show initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final online = ConnectivityService.instance.isOnline;
      if (!online) _showNoInternetOverlay();
    });

    // Listen for connectivity changes
    _connectivitySub = ConnectivityService.instance.onConnectivityChanged
        .listen((isOnline) {
          if (isOnline) {
            _hideNoInternetOverlay();
          } else {
            _showNoInternetOverlay();
          }
        });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _showNoInternetOverlay() {
    if (_noInternetOverlay != null) return;

    final overlay = Overlay.of(context);

    _noInternetOverlay = OverlayEntry(
      builder: (ctx) {
        final paddingTop = MediaQuery.of(ctx).padding.top;
        return Positioned(
          top: paddingTop + 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.red),
                  const Gap(8),
                  Text(
                    'No internet connection',
                    style:
                        Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_noInternetOverlay!);

    // Auto-dismiss after 10 minutes if still offline
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(
      const Duration(minutes: 10),
      _hideNoInternetOverlay,
    );
  }

  void _hideNoInternetOverlay() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _noInternetOverlay?.remove();
    _noInternetOverlay = null;
  }

  void _showTopRightSnack(String message) {
    _hideTopRightSnack();
    final overlay = Overlay.of(context);
    final paddingTop = MediaQuery.of(context).padding.top;

    _errorOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        top: paddingTop + 12,
        right: 12,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200.w,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style:
                  Theme.of(
                    ctx,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white) ??
                  const TextStyle(color: Colors.white),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );

    overlay.insert(_errorOverlay!);
    _errorDismissTimer?.cancel();
    _errorDismissTimer = Timer(const Duration(seconds: 4), _hideTopRightSnack);
  }

  void _hideTopRightSnack() {
    _errorDismissTimer?.cancel();
    _errorDismissTimer = null;
    _errorOverlay?.remove();
    _errorOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InvAPColors.kAppBackgroundColor,
      body: Row(
        children: [
          Container(
            width: 0.45.sw,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(Assets.imagesLoginLeftImage2),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Gap(100.h),
                Text(
                  InvAppConstants.kOptimizeYourInventory,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontFamily: "Fontspring-DEMO-integralcf",
                    color: const Color(0xFF555654),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10.w,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          InvAppConstants.kLogIntoYourAccount,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          InvAppConstants.kEnterAccountCredentials,
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: InvAPColors.kSecondaryTextColor),
                        ),
                      ],
                    ),
                    Image.asset(Assets.iconsLoginSmallIcon, scale: 4.0),
                  ],
                ),
                Gap(50.h),
                BlocListener<AuthBloc, AuthState>(
                  listenWhen: (prev, curr) =>
                      prev.errorMessage != curr.errorMessage ||
                      prev.stateStatus != curr.stateStatus,
                  listener: (context, state) {
                    // Toggle global loader overlay
                    final isLoading = state.stateStatus is LoggingInUser;
                    if (isLoading) {
                      context.loaderOverlay.show();
                    } else {
                      context.loaderOverlay.hide();
                    }
                    // Show error as SnackBar when state indicates an error
                    // Prefer explicit error message if present; fallback to status message
                    final status = state.stateStatus;
                    final msg = state.errorMessage.isNotEmpty
                        ? state.errorMessage
                        : (status is ErrorStatus ? (status.error) : '');
                    if (msg.isNotEmpty) {
                      _showTopRightSnack(msg);
                    }
                    // Navigate on success
                    if (state.stateStatus is LoginSuccess) {
                      // Clear inputs on success
                      _usernameController.clear();
                      _passwordController.clear();
                      context.read<AuthBloc>().add(const UsernameChanged(''));
                      context.read<AuthBloc>().add(const PasswordChanged(''));

                      NavigationHelper.goNamed(
                        InvRouteConstants.apHomeRoute.routeName,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 100.0),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 5.h,
                          children: [
                            Text(
                              InvAppConstants.kUsername,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            APUsernameField(
                              // No field-level error in AuthState; rely on overall errorMessage
                              errorText: null,
                              onChanged: (v) => context
                                  .read<AuthBloc>()
                                  .add(UsernameChanged(v)),
                              controller: _usernameController,
                            ),
                            Gap(10.h),
                            Text(
                              InvAppConstants.kPassword,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            APPasswordField(
                              errorText: null,
                              onChanged: (v) => context
                                  .read<AuthBloc>()
                                  .add(PasswordChanged(v)),
                              controller: _passwordController,
                            ),
                            Gap(20.h),
                            ApButton(
                              btnText: InvAppConstants.kLogin,
                              width: 1.sw,
                              height: 40,
                              fontSize: 10.sp,
                              onPressed: (state.stateStatus is LoggingInUser)
                                  ? null
                                  : () => context
                                        .read<AuthBloc>()
                                        .add(const LoginFormSubmitted()),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Text(
                    InvAppConstants.kPoweredByFasaha,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
