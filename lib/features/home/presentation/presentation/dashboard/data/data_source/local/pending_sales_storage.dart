import 'dart:math';

import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/user_local_storage.dart';

/// One line of a queued sale, for display only.
///
/// The wire payload carries ids and quantities and no prices — deliberately, since the server
/// prices the sale. But a cashier looking at a stuck order needs to see what is in it, and by then
/// the cart that knew the names and prices is long gone. So a snapshot is taken at enqueue time,
/// which is the only moment the information exists.
///
/// Nothing here is ever sent to the server.
class PendingSaleLine {
  const PendingSaleLine({
    required this.productName,
    required this.unitType,
    required this.quantity,
    required this.unitPrice,
  });

  final String productName;
  final String unitType;
  final int quantity;
  final double unitPrice;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'productName': productName,
        'unitType': unitType,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  static PendingSaleLine fromMap(Map<dynamic, dynamic> map) => PendingSaleLine(
        productName: (map['productName'] as String?) ?? 'Unknown item',
        unitType: (map['unitType'] as String?) ?? '',
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      );
}

/// A sale waiting to be sent, plus the bookkeeping the drain loop needs.
///
/// `payload` is untouched and is what gets POSTed. Everything else is metadata stored beside it —
/// in particular the attempt count, which MUST live on disk rather than in memory: a counter that
/// resets on every app launch would never reach its cap, and the queue would stay blocked forever
/// by exactly the sale this class exists to get past.
class PendingSale {
  const PendingSale({
    required this.queueId,
    required this.payload,
    this.attempts = 0,
    this.heldUp = false,
    this.lastError,
    this.total = 0,
    this.lines = const [],
  });

  /// Stable identity, independent of position in the queue.
  ///
  /// The drain loop used to remove index 0 and rely on the next entry sliding into its place. That
  /// was correct, but only as long as nobody changed the loop — and it stops being correct the
  /// moment the loop can skip an entry, which is precisely what held-up sales require. Removing by
  /// id cannot address the wrong row no matter what order the loop visits things in.
  final String queueId;

  final Map<String, dynamic> payload;
  final int attempts;

  /// Failed its retry cap. Skipped by the drain loop so the queue moves past it, and kept until a
  /// human resolves it. Never a reason to delete a sale.
  final bool heldUp;

  final String? lastError;

  /// Cart total at the time of sale, for the discard confirmation. The payload cannot supply it.
  final double total;

  final List<PendingSaleLine> lines;

  /// The key the sale was created with. Carried through every retry untouched — it is what makes a
  /// retry unable to record a second sale.
  String? get idempotencyKey => payload['idempotencyKey'] as String?;

  /// Whether [line] is the one the failure names.
  ///
  /// The server says which product it refused — "Insufficient stock for Bottled Water - 500ml" —
  /// so the line can usually be picked out, and the cashier is shown the item to deal with rather
  /// than a whole order marked bad.
  ///
  /// When nothing matches, EVERY line is flagged rather than none. A held-up order that shows no
  /// marker anywhere would contradict the badge that sent the cashier looking, and "we cannot tell
  /// which item" is better said by marking all of them than by saying nothing.
  bool isLineAffected(PendingSaleLine line) {
    if (!heldUp) return false;

    final reason = lastError?.toLowerCase();
    if (reason == null || reason.isEmpty) return true;

    final anyNamed = lines.any((l) =>
        l.productName.isNotEmpty && reason.contains(l.productName.toLowerCase()));
    if (!anyNamed) return true;

    return line.productName.isNotEmpty && reason.contains(line.productName.toLowerCase());
  }

  PendingSale copyWith({int? attempts, bool? heldUp, String? lastError}) => PendingSale(
        queueId: queueId,
        payload: payload,
        attempts: attempts ?? this.attempts,
        heldUp: heldUp ?? this.heldUp,
        lastError: lastError ?? this.lastError,
        total: total,
        lines: lines,
      );

  Map<String, dynamic> toMap() => {
        'queueId': queueId,
        'payload': payload,
        'attempts': attempts,
        'heldUp': heldUp,
        'lastError': lastError,
        'total': total,
        'lines': lines.map((l) => l.toMap()).toList(),
      };

