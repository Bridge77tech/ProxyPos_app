// Queue mechanics: ordering, the retry cap, held-up entries, and which row gets removed.
//
// No Hive, no network, no connectivity singleton — PendingSalesDrainer takes its storage and its
// submit function as arguments precisely so this can be tested directly.
//
// Every test asserts its precondition before the behaviour it cares about. Nothing in this file is
// wrapped in an `if (found)` or an `if (status == 200)`: assertions inside a conditional that never
// fires are how a suite reports green while testing nothing.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/data/data_source/local/pending_sales_storage.dart';
import 'package:inventory_app_pos/features/home/presentation/presentation/dashboard/domain/services/pending_sales_drainer.dart';

/// In-memory PendingSalesStorage, faithful to the contract the real one implements.
class FakeQueue implements PendingSalesStorage {
  FakeQueue([List<PendingSale>? initial]) : _entries = [...?initial];

  final List<PendingSale> _entries;

  /// Every queueId passed to removeByQueueId, in order — so a test can prove the drainer named the
  /// entry it meant rather than happening to leave the right list behind.
  final List<String> removed = [];

  @override
  Future<void> enqueue(
    Map<String, dynamic> payload, {
    double total = 0,
    List<PendingSaleLine> lines = const [],
  }) async {
    _entries.add(PendingSale(
      queueId: payload['idempotencyKey'] as String,
      payload: Map<String, dynamic>.from(payload),
      total: total,
      lines: lines,
    ));
  }

  @override
  Future<List<PendingSale>> getQueue() async => List.unmodifiable(_entries);

  @override
  Future<void> removeByQueueId(String queueId) async {
    removed.add(queueId);
    _entries.removeWhere((e) => e.queueId == queueId);
  }

  @override
  Future<void> recordAttempt(
    String queueId, {
    required int attempts,
    required bool heldUp,
    String? lastError,
  }) async {
    final i = _entries.indexWhere((e) => e.queueId == queueId);
    if (i < 0) return;
    _entries[i] = _entries[i].copyWith(attempts: attempts, heldUp: heldUp, lastError: lastError);
  }

  @override
  Future<void> resetAttempts(String queueId) async {
    final i = _entries.indexWhere((e) => e.queueId == queueId);
    if (i < 0) return;
    final e = _entries[i];
    _entries[i] = PendingSale(
      queueId: e.queueId,
      payload: e.payload,
      total: e.total,
      lines: e.lines,
    );
  }

  @override
  Future<void> clear() async => _entries.clear();

  List<String> get ids => _entries.map((e) => e.queueId).toList();
  PendingSale byId(String id) => _entries.firstWhere((e) => e.queueId == id);
  bool has(String id) => _entries.any((e) => e.queueId == id);
}

/// A sale payload carrying the key it was created with, as the real one does.
Map<String, dynamic> payloadFor(String key, {double amountPaid = 10}) => {
      'items': [
        {'productId': 'p1', 'variantId': 'v1', 'quantity': 1, 'saleType': 'Single'}
      ],
      'amountPaid': amountPaid,
      'paymentMethod': 'cash',
      'deviceId': 'POS-TABLET-001',
      'idempotencyKey': key,
    };

PendingSale entry(String key, {int attempts = 0, bool heldUp = false, double total = 10}) =>
    PendingSale(
      queueId: key,
      payload: payloadFor(key),
      attempts: attempts,
      heldUp: heldUp,
      total: total,
    );

DioException httpError(int status) => DioException(
      requestOptions: RequestOptions(path: '/pos/sales'),
      response: Response(
        requestOptions: RequestOptions(path: '/pos/sales'),
        statusCode: status,
        data: {'error': 'boom'},
      ),
    );

DioException networkError() => DioException(
      requestOptions: RequestOptions(path: '/pos/sales'),
      type: DioExceptionType.connectionTimeout,
    );

