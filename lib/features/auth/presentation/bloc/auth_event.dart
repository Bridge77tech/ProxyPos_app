import 'package:equatable/equatable.dart';
import 'package:fasaha_utils/utils_export/fasaha_haus_state_status.dart';
import 'package:inventory_app_pos/features/auth/data/model/ap_user_model.dart';
import 'package:inventory_app_pos/features/auth/data/model/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class UsernameChanged extends AuthEvent {
  const UsernameChanged(this.username);
  final String username;

  @override
  List<Object?> get props => [username];
}

class PasswordChanged extends AuthEvent {
  const PasswordChanged(this.password);
  final String password;

  @override
  List<Object?> get props => [password];
}

class LoginFormSubmitted extends AuthEvent {
  const LoginFormSubmitted();

  @override
  List<Object?> get props => [];
}

class SaveUserInfo extends AuthEvent {
  final UserModel userInfo;

  const SaveUserInfo(this.userInfo);

  @override
  List<Object?> get props => [userInfo];
}

class LoggingInUser extends StateStatus {
  const LoggingInUser();
}

class LoginSuccess extends StateStatus {}
