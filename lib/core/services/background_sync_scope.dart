/// Marks work the user did not initiate, so a failure can stay quiet.
///
/// The auth interceptor's response to an expired token is to clear the session and
/// throw the user back to the login screen. That is right for a tap the clerk just
/// made, and wrong for the queue flush that runs by itself on reconnect: a till
/// that was offline past its session timeout would eject whoever was standing at
/// it, mid-shift, because a *background* task's token had aged out.
///
/// Requests made inside [run] are marked, and the interceptor then reports the
/// failure without destroying the session. The queued sale stays queued — it is
/// durable and carries an idempotency key — and the next reconnect or login retries
/// it.
///
/// A user-initiated request could in principle overlap a sync and be misread as
/// background. That direction is harmless: the request still fails and the user is
/// simply not logged out, and their next request gets the usual treatment. The
/// reverse mistake — logging someone out for a background failure — is the one that
/// costs a shift.
class BackgroundSyncScope {
  BackgroundSyncScope._();

  static int _depth = 0;

  /// Whether the code currently issuing a request is a background retry.
  static bool get inProgress => _depth > 0;

  /// Runs [body] with background requests marked. Nestable.
  static Future<T> run<T>(Future<T> Function() body) async {
    _depth++;
    try {
      return await body();
    } finally {
      _depth--;
    }
  }
}
