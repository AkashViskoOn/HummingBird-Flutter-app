import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:humming_bird/apis/status_api.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class StatusController extends GetxController {
  final StatusApi _api = StatusApi();

  String _myUserId = '';

  /// Current user's id (seeded from UserController, refreshed by
  /// /status/my responses). Public so the viewer can resolve the 1:1 room
  /// without re-reading UserController.
  String get myUserId => _myUserId;

  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxString availability = 'Available'.obs;
  final Rx<MyUpdateData?> myUpdate = Rx<MyUpdateData?>(null);
  final RxList<FriendUpdate> friendUpdates = <FriendUpdate>[].obs;
  final RxList<StatusModel> archivedUpdates = <StatusModel>[].obs;
  final RxList<StatusModel> myStatuses = <StatusModel>[].obs;
  final Rx<StatusPrivacyData?> privacy = Rx<StatusPrivacyData?>(null);
  final RxBool feedHasMore = false.obs;
  final RxInt feedPage = 1.obs;
  final RxMap<String, List<Map<String, dynamic>>> viewersMap =
      <String, List<Map<String, dynamic>>>{}.obs;
  final RxString errorMessage = ''.obs;

  // New reactive state
  final RxMap<String, Map<String, int>> reactionsMap =
      <String, Map<String, int>>{}.obs;
  final RxMap<String, List<StatusReply>> repliesMap =
      <String, List<StatusReply>>{}.obs;
  final RxList<Map<String, dynamic>> mutedUsers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> searchResults =
      <Map<String, dynamic>>[].obs;
  final Rx<StatusAnalytics?> analytics = Rx<StatusAnalytics?>(null);
  final RxBool analyticsLoading = false.obs;
  final RxBool analyticsError = false.obs;
  final RxBool isSearching = false.obs;

  // Shares
  final RxMap<String, List<Map<String, dynamic>>> sharesMap =
      <String, List<Map<String, dynamic>>>{}.obs;
  final RxMap<String, int> shareCountMap = <String, int>{}.obs;

  // Upload queue (offline retry)
  final RxList<Map<String, dynamic>> pendingUploads =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, double> uploadProgress = <String, double>{}.obs;
  final RxBool isProcessingUploads = false.obs;

  Timer? _expiryTimer;

  @override
  void onInit() {
    super.onInit();
    _initMyUserId();
    _loadFromCache();
    _loadPendingUploads();
    refreshAll();
    fetchMutedList();
    _setupSocketListeners();
    retryPendingUploads();
    // Enforce the 24h expiry locally even without server/socket events —
    // cached or stale statuses must never outlive their window.
    _expiryTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _pruneExpired());
  }

  @override
  void onClose() {
    _expiryTimer?.cancel();
    super.onClose();
  }

  /// Wipes the previous account's status/moment state from memory on logout /
  /// account switch (the registered controller instance is reused by GetX).
  void resetAccountData() {
    _myUserId = '';
    friendUpdates.clear();
    archivedUpdates.clear();
    myStatuses.clear();
    myUpdate.value = null;
    privacy.value = null;
    viewersMap.clear();
    reactionsMap.clear();
    repliesMap.clear();
    mutedUsers.clear();
    searchResults.clear();
    analytics.value = null;
    sharesMap.clear();
    shareCountMap.clear();
    pendingUploads.clear();
    uploadProgress.clear();
    isSearching.value = false;
    isLoading.value = false;
    errorMessage.value = '';
    feedHasMore.value = false;
    feedPage.value = 1;
  }

  /// Drops statuses whose `su_expires_at` has passed from every local list
  /// (own + friends + my-update circle) and persists the cleanup.
  void _pruneExpired() {
    try {
      final before = friendUpdates.length + myStatuses.length;
      friendUpdates.removeWhere((f) => f.update?.isExpired == true);
      myStatuses.removeWhere((s) => s.isExpired);
      final mu = myUpdate.value;
      if (mu != null && mu.latestUpdate?.isExpired == true) {
        myUpdate.value = MyUpdateData(
          user: mu.user,
          availability: mu.availability,
          latestUpdate: null,
        );
      }
      if (friendUpdates.length + myStatuses.length != before) {
        _saveToCache();
      }
    } catch (_) {}
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

  void _setupSocketListeners() {
    try {
      final chatController = Get.find<ChatController>();
      final IO.Socket socket = chatController.socket;

      const events = [
        'status_created',
        'status_updated',
        'status_deleted',
        'status_seen',
        'status_reaction',
        'status_reply',
        'status_archived',
        'status_restored',
        'status_expired',
        'status_shared',
        'moment-published',
      ];
      for (final event in events) {
        try {
          socket.off(event);
        } catch (_) {}
      }

      socket.on('status_created', (data) {
        final isMine = data is Map<String, dynamic> &&
            data['su_user_id']?.toString() == _myUserId;
        if (isMine) {
          fetchMyStatuses();
        } else {
          fetchFriendUpdates();
        }
      });
      socket.on('status_updated',
          (_) => Future.wait([fetchMyUpdate(), fetchFriendUpdates()]));
      socket.on(
          'status_deleted',
          (_) => Future.wait(
              [fetchMyUpdate(), fetchFriendUpdates(), fetchMyStatuses()]));
      socket.on('status_seen',
          (_) => Future.wait([fetchMyUpdate(), fetchFriendUpdates()]));
      socket.on('status_reaction', (data) {
        if (data is Map<String, dynamic> && data['status_id'] != null) {
          _refreshReactions(data['status_id'].toString());
        }
      });
      socket.on('status_reply', (data) {
        if (data is Map<String, dynamic> && data['srp_status_id'] != null) {
          _refreshReplies(data['srp_status_id'].toString());
          fetchMyStatuses();
        }
      });
      socket.on('status_archived', (_) => fetchArchivedList());
      socket.on('status_restored', (_) => fetchArchivedList());
      socket.on('moment-published', (data) {
        // Also bridge to the Scheduled Moments controller. Because this
        // controller offs+ons 'moment-published' on the shared socket, its
        // registration replaces ChatController's bridge handler — without
        // this forward the moment list would stop updating after the first
        // Status screen opens.
        try {
          if (data is Map<String, dynamic> &&
              Get.isRegistered<ScheduledMomentController>()) {
            Get.find<ScheduledMomentController>()
                .handleSocketEvent('moment-published', data);
          }
        } catch (_) {}
        Future.wait([fetchFriendUpdates(), fetchMyStatuses()]);
      });
      socket.on('status_expired', (data) {
        String? statusId;
        if (data is Map<String, dynamic>)
          statusId = data['status_id']?.toString();
        if (statusId != null) {
          myStatuses.removeWhere((s) => s.suId == statusId);
          friendUpdates.removeWhere((f) => f.update?.suId == statusId);
        } else {
          fetchMyStatuses();
          fetchFriendUpdates();
        }
      });
      socket.on('status_shared', (data) {
        if (data is Map<String, dynamic> && data['status_id'] != null) {
          final statusId = data['status_id'].toString();
          final count = data['share_count'];
          if (count != null) {
            shareCountMap[statusId] = int.tryParse(count.toString()) ?? 0;
          }
          if (data['user_id']?.toString() == _myUserId) {
            final idx = myStatuses.indexWhere((s) => s.suId == statusId);
            if (idx != -1) {
              final s = myStatuses[idx];
              myStatuses[idx] = StatusModel(
                suId: s.suId,
                suUserId: s.suUserId,
                suContent: s.suContent,
                suMediaUrl: s.suMediaUrl,
                suMediaType: s.suMediaType,
                suScheduleId: s.suScheduleId,
                suCreatedAt: s.suCreatedAt,
                suExpiresAt: s.suExpiresAt,
                suIsArchived: s.suIsArchived,
                suPrivacy: s.suPrivacy,
                suBgColor: s.suBgColor,
                suFontStyle: s.suFontStyle,
                suTextColor: s.suTextColor,
                suCaption: s.suCaption,
                suLocation: s.suLocation,
                suLink: s.suLink,
                suMentions: s.suMentions,
                viewCount: s.viewCount,
                reactionCount: s.reactionCount,
                replyCount: s.replyCount,
                shareCount: (s.shareCount ?? 0) + 1,
              );
            }
          }
        }
      });
    } catch (_) {
      Future.delayed(const Duration(seconds: 1), _setupSocketListeners);
    }
  }

  void _loadFromCache() {
    try {
      final cached = LocalDatabase.statusBox?.get('my_update');
      if (cached != null) {
        final loaded = MyUpdateData.fromJson(Map<String, dynamic>.from(cached));
        myUpdate.value = (loaded.latestUpdate?.isExpired == true)
            ? MyUpdateData(
                user: loaded.user,
                availability: loaded.availability,
                latestUpdate: null,
              )
            : loaded;
      }
      final avail = LocalDatabase.statusBox?.get('availability');
      if (avail is String) {
        availability.value = avail;
      }
      final cachedUpdates = LocalDatabase.statusBox?.get('friend_updates');
      if (cachedUpdates is List) {
        friendUpdates.assignAll(
          cachedUpdates
              .map((e) => FriendUpdate.fromJson(Map<String, dynamic>.from(e)))
              .where((f) => f.update?.isExpired != true),
        );
      }
      final cachedArchived = LocalDatabase.statusBox?.get('archived');
      if (cachedArchived is List) {
        archivedUpdates.assignAll(
          cachedArchived
              .map((e) => StatusModel.fromJson(Map<String, dynamic>.from(e))),
        );
      }
      final cachedMyStatuses = LocalDatabase.statusBox?.get('my_statuses');
      if (cachedMyStatuses is List) {
        myStatuses.assignAll(
          cachedMyStatuses
              .map((e) => StatusModel.fromJson(Map<String, dynamic>.from(e)))
              .where((s) => !s.isExpired),
        );
      }
      final cachedPrivacy = LocalDatabase.statusBox?.get('status_privacy');
      if (cachedPrivacy != null) {
        privacy.value = StatusPrivacyData.fromJson(
            Map<String, dynamic>.from(cachedPrivacy));
      }
    } catch (_) {}
  }

  void _saveToCache() {
    try {
      if (myUpdate.value != null) {
        LocalDatabase.statusBox?.put('my_update', myUpdate.value!.toJson());
      }
      LocalDatabase.statusBox?.put('availability', availability.value);
      LocalDatabase.statusBox?.put(
        'friend_updates',
        friendUpdates.map((e) => e.toJson()).toList(),
      );
      LocalDatabase.statusBox?.put(
        'archived',
        archivedUpdates.map((e) => e.toJson()).toList(),
      );
      LocalDatabase.statusBox?.put(
        'my_statuses',
        myStatuses.map((e) => e.toJson()).toList(),
      );
      if (privacy.value != null) {
        LocalDatabase.statusBox?.put('status_privacy', privacy.value!.toJson());
      }
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchMyUpdate(),
      fetchFriendUpdates(),
      fetchArchivedList(),
      fetchMyStatuses(),
      fetchPrivacy(),
    ]);
  }

  Future<void> fetchMyUpdate() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await _api.getMyUpdate();
      if (data != null) {
        myUpdate.value = data;
        if (data.availability?.uaStatus != null) {
          availability.value = data.availability!.uaStatus!;
        }
        _saveToCache();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load updates';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFriendUpdates() async {
    try {
      final updates = await _api.fetchUpdates();
      friendUpdates.assignAll(
          updates.where((u) => u.update?.isExpired != true).toList());
      _saveToCache();
    } catch (_) {}
  }

  Future<void> fetchMyStatuses() async {
    try {
      final data = await _api.fetchMyStatuses();
      if (data != null) {
        myStatuses.assignAll(data.statuses.where((s) => !s.isExpired).toList());
        if (data.user != null && data.user!['user_id'] != null) {
          _myUserId = data.user!['user_id'].toString();
        }
        if (data.privacy != null) {
          privacy.value = StatusPrivacyData.fromJson(data.privacy!);
        }
        _saveToCache();
      }
    } catch (_) {}
  }

  Future<void> fetchPrivacy() async {
    try {
      final data = await _api.fetchPrivacy();
      if (data != null) {
        privacy.value = data;
        _saveToCache();
      }
    } catch (_) {}
  }

  Future<bool> savePrivacy({
    required String privacy,
    List<int> exceptIds = const [],
    List<int> shareIds = const [],
  }) async {
    final success = await _api.savePrivacy(
      privacy: privacy,
      exceptIds: exceptIds,
      shareIds: shareIds,
    );
    if (success) {
      await fetchPrivacy();
    }
    return success;
  }

  Future<bool> reportStatus(String statusId, String reason) async {
    return await _api.report(statusId, reason);
  }

  Future<void> fetchArchivedList() async {
    try {
      final list = await _api.fetchArchived();
      archivedUpdates.assignAll(list);
      _saveToCache();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> createUpdate(
    String content, {
    File? file,
    String mediaType = 'text',
    String? scheduleId,
    String? bgColor,
    String? fontStyle,
    String? textColor,
    String? caption,
    String? location,
    String? link,
    List<int>? mentions,
  }) async {
    isCreating.value = true;
    try {
      final body = <String, dynamic>{
        'content': content,
        'media_type': mediaType,
      };
      if (scheduleId != null) {
        body['schedule_id'] = scheduleId;
      }
      if (bgColor != null) body['bg_color'] = bgColor;
      if (fontStyle != null) body['font_style'] = fontStyle;
      if (textColor != null) body['text_color'] = textColor;
      if (caption != null) body['caption'] = caption;
      if (location != null) body['location'] = location;
      if (link != null) body['link'] = link;
      if (mentions != null && mentions.isNotEmpty) {
        body['mentions'] = mentions;
      }
      final result = await _api.create(body, file: file);
      if (result != null) {
        await Future.wait(
            [fetchMyUpdate(), fetchFriendUpdates(), fetchMyStatuses()]);
      }
      return result;
    } finally {
      isCreating.value = false;
    }
  }

  Future<bool> editUpdate(String updateId, String content) async {
    final success = await _api.edit(updateId, content);
    if (success) {
      await fetchMyUpdate();
    }
    return success;
  }

  Future<bool> viewUpdate(String statusId) async {
    return await _api.view(statusId);
  }

  Future<List<Map<String, dynamic>>> fetchViewers(String statusId) async {
    final viewers = await _api.fetchViewers(statusId);
    viewersMap[statusId] = viewers;
    return viewers;
  }

  Future<bool> changeAvailability(String status) async {
    final success = await _api.changeAvailability(status);
    if (success) {
      availability.value = status;
      _saveToCache();
    }
    return success;
  }

  Future<bool> archiveUpdate(String updateId, bool archive) async {
    final success = await _api.archive(updateId, archive);
    if (success) {
      await Future.wait([
        fetchMyUpdate(),
        fetchFriendUpdates(),
        fetchArchivedList(),
      ]);
    }
    return success;
  }

  Future<bool> deleteUpdate(String id) async {
    final success = await _api.delete(id);
    if (success) {
      // Local removal first — the API refetch can lag, so the feed would
      // otherwise keep showing the deleted status until a manual refresh.
      myStatuses.removeWhere((s) => s.suId == id);
      await Future.wait([
        fetchMyUpdate(),
        fetchFriendUpdates(),
        fetchArchivedList(),
        fetchMyStatuses(),
      ]);
    }
    return success;
  }

  // ── Reactions ───────────────────────────────────────────────────
  /// Returns the raw backend response so callers can tell whether the
  /// reaction was added/changed (`removed == false`) or removed (`true`).
  Future<Map<String, dynamic>?> reactToStatus(
      String statusId, String reaction) async {
    final res = await _api.react(statusId, reaction);
    if (res != null && res['status'] == true) {
      final removed = res['removed'] == true;
      _updateLocalInteraction(statusId, reaction: removed ? null : reaction);
      _refreshReactions(statusId);
    }
    return res;
  }

  Future<void> fetchReactions(String statusId) async {
    final res = await _api.fetchReactions(statusId);
    if (res != null && res['data'] is Map<String, dynamic>) {
      final data = res['data'] as Map<String, dynamic>;
      final grouped = data['reactions'];
      final map = <String, int>{};
      if (grouped is Map<String, dynamic>) {
        grouped.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            map[key] = int.tryParse('${val['count'] ?? 0}') ?? 0;
          }
        });
      } else if (grouped is List) {
        for (final item in grouped) {
          if (item is Map<String, dynamic>) {
            final key = '${item['reaction'] ?? item['emoji'] ?? ''}';
            if (key.isNotEmpty) {
              map[key] = (map[key] ?? 0) + 1;
            }
          }
        }
      }
      reactionsMap[statusId] = map;
    }
  }

  /// Raw reactions payload (counts + users) for a status.
  Future<Map<String, dynamic>?> fetchReactionsDetail(String statusId) async {
    return await _api.fetchReactions(statusId);
  }

  Future<void> _refreshReactions(String statusId) async {
    await fetchReactions(statusId);
  }

  // ── Replies ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> replyToStatus(
      String statusId, String message) async {
    final res = await _api.reply(statusId, message);
    if (res != null && res['status'] == true) {
      _updateLocalInteraction(statusId, replied: true);
      _refreshReplies(statusId);
    }
    return res;
  }

  Future<void> fetchReplies(String statusId) async {
    final replies = await _api.fetchReplies(statusId);
    repliesMap[statusId] = replies;
  }

  Future<void> _refreshReplies(String statusId) async {
    await fetchReplies(statusId);
  }

  /// Optimistically marks a friend status as interacted-with so the feed
  /// highlight appears instantly (the next /status/fetch-updates round-trip
  /// will confirm it server-side).
  void _updateLocalInteraction(String statusId,
      {bool? replied, String? reaction}) {
    final idx = friendUpdates.indexWhere((f) => f.update?.suId == statusId);
    if (idx == -1) return;
    final old = friendUpdates[idx];
    final wasReplied = old.myReply == true;
    final wasReacted = old.myReaction != null;
    final oldCount = old.replyCount ?? 0;
    final newReplied = replied ?? old.myReply;
    final newReaction = reaction == null ? old.myReaction : reaction;
    if (newReplied == old.myReply && newReaction == old.myReaction) return;
    friendUpdates[idx] = FriendUpdate(
      update: old.update,
      author: old.author,
      viewCount: old.viewCount,
      shareCount: old.shareCount,
      replyCount: replied == true && !wasReplied ? oldCount + 1 : oldCount,
      viewed: old.viewed,
      myReaction: newReaction,
      myReply: newReplied,
    );
    if (replied == true && !wasReplied || (reaction != null && !wasReacted)) {
      _saveToCache();
    }
  }

  // ── Mute ─────────────────────────────────────────────────────────
  Future<bool> muteUser(String mutedUserId) async {
    final success = await _api.muteUser(mutedUserId);
    if (success) fetchMutedList();
    return success;
  }

  Future<void> fetchMutedList() async {
    final muted = await _api.fetchMutedList();
    mutedUsers.assignAll(muted);
  }

  // ── Search ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> searchStatuses({
    String? keyword,
    String? dateFrom,
    String? dateTo,
    String? mediaType,
    int page = 1,
  }) async {
    isSearching.value = true;
    try {
      final data = await _api.search(
        keyword: keyword,
        dateFrom: dateFrom,
        dateTo: dateTo,
        mediaType: mediaType,
        page: page,
      );
      if (data != null && data['results'] != null) {
        final list = List<Map<String, dynamic>>.from(data['results']);
        if (page == 1) {
          searchResults.assignAll(list);
        } else {
          searchResults.addAll(list);
        }
        return list;
      }
      return [];
    } finally {
      isSearching.value = false;
    }
  }

  // ── Analytics ────────────────────────────────────────────────────
  Future<void> fetchAnalytics() async {
    analyticsLoading.value = true;
    analyticsError.value = false;
    try {
      final data = await _api.fetchAnalytics();
      if (data == null) {
        analyticsError.value = true;
      } else {
        analytics.value = data;
      }
    } catch (_) {
      analyticsError.value = true;
    } finally {
      analyticsLoading.value = false;
    }
  }

  // ── Upload ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> uploadFile(File file) async {
    return await _api.uploadFile(file);
  }

  // ── Shares ────────────────────────────────────────────────────────
  Future<bool> shareStatus(String statusId) async {
    final count = await _api.share(statusId);
    if (count > 0) {
      shareCountMap[statusId] = count;
    }
    return count > 0;
  }

  Future<List<Map<String, dynamic>>> fetchShares(String statusId) async {
    final shares = await _api.fetchShares(statusId);
    sharesMap[statusId] = shares;
    return shares;
  }

  // ── Offline upload queue ──────────────────────────────────────────
  void _persistPendingUploads() {
    try {
      LocalDatabase.statusBox?.put('pending_uploads', pendingUploads.toList());
    } catch (_) {}
  }

  void _loadPendingUploads() {
    try {
      final cached = LocalDatabase.statusBox?.get('pending_uploads');
      if (cached is List) {
        pendingUploads.assignAll(
          cached.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      }
    } catch (_) {}
  }

  /// Enqueue a status upload that failed (or was made offline).
  /// [payload] holds the create() body; [filePath] is the local media path.
  void enqueueUpload({
    required Map<String, dynamic> payload,
    String? filePath,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    pendingUploads.add({
      'id': id,
      'payload': payload,
      'file_path': filePath,
      'retry_count': 0,
      'queued_at': DateTime.now().toIso8601String(),
    });
    _persistPendingUploads();
    retryPendingUploads();
  }

  void removePendingUpload(String id) {
    pendingUploads.removeWhere((u) => u['id'] == id);
    _persistPendingUploads();
  }

  Future<void> retryPendingUploads() async {
    if (isProcessingUploads.value || pendingUploads.isEmpty) return;
    isProcessingUploads.value = true;
    try {
      final queue = List<Map<String, dynamic>>.from(pendingUploads);
      for (final item in queue) {
        final id = item['id'] as String;
        final payload = Map<String, dynamic>.from(item['payload'] as Map);
        final filePath = item['file_path'] as String?;
        final retries = (item['retry_count'] as num?)?.toInt() ?? 0;
        if (retries >= 3) {
          removePendingUpload(id);
          continue;
        }
        uploadProgress[id] = 0;
        try {
          File? file;
          if (filePath != null && File(filePath).existsSync()) {
            file = File(filePath);
          }
          final result = await _api.create(payload, file: file);
          if (result != null) {
            removePendingUpload(id);
            await Future.wait(
                [fetchMyUpdate(), fetchFriendUpdates(), fetchMyStatuses()]);
          } else {
            pendingUploads[pendingUploads.indexWhere((u) => u['id'] == id)] = {
              ...item,
              'retry_count': retries + 1,
            };
            _persistPendingUploads();
          }
        } catch (_) {
          pendingUploads[pendingUploads.indexWhere((u) => u['id'] == id)] = {
            ...item,
            'retry_count': retries + 1,
          };
          _persistPendingUploads();
        } finally {
          uploadProgress.remove(id);
        }
      }
    } finally {
      isProcessingUploads.value = false;
    }
  }
}
