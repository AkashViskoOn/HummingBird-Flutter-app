import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();

  final Connectivity _connectivity = Connectivity();
  final RxBool isOnline = true.obs;
  final Rx<ConnectivityResult?> connectionType = Rx<ConnectivityResult?>(null);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  /// Re-checks the platform connectivity state through the same channel as
  /// [onInit] — never creates a new instance or listener.
  Future<void> refresh() => _init();

  Future<void> _init() async {
    try {
      final result = await _connectivity.checkConnectivity();
      isOnline.value = !result.contains(ConnectivityResult.none);
      connectionType.value = _pickType(result);
    } catch (_) {}
    try {
      _subscription ??= _connectivity.onConnectivityChanged.listen((result) {
        isOnline.value = !result.contains(ConnectivityResult.none);
        connectionType.value = _pickType(result);
      });
    } catch (_) {}
  }

  static ConnectivityResult? _pickType(List<ConnectivityResult> results) {
    for (final result in results) {
      if (result != ConnectivityResult.none) return result;
    }
    return results.isEmpty ? null : results.first;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
