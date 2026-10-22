import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class RetryQueueService extends GetxService {
  static RetryQueueService get to => Get.find();
  final GetStorage _storage = GetStorage();
  final RxInt pendingCount = 0.obs;

  static const _queueKey = 'retry_queue';

  @override
  void onInit() {
    super.onInit();
    _loadCount();
  }

  void _loadCount() {
    final queue = _storage.read<List>(_queueKey) ?? [];
    pendingCount.value = queue.length;
  }

  void enqueue(Map<String, dynamic> task) {
    final queue = List<Map<String, dynamic>>.from(
      (_storage.read<List>(_queueKey) ?? []).cast<Map<String, dynamic>>(),
    );
    queue.add(task);
    _storage.write(_queueKey, queue);
    pendingCount.value = queue.length;
  }

  void dequeue(String taskId) {
    final queue = List<Map<String, dynamic>>.from(
      (_storage.read<List>(_queueKey) ?? []).cast<Map<String, dynamic>>(),
    );
    queue.removeWhere((t) => t['id'] == taskId);
    _storage.write(_queueKey, queue);
    pendingCount.value = queue.length;
  }

  List<Map<String, dynamic>> getQueue() {
    return List<Map<String, dynamic>>.from(
      (_storage.read<List>(_queueKey) ?? []).cast<Map<String, dynamic>>(),
    );
  }

  void clearQueue() {
    _storage.remove(_queueKey);
    pendingCount.value = 0;
  }
}
