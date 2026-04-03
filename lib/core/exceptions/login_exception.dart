class LoginException {
  String? message;

  LoginException({this.message});

  @override
  String toString() => 'LoginException{message: $message}';
}