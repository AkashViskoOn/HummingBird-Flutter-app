import 'dart:async';
import 'package:get/get.dart';
import 'package:humming_bird/apis/scheduled_moment_api.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:humming_bird/database/local_database.dart';

class StatusScheduleService extends GetxService {
  Timer? _ticker;
  final ScheduledMomentApi _api = ScheduledMomentApi();
  final RxList<ScheduledMoment> pendingQueue = <ScheduledMoment>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadPending();
    _startTicker();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      _processQueue();
    });
  }

  void _loadPending() {
    try {
      final cached = LocalDatabase.statusBox?.get('scheduled_moments');
      if (cached is List) {
        pendingQueue.assignAll(
          cached.map(
              (e) => ScheduledMoment.fromJson(Map<String, dynamic>.from(e))),
        );
      }
    } catch (_) {}
  }

  void _savePending() {
    try {
      LocalDatabase.statusBox?.put(
        'scheduled_moments',
        pendingQueue.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  void addToQueue(ScheduledMoment moment) {
    pendingQueue.add(moment);
    _savePending();
  }

  void removeFromQueue(String smId) {
    pendingQueue.removeWhere((m) => m.smId == smId);
    _savePending();
  }

  Future<void> _processQueue() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final due = pendingQueue.where((m) {
      final epoch = m.scheduledEpoch;
      return epoch != null && epoch <= now && m.isPending;
    }).toList();

    for (final moment in due) {
      try {
        if (moment.smId != null) {
          await _api.publish(moment.smId!);
          removeFromQueue(moment.smId!);
          Get.find<ScheduledMomentController>().fetchScheduledMoments();
        }
      } catch (_) {
        // Will retry on next tick
      }
    }
  }

  void checkAndProcess() {
    _processQueue();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
