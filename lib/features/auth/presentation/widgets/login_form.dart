import 'package:fasaha_utils/utils_export/fasaha_haus_state_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:inventory_app_pos/core/app_constants/inv_app_constants.dart';
import 'package:inventory_app_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:inventory_app_pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:inventory_app_pos/shared/app_buttons/ap_button.dart';
import 'package:inventory_app_pos/shared/input_fileds/ap_username_field.dart';
import 'package:inventory_app_pos/shared/input_fileds/app_password_field.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../bloc/auth_state.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: context.read<AuthBloc>().loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.h,
        children: [
          Text(
            InvAppConstants.kUsername,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          APUsernameField(
            focusNode: context.read<AuthBloc>().usernameFocusNode,
            textInputAction: TextInputAction.next,
            onChanged: (value) =>
                context.read<AuthBloc>().add(UsernameChanged(value)),
            onFieldSubmitted: (_) => context
                .read<AuthBloc>()
                .passwordFocusNode
                .requestFocus(),
          ),
          Gap(10.h),
          Text(
            InvAppConstants.kPassword,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          APPasswordField(
            focusNode: context.read<AuthBloc>().passwordFocusNode,
            textInputAction: TextInputAction.done,
            onChanged: (value) =>
                context.read<AuthBloc>().add(PasswordChanged(value)),
            onFieldSubmitted: (_) {
              final formKey = context.read<AuthBloc>().loginFormKey;
              if (formKey.currentState?.validate() ?? false) {
                context.read<AuthBloc>().add(const LoginFormSubmitted());
              }
            },
          ),
          Gap(20.h),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (oldState, newState) =>
            oldState.stateStatus != newState.stateStatus,
            listener: (context, state) {
              switch (state.stateStatus.runtimeType) {
                case (const (LoggingInUser)):
                  context.loaderOverlay.show();
                  break;
                case (const (ErrorStatus)):
                  context.loaderOverlay.hide();
                  final message = (state.stateStatus as ErrorStatus).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        message,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        top: 20.h,
                        bottom: MediaQuery.of(context).size.height - 100.h,
                        left: 0.55.sw,
                        right: 0.05.sw,
                      ),
                      duration: const Duration(seconds: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                  break;
                default:
                  // Keep loader visible for LoginSuccess and InitStatus —
                  // the loader is hidden after navigation in the BLoC.
                  break;
              }
            },
            child: ApButton(
              btnText: InvAppConstants.kLogin,
              width: 1.sw,
              height: 40,
              fontSize: 10.sp,
              onPressed: () {
                final formKey = context.read<AuthBloc>().loginFormKey;
                if (formKey.currentState?.validate() ?? false) {
                  context.read<AuthBloc>().add(const LoginFormSubmitted());
                }
              },
            ),
          ),

        ],
      ),
    );
  }
}
