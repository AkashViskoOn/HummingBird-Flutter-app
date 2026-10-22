import 'dart:io';
import 'package:get/get.dart';
import 'package:humming_bird/apis/scheduled_moment_api.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';

class ScheduledMomentController extends GetxController {
  final ScheduledMomentApi _api = ScheduledMomentApi();

  String _myUserId = '';

  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxDouble uploadProgress = 0.0.obs;
  final RxString uploadStatus = ''.obs;
  final RxList<ScheduledMoment> scheduledMoments = <ScheduledMoment>[].obs;
  final RxList<ScheduledMoment> draftMoments = <ScheduledMoment>[].obs;
  final RxList<ScheduledMoment> publishedMoments = <ScheduledMoment>[].obs;
  final RxMap<String, List<ScheduledMoment>> calendarMap =
      <String, List<ScheduledMoment>>{}.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initMyUserId();
    _loadFromCache();
    refreshAll();
  }

  /// Wipes the previous account's moments from memory on logout / account
  /// switch (the registered controller instance is reused by GetX).
  void resetAccountData() {
    _myUserId = '';
    scheduledMoments.clear();
    draftMoments.clear();
    publishedMoments.clear();
    calendarMap.clear();
    isLoading.value = false;
    isUploading.value = false;
    uploadProgress.value = 0;
    uploadStatus.value = '';
    errorMessage.value = '';
  }

  void _initMyUserId() {
    try {
      final userController = Get.find<UserController>();
      if (userController.userId.isNotEmpty) {
        _myUserId = userController.userId;
      } else if (userController.user?.userId != null) {
        _myUserId = userController.user!.userId!;
      }
    } catch (_) {}
  }

  void _loadFromCache() {
    try {
      final cached = LocalDatabase.statusBox?.get('scheduled_moments');
      if (cached is List) {
        scheduledMoments.assignAll(
          cached.map(
              (e) => ScheduledMoment.fromJson(Map<String, dynamic>.from(e))),
        );
      }
      final drafts = LocalDatabase.statusBox?.get('draft_moments');
      if (drafts is List) {
        draftMoments.assignAll(
          drafts.map(
              (e) => ScheduledMoment.fromJson(Map<String, dynamic>.from(e))),
        );
      }
      final published = LocalDatabase.statusBox?.get('published_moments');
      if (published is List) {
        publishedMoments.assignAll(
          published.map(
              (e) => ScheduledMoment.fromJson(Map<String, dynamic>.from(e))),
        );
      }
    } catch (_) {}
  }

  void _saveToCache() {
    try {
      LocalDatabase.statusBox?.put(
        'scheduled_moments',
        scheduledMoments.map((e) => e.toJson()).toList(),
      );
      LocalDatabase.statusBox?.put(
        'draft_moments',
        draftMoments.map((e) => e.toJson()).toList(),
      );
      LocalDatabase.statusBox?.put(
        'published_moments',
        publishedMoments.map((e) => e.toJson()).toList(),
      );
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchScheduledMoments(),
      fetchDrafts(),
      fetchPublishedMoments(),
    ]);
  }

  Future<void> fetchScheduledMoments() async {
    await Future<void>.delayed(Duration.zero);
    isLoading.value = true;
    try {
      final list = await _api.fetchList();
      scheduledMoments.assignAll(list);
      publishedMoments.assignAll(list.where((m) => m.isPublished));
      _saveToCache();
    } catch (_) {
      errorMessage.value = 'Failed to load moments';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPublishedMoments() async {
    try {
      final list = await _api.fetchPublished();
      if (list.isNotEmpty) {
        publishedMoments.assignAll(list);
        _saveToCache();
      }
    } catch (_) {}
  }

  Future<void> fetchDrafts() async {
    try {
      final list = await _api.fetchDrafts();
      draftMoments.assignAll(list);
      _saveToCache();
    } catch (_) {}
  }

  void handleSocketEvent(String event, Map<String, dynamic> data) {
    try {
      // Owner-scoped guard: moment events carry sm_user_id. Ignore anyone
      // else's moments — older socket servers broadcast these globally, and
      // inserting them would show strangers' moments in My Moments.
      final ownerId = data['sm_user_id']?.toString();
      if (ownerId != null && ownerId.isNotEmpty && ownerId != _myUserId) {
        return;
      }
      final moment = ScheduledMoment.fromJson(data);
      final hasBody = (moment.smStatus ?? '').isNotEmpty ||
          event == 'moment-deleted' ||
          event == 'moment-expired';
      if (!hasBody) {
        // Ping / incomplete payload — refetch the authoritative list
        // instead of inserting a stub row.
        fetchScheduledMoments();
        return;
      }
      switch (event) {
        case 'moment-created':
          if (moment.smStatus == 'published') {
            publishedMoments.insert(0, moment);
          } else if (moment.smStatus == 'scheduled') {
            scheduledMoments.insert(0, moment);
          }
          break;
        case 'moment-updated':
          _replaceInList(scheduledMoments, moment);
          _replaceInList(publishedMoments, moment);
          _replaceInList(draftMoments, moment);
          break;
        case 'moment-deleted':
          scheduledMoments.removeWhere((m) => m.smId == moment.smId);
          publishedMoments.removeWhere((m) => m.smId == moment.smId);
          draftMoments.removeWhere((m) => m.smId == moment.smId);
          break;
        case 'moment-published':
          scheduledMoments.removeWhere((m) => m.smId == moment.smId);
          publishedMoments.removeWhere((m) => m.smId == moment.smId);
          publishedMoments.insert(0, moment);
          break;
        case 'moment-expired':
          publishedMoments.removeWhere((m) => m.smId == moment.smId);
          break;
      }
      _saveToCache();
    } catch (_) {}
  }

  void _replaceInList(RxList<ScheduledMoment> list, ScheduledMoment moment) {
    final idx = list.indexWhere((m) => m.smId == moment.smId);
    if (idx >= 0) {
      list[idx] = moment;
      list.refresh();
    }
  }

  Future<bool> scheduleMoment({
    required String content,
    File? file,
    String mediaType = 'text',
    required DateTime scheduledAt,
    required String visibility,
    required int expiryHours,
    String? caption,
  }) async {
    isUploading.value = true;
    uploadProgress.value = 0.0;
    uploadStatus.value = 'Scheduling moment...';
    try {
      final scheduledEpoch =
          (scheduledAt.millisecondsSinceEpoch ~/ 1000).toString();
      final cappedHours = expiryHours.clamp(1, 24).toInt();

      final body = <String, dynamic>{
        'content': content,
        'media_type': mediaType,
        'scheduled_at': scheduledEpoch,
        'expiry_hours': cappedHours.toString(),
        'visibility': visibility,
        'caption': caption ?? '',
      };

      if (file != null && (mediaType == 'image' || mediaType == 'video')) {
        uploadStatus.value =
            mediaType == 'image' ? 'Uploading image...' : 'Uploading video...';
        uploadProgress.value = 0.3;
      }

      final result = await _api.schedule(body, file: file);
      if (result != null) {
        uploadProgress.value = 1.0;
        uploadStatus.value = 'Moment scheduled!';
        await fetchScheduledMoments();
        return true;
      }
      uploadStatus.value = 'Failed to schedule moment';
      return false;
    } catch (e) {
      uploadStatus.value = 'Upload failed. Retry?';
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  Future<bool> saveAsDraft({
    required String content,
    String? mediaPath,
    String mediaType = 'text',
    DateTime? scheduledAt,
    String visibility = 'everyone',
    int expiryHours = 24,
  }) async {
    try {
      final body = <String, dynamic>{
        'content': content,
        'media_type': mediaType,
        'media_path': mediaPath ?? '',
        'visibility': visibility,
        'expiry_hours': expiryHours.toString(),
      };
      if (scheduledAt != null) {
        body['scheduled_at'] =
            (scheduledAt.millisecondsSinceEpoch ~/ 1000).toString();
      }
      final success = await _api.saveDraft(body);
      if (success) await fetchDrafts();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMoment(String id) async {
    final success = await _api.delete(id);
    if (success) {
      scheduledMoments.removeWhere((m) => m.smId == id);
      _saveToCache();
    }
    return success;
  }

  Future<bool> deleteDraft(String id) async {
    final success = await _api.deleteDraft(id);
    if (success) {
      draftMoments.removeWhere((m) => m.smId == id);
      _saveToCache();
    }
    return success;
  }

  Future<bool> publishNow(String id) async {
    final success = await _api.publish(id);
    if (success) await fetchScheduledMoments();
    return success;
  }

  Future<bool> cancelScheduled(String id) async {
    final success = await _api.cancel(id);
    if (success) await fetchScheduledMoments();
    return success;
  }

  Future<bool> duplicateMoment(String id) async {
    final success = await _api.duplicate(id);
    if (success) await fetchDrafts();
    return success;
  }

  Future<Map<String, List<ScheduledMoment>>?> fetchCalendar() async {
    try {
      final result = await _api.fetchCalendar();
      if (result != null) {
        calendarMap.assignAll(result);
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  int secondsUntilPublish(ScheduledMoment moment) {
    final epoch = moment.scheduledEpoch;
    if (epoch == null) return 0;
    final diff = DateTime.fromMillisecondsSinceEpoch(epoch * 1000)
        .difference(DateTime.now());
    return diff.inSeconds.clamp(0, diff.inSeconds);
  }
}
