class SessionExpiredException implements Exception {
  String? message;

  SessionExpiredException([
    this.message = "User session expired, consider loggin in",
  ]);

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "SessionExpiredException";
    return "SessionExpiredException: $message";
  }
}