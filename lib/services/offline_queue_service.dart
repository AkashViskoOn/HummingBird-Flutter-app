import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/services/connectivity_service.dart';

class OfflineQueueService extends GetxService {
  static OfflineQueueService get to => Get.find();
  final GetStorage _storage = GetStorage();
  final RxInt pendingMessages = 0.obs;
  Worker? _connectivityWorker;

  static const _queueKey = 'offline_message_queue';

  /// Set once ChatController is live (post-login) so a reconnect can actually
  /// re-send queued payloads. Until a handler is set the queue is preserved,
  /// never silently dropped.
  Future<void> Function()? resendHandler;

  @override
  void onInit() {
    super.onInit();
    _loadCount();
    _listenConnectivity();
  }

  void _loadCount() {
    final queue = _storage.read<List>(_queueKey) ?? [];
    pendingMessages.value = queue.length;
  }

  void _listenConnectivity() {
    _connectivityWorker = ever(ConnectivityService.to.isOnline, (bool online) {
      if (online) {
        _processQueue();
      }
    });
  }

  void enqueue(Map<String, dynamic> messageData) {
    final queue = List<Map<String, dynamic>>.from(
      (_storage.read<List>(_queueKey) ?? []).cast<Map<String, dynamic>>(),
    );
    queue.add(messageData);
    _storage.write(_queueKey, queue);
    pendingMessages.value = queue.length;
  }

  Future<void> _processQueue() async {
    final queue = getQueue();
    if (queue.isEmpty) return;
    final handler = resendHandler;
    if (handler == null) return;
    await handler();
  }

  void _dequeue(String id) {
    final queue = List<Map<String, dynamic>>.from(
      (_storage.read<List>(_queueKey) ?? []).cast<Map<String, dynamic>>(),
    );
    queue.removeWhere((t) => t['id']?.toString() == id);
    _storage.write(_queueKey, queue);
    pendingMessages.value = queue.length;
  }

  /// Public dequeue so a re-sender can drop an item after confirmation.
  void dequeue(String id) => _dequeue(id);

  List<Map<String, dynamic>> getQueue() {
    return List<Map<String, dynamic>>.from(
      (_storage.read<List>(_queueKey) ?? []).cast<Map<String, dynamic>>(),
    );
  }

  @override
  void onClose() {
    _connectivityWorker?.dispose();
    super.onClose();
  }
}
