import 'package:equatable/equatable.dart';

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

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted();
}
