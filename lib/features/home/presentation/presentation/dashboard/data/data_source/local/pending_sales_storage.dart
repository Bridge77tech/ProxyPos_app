import 'package:inventory_app_pos/data/storage_box.dart';
import 'package:inventory_app_pos/features/auth/data/data_source/local/user_local_storage.dart';

/// Local queue for pending sales payloads when offline.
abstract class PendingSalesStorage {
  Future<void> enqueue(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getQueue();
  Future<void> removeAt(int index);
  Future<void> clear();
}

class PendingSalesStorageImpl extends BaseUserLocalStorage<List<dynamic>> implements PendingSalesStorage {
  PendingSalesStorageImpl._()
      : super(
          boxType: StorageBox.createNewSale,
          storageKey: 'pending_sales_queue',
          loggerName: 'PendingSalesStorage',
        );

  static final instance = PendingSalesStorageImpl._();

  @override
  Future<void> enqueue(Map<String, dynamic> payload) async {
    final queue = await getQueue();
    queue.add(Map<String, dynamic>.from(payload));
    await super.saveData(queue);
  }

  @override
  Future<List<Map<String, dynamic>>> getQueue() async {
    final data = await super.getStorageData();
    if (data == null) return <Map<String, dynamic>>[];
    final list = List<dynamic>.from(data);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<void> removeAt(int index) async {
    final queue = await getQueue();
    if (index >= 0 && index < queue.length) {
      queue.removeAt(index);
      await super.saveData(queue);
    }
  }

  @override
  Future<void> clear() async {
    await super.saveData(<Map<String, dynamic>>[]);
  }
}

