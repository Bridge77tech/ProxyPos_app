import 'package:equatable/equatable.dart';
import 'package:fasaha_utils/utils_export/fasaha_haus_state_status.dart';

class AuthState extends Equatable {
  const AuthState({
    this.username = '',
    this.password = '',
    this.errorMessage = '',
    this.stateStatus = const InitStatus(),
  });

  final String username;
  final String password;
  final String errorMessage;
  final StateStatus stateStatus;

  AuthState copyWith({
    String? username,
    String? password,
    String? errorMessage,
    StateStatus? stateStatus,
  }) {
    return AuthState(
      username: username ?? this.username,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
      stateStatus: stateStatus ?? this.stateStatus,
    );
  }

  @override
  List<Object?> get props => [
    username,
    password,
    errorMessage,
    stateStatus,
  ];
}
