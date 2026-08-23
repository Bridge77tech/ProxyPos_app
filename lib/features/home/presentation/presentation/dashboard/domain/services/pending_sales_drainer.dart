import 'package:dio/dio.dart';

import '../../data/data_source/local/pending_sales_storage.dart';

/// How a failed submit should be treated.
enum FailureClass {
  /// May well succeed next time — a timeout, a deploy, an expired token.
  transient,

  /// The server has refused this payload. It cannot succeed until something changes in the world,
  /// so a human needs to look at it.
  definitive,
}

/// Attempts allowed before a sale is held up.
///
/// The two differ because the failures differ. A `400 insufficient stock` fails identically every
/// time, so spending three reconnects on it just keeps the rest of the morning's takings stuck
/// behind it — it is held up on the first attempt and the queue moves on. A timeout or a 5xx is
/// ordinary flaky-network life and deserves real retries, or the badge cries wolf and cashiers
/// learn to ignore it.
///
/// Retries are event-driven — an offline→online transition, or the home screen mounting — with no
/// timer anywhere. So these are counts of *reconnects*, not of seconds, and three can span a day.
/// That asymmetry is the reason the definitive cap is 1: waiting three reconnects to skip a sale
/// that was never going to be accepted is the bug, not the fix.
const int kTransientRetryCap = 3;
const int kDefinitiveRetryCap = 1;

/// Classify a submit failure.
///
/// Unknown errors count as transient on purpose. If the server accepted the sale and we merely
/// failed to read the response, the sale exists — and retrying is free, because the payload keeps
/// its original idempotency key and the server returns the sale it already recorded rather than
/// creating a second one. Guessing "definitive" would strand a sale that had in fact succeeded.
FailureClass classifyFailure(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;

    // No response at all: the request never landed, or the reply never came back.
    if (status == null) return FailureClass.transient;

    // Timeout and rate-limit are explicitly "try again".
    if (status == 408 || status == 429) return FailureClass.transient;

    // An expired token is why BackgroundSyncScope exists — it reports a failure instead of signing
    // the cashier out mid-shift. The next login drains the queue, so this must not burn the budget
    // as though the sale were malformed.
    if (status == 401) return FailureClass.transient;

    if (status >= 500) return FailureClass.transient;
    if (status >= 400) return FailureClass.definitive;
  }
  return FailureClass.transient;
}

/// What one drain pass did, for logging and for the UI.
class DrainReport {
  const DrainReport({
    this.submitted = 0,
    this.heldUp = 0,
    this.stoppedEarly = false,
    this.skipped = 0,
  });

  final int submitted;
  final int heldUp;

  /// A retryable failure stopped the pass to preserve ordering.
  final bool stoppedEarly;

  /// Entries already held up, stepped over without being touched.
  final int skipped;
}

/// Sends queued sales, one pass at a time.
///
/// ## What changed, and why the two failure paths differ
///
/// This loop used to `break` on the first failure of any kind. That preserved ordering, which is
/// the right instinct, but it meant one permanently-failing sale at the head of the queue blocked
/// every sale behind it indefinitely — a morning's takings sitting on a device while the till
/// looked entirely normal.
///
/// So the two cases are separated:
///
///   * a failure that has NOT exhausted its budget still stops the pass. Ordering is preserved for
///     everything that might yet succeed, exactly as before.
///   * a failure that HAS exhausted its budget marks the entry held up and carries on, so the rest
///     of the queue drains past it in the same pass.
///
/// A held-up sale is skipped, never deleted. It stays in the queue where a human can see it and
/// decide, because the one thing worse than a stuck sale is a silently discarded one.
///
/// ## Retrying cannot double-charge
///
/// Every attempt sends the stored payload unchanged, so it carries the idempotency key the sale was
/// created with. The server records the sale against that key and returns the existing one on any
/// repeat, so a sale that succeeded but whose response was lost is dequeued on the next pass rather
/// than recorded twice. Nothing in this file may ever regenerate that key.
class PendingSalesDrainer {
  PendingSalesDrainer({
    required PendingSalesStorage storage,
    required Future<void> Function(Map<String, dynamic> payload) submit,
    void Function(String message)? log,
  })  : _storage = storage,
        _submit = submit,
        _log = log ?? _noop;

  final PendingSalesStorage _storage;
  final Future<void> Function(Map<String, dynamic> payload) _submit;
  final void Function(String) _log;

  static void _noop(String _) {}

  Future<DrainReport> drain() async {
    final queue = await _storage.getQueue();
    if (queue.isEmpty) return const DrainReport();

    var submitted = 0;
    var heldUp = 0;
    var skipped = 0;

    for (final entry in queue) {
      if (entry.heldUp) {
        // Already exhausted. Stepped over so everything behind it can still go.
        skipped++;
        continue;
      }

      try {
        // The stored payload, byte for byte — same idempotency key as the first attempt.
        await _submit(entry.payload);
        await _storage.removeByQueueId(entry.queueId);
        submitted++;
      } catch (error) {
        final failure = classifyFailure(error);
        final cap = failure == FailureClass.definitive ? kDefinitiveRetryCap : kTransientRetryCap;
        final attempts = entry.attempts + 1;
        final exhausted = attempts >= cap;

        await _storage.recordAttempt(
          entry.queueId,
          attempts: attempts,
          heldUp: exhausted,
          lastError: _describe(error),
        );

        if (exhausted) {
          heldUp++;
          _log('Sale ${entry.queueId} held up after $attempts attempt(s): ${_describe(error)}');
          // Carry on: the point of holding up is that the queue no longer waits on this one.
          continue;
        }

        _log('Sale ${entry.queueId} failed (attempt $attempts of $cap); '
            'stopping this pass to preserve order');
        return DrainReport(
          submitted: submitted,
          heldUp: heldUp,
          skipped: skipped,
          stoppedEarly: true,
        );
      }
    }

    return DrainReport(submitted: submitted, heldUp: heldUp, skipped: skipped);
  }

  /// Short, human-readable reason, kept on the entry so the queue UI can say what went wrong.
  static String _describe(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      final serverMessage = data is Map ? (data['error'] ?? data['message']) : null;
      if (serverMessage != null) return '$status: $serverMessage';
      if (status != null) return 'HTTP $status';
      return error.type.name;
    }
    return error.toString();
  }
}
