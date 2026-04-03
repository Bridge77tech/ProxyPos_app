class LocalStorageException implements Exception {
  dynamic message;

  LocalStorageException({this.message});

  @override
  String toString() {
    Object? message = this.message;
    if (message == null) return "LocalStorageException";
    return "Exception: $message";
  }
}