void main() {
  group('classifyFailure', () {
    test('no response is transient — the request may never have landed', () {
      expect(classifyFailure(networkError()), FailureClass.transient);
    });

    test('timeout, rate limit, expired token and 5xx are transient', () {
      for (final status in [408, 429, 401, 500, 502, 503]) {
        expect(classifyFailure(httpError(status)), FailureClass.transient,
            reason: '$status should be retried');
      }
    });

    test('an ordinary 4xx is definitive — the server has refused this payload', () {
      for (final status in [400, 403, 404, 422]) {
        expect(classifyFailure(httpError(status)), FailureClass.definitive,
            reason: '$status cannot succeed until something changes');
      }
    });

    test('an unknown error is transient, because the sale may in fact have been recorded', () {
      // If the server accepted it and we failed to read the reply, retrying returns the existing
      // sale thanks to the idempotency key. Guessing "definitive" would strand a real sale.
      expect(classifyFailure(StateError('parse failed')), FailureClass.transient);
    });
  });

  group('enqueue and drain ordering', () {
    test('sales are sent in the order they were queued', () async {
      final queue = FakeQueue();
      await queue.enqueue(payloadFor('k1'));
      await queue.enqueue(payloadFor('k2'));
      await queue.enqueue(payloadFor('k3'));
      expect(queue.ids, ['k1', 'k2', 'k3'], reason: 'precondition: queued in order');

      final sent = <String>[];
      final report = await PendingSalesDrainer(
        storage: queue,
        submit: (p) async => sent.add(p['idempotencyKey'] as String),
      ).drain();

      expect(sent, ['k1', 'k2', 'k3']);
      expect(report.submitted, 3);
      expect(queue.ids, isEmpty, reason: 'everything sent should be gone');
    });

    test('an empty queue does nothing at all', () async {
      final queue = FakeQueue();
      var calls = 0;
      final report = await PendingSalesDrainer(
        storage: queue,
        submit: (_) async => calls++,
      ).drain();

      expect(calls, 0);
      expect(report.submitted, 0);
      expect(queue.removed, isEmpty);
    });
  });

  group('a failure leaves the queue intact', () {
    test('a transient failure sends nothing and removes nothing', () async {
      final queue = FakeQueue([entry('k1'), entry('k2')]);
      expect(queue.ids, ['k1', 'k2'], reason: 'precondition');

      final report = await PendingSalesDrainer(
        storage: queue,
        submit: (_) async => throw networkError(),
      ).drain();

      expect(queue.ids, ['k1', 'k2'], reason: 'nothing may be dropped on failure');
      expect(queue.removed, isEmpty);
      expect(report.submitted, 0);
      expect(report.stoppedEarly, isTrue);
      expect(queue.byId('k1').attempts, 1);
      // k2 was never attempted — ordering is preserved for anything that might still succeed.
      expect(queue.byId('k2').attempts, 0);
    });

    test('a retryable failure stops the pass, so a later sale cannot jump the queue', () async {
      final queue = FakeQueue([entry('k1'), entry('k2')]);
      final sent = <String>[];

      await PendingSalesDrainer(
        storage: queue,
        submit: (p) async {
          final key = p['idempotencyKey'] as String;
          if (key == 'k1') throw httpError(503);
          sent.add(key);
        },
      ).drain();

      expect(sent, isEmpty, reason: 'k2 must not be sent before k1 succeeds');
      expect(queue.ids, ['k1', 'k2']);
    });
  });

  group('draining removes the correct entry, not a neighbouring one', () {
    test('the entry that succeeded is the one removed', () async {
      // A is already held up so it is skipped; B succeeds; C is definitively refused.
      // If removal were by position — the old removeAt(0) — A would be deleted instead of B.
      final queue = FakeQueue([
        entry('A', attempts: 3, heldUp: true),
        entry('B'),
        entry('C'),
      ]);
      expect(queue.ids, ['A', 'B', 'C'], reason: 'precondition');

      await PendingSalesDrainer(
        storage: queue,
        submit: (p) async {
          if (p['idempotencyKey'] == 'C') throw httpError(400);
        },
      ).drain();

      expect(queue.removed, ['B'], reason: 'removal must name B, not index 0');
      expect(queue.ids, ['A', 'C'], reason: 'A and C must both survive');
      expect(queue.has('A'), isTrue, reason: 'the held-up entry must never be deleted');
    });

    test('a successful middle sale does not disturb its neighbours', () async {
      final queue = FakeQueue([entry('A'), entry('B'), entry('C')]);

      await PendingSalesDrainer(
        storage: queue,
        submit: (p) async {
          // A and C are refused definitively, so both end up held up and the pass continues.
          if (p['idempotencyKey'] != 'B') throw httpError(400);
        },
      ).drain();

      expect(queue.removed, ['B']);
      expect(queue.ids, ['A', 'C']);
      expect(queue.byId('A').heldUp, isTrue);
      expect(queue.byId('C').heldUp, isTrue);
    });
  });

  group('the retry cap', () {
    test('a definitive rejection is held up on the first attempt, not removed', () async {
      final queue = FakeQueue([entry('k1')]);

      await PendingSalesDrainer(
        storage: queue,
        submit: (_) async => throw httpError(400),
      ).drain();

      expect(queue.has('k1'), isTrue, reason: 'a held-up sale is never discarded');
      expect(queue.byId('k1').heldUp, isTrue);
      expect(queue.byId('k1').attempts, kDefinitiveRetryCap);
      expect(queue.removed, isEmpty);
    });

    test('a transient failure is held up only after the transient cap', () async {
      final queue = FakeQueue([entry('k1')]);
      final drainer = PendingSalesDrainer(
        storage: queue,
        submit: (_) async => throw networkError(),
      );

      for (var pass = 1; pass < kTransientRetryCap; pass++) {
        await drainer.drain();
        expect(queue.byId('k1').attempts, pass);
        expect(queue.byId('k1').heldUp, isFalse,
            reason: 'still within budget after $pass attempt(s)');
      }

      await drainer.drain();
      expect(queue.byId('k1').attempts, kTransientRetryCap);
      expect(queue.byId('k1').heldUp, isTrue);
      expect(queue.has('k1'), isTrue, reason: 'exhausting the budget must not delete the sale');
    });

    test('the attempt count is what persists, so the cap cannot be reset by a new pass', () async {
      // The counter lives on the stored entry rather than in the loop. A per-pass counter would
      // never reach the cap, and the queue would stay blocked by exactly the sale this fixes.
      final queue = FakeQueue([entry('k1', attempts: kTransientRetryCap - 1)]);

      await PendingSalesDrainer(
        storage: queue,
        submit: (_) async => throw networkError(),
      ).drain();

      expect(queue.byId('k1').heldUp, isTrue,
          reason: 'an entry that arrives one short of the cap must trip on this attempt');
    });

    test('the recorded reason names the status, so the UI can say what went wrong', () async {
      final queue = FakeQueue([entry('k1')]);
      await PendingSalesDrainer(
        storage: queue,
        submit: (_) async => throw httpError(400),
      ).drain();

      expect(queue.byId('k1').lastError, isNotNull);
      expect(queue.byId('k1').lastError, contains('400'));
    });
  });

  group('the queue drains past a held-up sale', () {
    test('a held-up entry is skipped and everything behind it is sent', () async {
      final queue = FakeQueue([
        entry('stuck', attempts: 3, heldUp: true),
        entry('k2'),
        entry('k3'),
      ]);

      final sent = <String>[];
      final report = await PendingSalesDrainer(
        storage: queue,
        submit: (p) async => sent.add(p['idempotencyKey'] as String),
      ).drain();

      expect(sent, ['k2', 'k3'], reason: 'the takings behind the stuck sale must get through');
      expect(report.skipped, 1);
      expect(report.submitted, 2);
      expect(queue.ids, ['stuck'], reason: 'only the held-up sale remains');
    });

    test('a held-up entry is not re-attempted, so its attempt count stops climbing', () async {
      final queue = FakeQueue([entry('stuck', attempts: 3, heldUp: true)]);
      var calls = 0;

      await PendingSalesDrainer(
        storage: queue,
        submit: (_) async => calls++,
      ).drain();

      expect(calls, 0, reason: 'a held-up sale waits for a human, not for another pass');
      expect(queue.byId('stuck').attempts, 3);
    });

    test('one sale being refused does not block the rest in the same pass', () async {
      // The whole point: a definitive rejection at the head must not hold the queue.
      final queue = FakeQueue([entry('bad'), entry('k2'), entry('k3')]);
      final sent = <String>[];

      await PendingSalesDrainer(
        storage: queue,
        submit: (p) async {
          final key = p['idempotencyKey'] as String;
          if (key == 'bad') throw httpError(400);
          sent.add(key);
        },
      ).drain();

      expect(sent, ['k2', 'k3'], reason: 'both later sales must go in this same pass');
      expect(queue.ids, ['bad']);
      expect(queue.byId('bad').heldUp, isTrue);
    });
  });

  group('a retried sale still carries its original idempotency key', () {
    test('every attempt sends the same key', () async {
      final queue = FakeQueue([entry('original-key')]);
      final keysSeen = <String>[];

      final drainer = PendingSalesDrainer(
        storage: queue,
        submit: (p) async {
          keysSeen.add(p['idempotencyKey'] as String);
          throw networkError();
        },
      );

      await drainer.drain();
      await drainer.drain();
      await drainer.drain();

      expect(keysSeen, hasLength(3), reason: 'precondition: three attempts were made');
      expect(keysSeen.toSet(), {'original-key'},
          reason: 'a regenerated key would let the server record the sale twice');
    });

    test('recording a failed attempt does not alter the payload', () async {
      final queue = FakeQueue([entry('original-key')]);
      final before = Map<String, dynamic>.from(queue.byId('original-key').payload);

      await PendingSalesDrainer(
        storage: queue,
        submit: (_) async => throw httpError(400),
      ).drain();

      expect(queue.byId('original-key').payload, before,
          reason: 'held-up bookkeeping lives beside the payload, never inside it');
      expect(queue.byId('original-key').idempotencyKey, 'original-key');
    });

    test('a manual retry clears the flag but keeps the key', () async {
      final queue = FakeQueue([entry('original-key', attempts: 3, heldUp: true)]);

      await queue.resetAttempts('original-key');

      expect(queue.byId('original-key').heldUp, isFalse);
      expect(queue.byId('original-key').attempts, 0);
      expect(queue.byId('original-key').idempotencyKey, 'original-key',
          reason: 'retry must be safe, which is only true while the key survives');
    });
  });

  group('stored shape', () {
    test('a bare payload from an older build is read as a fresh entry', () async {
      // Devices in the field have queued sales stored as raw payload maps. A shop that went offline
      // before this change still has takings on the tablet; losing them to a schema change would be
      // worse than the bug being fixed.
      final legacy = PendingSale.fromStored(payloadFor('legacy-key'), fallbackId: 'legacy-0');

      expect(legacy.payload['idempotencyKey'], 'legacy-key');
      expect(legacy.attempts, 0, reason: 'it must get the full budget, not be held up on sight');
      expect(legacy.heldUp, isFalse);
      expect(legacy.queueId, 'legacy-key');
    });

    test('a legacy payload with no key still gets a stable id', () async {
      final noKey = {'items': <dynamic>[], 'amountPaid': 5};
      final restored = PendingSale.fromStored(noKey, fallbackId: 'legacy-7');
      expect(restored.queueId, 'legacy-7');
    });

    test('the current shape round-trips through storage', () async {
      final original = PendingSale(
        queueId: 'k1',
        payload: payloadFor('k1'),
        attempts: 2,
        heldUp: true,
        lastError: '400: no stock',
        total: 42.5,
        lines: const [
          PendingSaleLine(productName: 'Bottled Water', unitType: 'Pack', quantity: 2, unitPrice: 20)
        ],
      );

      final restored = PendingSale.fromStored(original.toMap(), fallbackId: 'unused');

      expect(restored.queueId, 'k1');
      expect(restored.attempts, 2);
      expect(restored.heldUp, isTrue);
      expect(restored.lastError, '400: no stock');
      expect(restored.total, 42.5);
      expect(restored.lines, hasLength(1));
      expect(restored.lines.first.productName, 'Bottled Water');
      expect(restored.lines.first.lineTotal, 40);
      expect(restored.idempotencyKey, 'k1');
    });
  });
}
