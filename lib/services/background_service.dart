import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/apis/scheduled_moment_api.dart';

@pragma('vm:entry-point')
class BackgroundService {
  final service = FlutterBackgroundService();
  Timer? _ticker;

  void initializeBackgroundService() async {
    try {
      await service.configure(
          iosConfiguration: IosConfiguration(),
          androidConfiguration: AndroidConfiguration(
              onStart: backgroundServiceOnStart,
              isForegroundMode: false,
              autoStart: true,
              autoStartOnBoot: true));
    } catch (_) {}
  }

  void startScheduleTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _processDueSchedules();
    });
  }

  Future<void> _processDueSchedules() async {
    try {
      final box = GetStorage();
      final cached = box.read('pending_moments');
      if (cached is! List || cached.isEmpty) return;
      final api = ScheduledMomentApi();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (final item in cached) {
        if (item is Map<String, dynamic>) {
          final epoch = int.tryParse(item['sm_scheduled_at']?.toString() ?? '');
          if (epoch != null && epoch <= now) {
            final id = item['sm_id']?.toString();
            if (id != null) {
              await api.publish(id);
            }
          }
        }
      }
    } catch (_) {}
  }

  void stopTicker() {
    _ticker?.cancel();
  }
}

@pragma('vm:entry-point')
void backgroundServiceOnStart(ServiceInstance service) async {
  await GetStorage.init();
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      final box = GetStorage();
      final cached = box.read('pending_moments');
      if (cached is! List || cached.isEmpty) return;
      final api = ScheduledMomentApi();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      for (final item in cached) {
        if (item is Map<String, dynamic>) {
          final epoch = int.tryParse(item['sm_scheduled_at']?.toString() ?? '');
          if (epoch != null && epoch <= now) {
            final id = item['sm_id']?.toString();
            if (id != null) {
              await api.publish(id);
            }
          }
        }
      }
    } catch (_) {}
  });
}
