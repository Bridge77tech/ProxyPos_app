/// Why a product fetch failed, in a form the UI can act on.
///
/// The message alone was not enough. The dashboard showed "check your connection" for every
/// failure, including a 500 and a response it could not parse — sending somebody to look at their
/// router while the fault was elsewhere. Sniffing the message string for the word "connection"
/// would be the same guess with extra steps, so the repository classifies it where the
/// DioException is still in hand.
enum ProductFetchFailure {
  /// The request never left, or the server could not be reached.
  offline,

  /// The session is gone. The interceptor has already started the trip back to login.
  unauthorized,

  /// Reached the server; the server could not answer.
  server,

  /// Answered, but not in a shape the till could read. A fault to report, not a network problem.
  malformed,

  unknown,
}

class GetProductException implements Exception {
  final String? message;
  final ProductFetchFailure kind;

  GetProductException(this.message, {this.kind = ProductFetchFailure.unknown});

  @override
  String toString() => 'GetProductException(${kind.name}): $message';
}