  /// Reads either the current shape or a bare payload written by an earlier build.
  ///
  /// Devices in the field have queued sales stored as raw payload maps with no metadata at all.
  /// They must keep working: a shop that went offline before this change still has takings on the
  /// tablet, and losing them to a schema change would be far worse than the bug being fixed.
  static PendingSale fromStored(Map<dynamic, dynamic> stored, {required String fallbackId}) {
    final looksWrapped = stored.containsKey('payload') && stored['payload'] is Map;

    if (!looksWrapped) {
      // A bare payload from an older build. Treated as a fresh entry, so it gets the full retry
      // budget rather than being held up on sight.
      return PendingSale(
        queueId: (stored['idempotencyKey'] as String?) ?? fallbackId,
        payload: Map<String, dynamic>.from(stored),
      );
    }

    return PendingSale(
      queueId: (stored['queueId'] as String?) ?? fallbackId,
      payload: Map<String, dynamic>.from(stored['payload'] as Map),
      attempts: (stored['attempts'] as num?)?.toInt() ?? 0,
      heldUp: stored['heldUp'] == true,
      lastError: stored['lastError'] as String?,
      total: (stored['total'] as num?)?.toDouble() ?? 0,
      lines: ((stored['lines'] as List?) ?? const [])
          .map((e) => PendingSaleLine.fromMap(e as Map))
          .toList(),
    );
  }
}

/// Local queue for pending sales payloads when offline.
abstract class PendingSalesStorage {
  Future<void> enqueue(
    Map<String, dynamic> payload, {
    double total,
    List<PendingSaleLine> lines,
  });

  Future<List<PendingSale>> getQueue();

  /// Removes one entry by identity. Never by position.
  Future<void> removeByQueueId(String queueId);

  /// Records a failed attempt, and whether that attempt exhausted the entry's budget.
  Future<void> recordAttempt(
    String queueId, {
    required int attempts,
    required bool heldUp,
    String? lastError,
  });

  /// Clears the held-up flag and the attempt count so a manual retry gets a fresh budget.
  Future<void> resetAttempts(String queueId);

  Future<void> clear();
}

String _generateQueueId() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(8, (_) => rnd.nextInt(256));
  return 'q-${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
}

class PendingSalesStorageImpl extends BaseUserLocalStorage<List<dynamic>>
    implements PendingSalesStorage {
  PendingSalesStorageImpl._()
      : super(
          boxType: StorageBox.createNewSale,
          storageKey: 'pending_sales_queue',
          loggerName: 'PendingSalesStorage',
        );

  static final instance = PendingSalesStorageImpl._();

  @override
  Future<void> enqueue(
    Map<String, dynamic> payload, {
    double total = 0,
    List<PendingSaleLine> lines = const [],
  }) async {
    final queue = await getQueue();
    queue.add(PendingSale(
      // Prefer the sale's own idempotency key as the queue id: one sale, one identity, and it
      // makes the stored rows readable when debugging a device.
      queueId: (payload['idempotencyKey'] as String?) ?? _generateQueueId(),
      payload: Map<String, dynamic>.from(payload),
      total: total,
      lines: lines,
    ));
    await _save(queue);
  }

  @override
  Future<List<PendingSale>> getQueue() async {
    final data = await super.getStorageData();
    if (data == null) return <PendingSale>[];

    final raw = List<dynamic>.from(data);
    final entries = <PendingSale>[];
    for (var i = 0; i < raw.length; i++) {
      entries.add(PendingSale.fromStored(
        raw[i] as Map,
        // Only reached for a legacy entry with no idempotency key either. Derived from position so
        // repeated reads of an unchanged queue agree with each other.
        fallbackId: 'legacy-$i',
      ));
    }
    return entries;
  }

  @override
  Future<void> removeByQueueId(String queueId) async {
    final queue = await getQueue();
    final before = queue.length;
    queue.removeWhere((e) => e.queueId == queueId);
    if (queue.length != before) await _save(queue);
  }

  @override
  Future<void> recordAttempt(
    String queueId, {
    required int attempts,
    required bool heldUp,
    String? lastError,
  }) async {
    await _mutate(queueId, (e) => e.copyWith(
          attempts: attempts,
          heldUp: heldUp,
          lastError: lastError,
        ));
  }

  @override
  Future<void> resetAttempts(String queueId) async {
    await _mutate(queueId, (e) => PendingSale(
          queueId: e.queueId,
          payload: e.payload,
          attempts: 0,
          heldUp: false,
          lastError: null,
          total: e.total,
          lines: e.lines,
        ));
  }

  @override
  Future<void> clear() async {
    await super.saveData(<Map<String, dynamic>>[]);
  }

  Future<void> _mutate(String queueId, PendingSale Function(PendingSale) change) async {
    final queue = await getQueue();
    final index = queue.indexWhere((e) => e.queueId == queueId);
    if (index < 0) return;
    queue[index] = change(queue[index]);
    await _save(queue);
  }

  Future<void> _save(List<PendingSale> queue) =>
      super.saveData(queue.map((e) => e.toMap()).toList());
}
