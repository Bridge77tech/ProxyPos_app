class AccessTokenExpiredException implements Exception {
  String? message;

  AccessTokenExpiredException([
    this.message = "Access token expired, consider refreshing the token",
  ]);

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "AccessTokenExpiredException";
    return "AccessTokenExpiredException: $message";
  }
}