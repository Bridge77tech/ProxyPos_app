part of 'connectivity_bloc.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState({required this.isOnline});

  final bool isOnline;

  ConnectivityState copyWith({bool? isOnline}) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [isOnline];
}