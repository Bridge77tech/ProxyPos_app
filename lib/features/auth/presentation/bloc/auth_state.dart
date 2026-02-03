import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  const AuthState({
    this.username = '',
    this.password = '',
    this.usernameError,
    this.passwordError,
    this.apiError,
    this.isSubmitting = false,
    this.isSuccess = false,
  });

  final String username;
  final String password;
  final String? usernameError;
  final String? passwordError;
  final String? apiError;
  final bool isSubmitting;
  final bool isSuccess;

  AuthState copyWith({
    String? username,
    String? password,
    String? usernameError,
    String? passwordError,
    String? apiError,
    bool? isSubmitting,
    bool? isSuccess,
  }) {
    return AuthState(
      username: username ?? this.username,
      password: password ?? this.password,
      usernameError: usernameError,
      passwordError: passwordError,
      apiError: apiError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
    username,
    password,
    usernameError,
    passwordError,
    apiError,
    isSubmitting,
    isSuccess,
  ];
}
