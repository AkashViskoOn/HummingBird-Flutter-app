import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/apis/message_api.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:intl/intl.dart';

class BirdController extends GetxController {
  GetStorage storage = GetStorage();
  RxBool startApplication = true.obs;
  RxBool showLoading = false.obs;
  DateTime currentDate = DateTime.now();
  RxString selectedDate = ''.obs;
  RxInt selectedDateIndex = 0.obs;
  UserController userController = Get.find();
  Map<String, List<Messages>> scheduledMessagesMap = {};
  RxList scheduledDates = [].obs;
  List<Messages> allScheduledMessages = [];

  RxDouble uploadValue = 0.0.obs;
  RxMap downloadingMediaMap = {}.obs;
  RxString mediaCompressionQuality = 'medium'.obs;
  RxBool autoCompressMedia = false.obs;

  int getContactsLength() {
    int length = storage.read('contact-length') ?? 0;
    return length;
  }

  bool checkLogin() {
    if (userController.storage.read('isLoggedIn') ?? false) {
      return true;
    } else {
      return false;
    }
  }

  void updateIndex(int index) {
    selectedDateIndex.value = index;
    update();
  }

  /// Wipes the previous account's schedule data from memory on logout /
  /// account switch. The controller instance survives re-login, so this must
  /// run to stop the old account's schedules showing for a new number.
  void resetAccountData() {
    scheduledMessagesMap = {};
    scheduledDates.clear();
    allScheduledMessages = [];
    scheduleCategories.clear();
    scheduleTemplates.clear();
    draftSchedules.clear();
    upcomingSchedules.clear();
    failedSchedules.clear();
    filteredSchedules.clear();
    selectedDateIndex.value = 0;
    selectedDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now());
    downloadingMediaMap.clear();
    showLoading.value = false;
  }

  void selectDate({String? date}) {
    if (date == null && scheduledMessagesMap.keys.toList().isEmpty) {
      selectedDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now());
      update();
    } else {
      final targetDate = date ?? _preferredDateKey();
      selectedDate.value = targetDate;
      allScheduledMessages = scheduledMessagesMap[targetDate] ?? [];
      update();
    }
  }

  /// Picks the date the user most likely wants to see: today when it has
  /// schedules, otherwise the next upcoming date with schedules, otherwise
  /// the most recent one.
  String _preferredDateKey() {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final keys = scheduledDates.cast<String>()..sort();

    if (keys.isEmpty) return todayKey;
    if (keys.contains(todayKey) &&
        (scheduledMessagesMap[todayKey]?.isNotEmpty ?? false)) {
      return todayKey;
    }

    final today = DateTime(now.year, now.month, now.day);
    for (final key in keys) {
      final date = DateTime.tryParse(key);
      if (date != null && !date.isBefore(today)) return key;
    }
    return keys.last;
  }

  Future<void> getScheduledMessages() async {
    showLoading.value = true;
    try {
      List<Messages> scheduledMessages = [];
      try {
        scheduledMessages = await MessageApi().getAllScheduledMessages();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('getScheduledMessages API error: $e');
        }
      }

      final Map<String, List<Messages>> messagesMap = {};
      for (var message in scheduledMessages) {
        final scheduledAt = int.tryParse(message.mScheduledAt ?? '');
        if (scheduledAt == null || scheduledAt <= 0) continue;

        // A legacy desktop bug stored `m_scheduled_at` as milliseconds read back
        // as seconds, so those rows carry ~1970 dates. A schedule cannot predate
        // the app, so drop anything before Y2K instead of rendering "14 Feb 1970".
        if (scheduledAt < 946684800) continue;

        final DateTime date =
            DateTime.fromMillisecondsSinceEpoch(scheduledAt * 1000);
        final key = DateFormat('yyyy-MM-dd').format(date);

        if (!messagesMap.containsKey(key)) {
          messagesMap[key] = [];
        }
        messagesMap[key]!.add(message);
      }

      // Scheduled message content is stored 5-layer encrypted — decrypt it so
      // lists (Today's Schedule etc.) show real text instead of ciphertext.
      try {
        final encrypted = messagesMap.values
            .expand((list) => list)
            .map((m) => m.mMessage ?? '')
            .toList();
        if (encrypted.isNotEmpty) {
          final decrypted = await EncryptionHelper.decryptListAsync(encrypted);
          var i = 0;
          for (final list in messagesMap.values) {
            for (final message in list) {
              message.mMessage = decrypted[i++];
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('getScheduledMessages decrypt error: $e');
        }
      }

      scheduledMessagesMap = messagesMap;
      scheduledDates.value = messagesMap.keys.toList()..sort();
      selectDate();
      updateIndex(0);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getScheduledMessages error: $e');
      }
    } finally {
      showLoading.value = false;
    }
  }

  bool hasScheduledForRoom(String roomId) {
    for (var messages in scheduledMessagesMap.values) {
      if (messages.any((m) => m.mRoomId == roomId)) return true;
    }
    return false;
  }

  /// Returns the next pending (future) scheduled message for a given room, or
  /// null if that room has no upcoming schedule. Used to show a subtle
  /// "Scheduled for ..." hint in the home chat list.
  Messages? nextScheduledForRoom(String roomId) {
    Messages? next;
    int? nextAt;
    final now = DateTime.now();
    for (final list in scheduledMessagesMap.values) {
      for (final m in list) {
        if (m.mRoomId != roomId) continue;
        final at = int.tryParse(m.mScheduledAt ?? '');
        if (at == null || at <= 0) continue;
        if (DateTime.fromMillisecondsSinceEpoch(at * 1000).isBefore(now)) {
          continue;
        }
        if (nextAt == null || at < nextAt) {
          nextAt = at;
          next = m;
        }
      }
    }
    return next;
  }

  /// All future (pending) scheduled messages, sorted soonest-first. Used by
  /// the compact home "Upcoming" section. Failed/cancelled/delivered
  /// schedules have past timestamps and are naturally excluded.
  List<Messages> upcomingScheduledMessages() {
    final now = DateTime.now();
    final upcoming = <Messages>[];
    for (final list in scheduledMessagesMap.values) {
      for (final m in list) {
        final at = int.tryParse(m.mScheduledAt ?? '');
        if (at == null || at <= 0) continue;
        final date = DateTime.fromMillisecondsSinceEpoch(at * 1000);
        if (date.isAfter(now)) upcoming.add(m);
      }
    }
    upcoming.sort((a, b) => (int.tryParse(a.mScheduledAt ?? '') ?? 0)
        .compareTo(int.tryParse(b.mScheduledAt ?? '') ?? 0));
    return upcoming;
  }

  void cancelScheduledMessage(Messages message, int index) async {
    if (message.mId == null) return;
    var data = await MessageApi().cancelScheduledMessage(message.mId!);

    if (data['status'] == true) {
      message.mStatus = 'cancelled';
      LocalDatabase.saveMessage([message]);
      Utils.showGetSnackBar('Schedule cancelled');
      await getScheduledMessages();
    } else {
      Utils.showGetSnackBar('Something went wrong');
    }
  }

  Future<bool> rescheduleMessage({
    required Messages message,
    required DateTime scheduledAt,
    required int interval,
    required int count,
  }) async {
    final data = await MessageApi().updateMessage({
      'm_id': message.mId,
      'new_message': null,
      'message_status': null,
      'seen_by': null,
      'scheduled_at': (scheduledAt.millisecondsSinceEpoch ~/ 1000).toString(),
      'm_interval': interval.toString(),
      'm_count': interval == 0
          ? '0'
          : count == 0
              ? '-1'
              : count.toString(),
    });

    if (data?.status ?? false) {
      await getScheduledMessages();
      Utils.showGetSnackBar('Schedule updated');
      return true;
    }

    Utils.showGetSnackBar('Unable to reschedule message');
    return false;
  }

  /// Single update call for the unified "Edit Schedule" dialog — text,
  /// scheduled time, repeat interval and occurrence count in one API hit.
  Future<bool> updateScheduledMessage({
    required Messages message,
    String? newMessage,
    DateTime? scheduledAt,
    int? interval,
    int? count,
  }) async {
    final data = await MessageApi().updateMessage({
      'm_id': message.mId,
      'new_message': (newMessage == null || newMessage.isEmpty)
          ? null
          : EncryptionHelper().encryptMessage(newMessage.trim()),
      'message_status': null,
      'seen_by': null,
      'scheduled_at': scheduledAt == null
          ? null
          : (scheduledAt.millisecondsSinceEpoch ~/ 1000).toString(),
      'm_interval': interval?.toString(),
      'm_count': interval == null
          ? null
          : interval == 0
              ? '0'
              : (count == null || count == 0)
                  ? '-1'
                  : count.toString(),
    });

    if (data?.status ?? false) {
      await getScheduledMessages();
      Utils.showGetSnackBar('Schedule updated');
      return true;
    }

    Utils.showGetSnackBar('Unable to update schedule');
    return false;
  }

  /// Cancels a schedule by id — used from the Details screen and the
  /// scheduled-message bubble menu where the list index isn't known.
  Future<bool> cancelScheduleById(String messageId) async {
    final data = await MessageApi().cancelScheduledMessage(messageId);
    if (data['status'] == true) {
      Messages? cancelled;
      for (final list in scheduledMessagesMap.values) {
        for (final m in list) {
          if (m.mId == messageId) {
            cancelled = m;
            break;
          }
        }
        if (cancelled != null) break;
      }
      if (cancelled != null) {
        cancelled.mStatus = 'cancelled';
        LocalDatabase.saveMessage([cancelled]);
      }
      Utils.showGetSnackBar('Schedule cancelled');
      await getScheduledMessages();
      return true;
    }
    Utils.showGetSnackBar('Something went wrong');
    return false;
  }

  // ══════════════════════════════════════════
  // PHASE 2 - SMART SCHEDULING 2.0
  // ══════════════════════════════════════════

  RxList<String> scheduleCategories = <String>[].obs;
  RxList scheduleTemplates = [].obs;
  RxList draftSchedules = [].obs;
  RxList upcomingSchedules = [].obs;
  RxList failedSchedules = [].obs;
  RxList<Messages> filteredSchedules = <Messages>[].obs;
  RxString selectedCategory = 'all'.obs;
  RxString scheduleSearchQuery = ''.obs;
  RxBool isScheduleSearching = false.obs;
  RxString activeScheduleFilter = 'all'.obs;
  TextEditingController scheduleSearchController = TextEditingController();

  Future<void> loadScheduleCategories() async {
    try {
      final res =
          await ApiService().getData(path: Endpoints.scheduleCategories);
      if (res['status'] == true && res['data'] is List) {
        scheduleCategories.value = List<String>.from(res['data']);
      }
    } catch (e) {
      scheduleCategories.value = [
        'all',
        'birthday',
        'anniversary',
        'reminder',
        'promotional',
        'meeting',
        'follow-up',
        'greeting',
        'emergency',
        'custom'
      ];
    }
  }

  Future<void> saveTemplate(Map<String, dynamic> template) async {
    try {
      await ApiService()
          .post(path: Endpoints.saveScheduleTemplate, data: template);
      await loadTemplates();
    } catch (e) {
      Utils.showGetSnackBar('Failed to save template');
    }
  }

  Future<void> loadTemplates() async {
    try {
      final res =
          await ApiService().getData(path: Endpoints.getScheduleTemplates);
      if (res['status'] == true && res['data'] != null) {
        scheduleTemplates.value = res['data'];
      }
    } catch (e) {/* silent */}
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      await ApiService().getData(
          path: Endpoints.deleteScheduleTemplate,
          queryParameters: {'template_id': templateId});
      await loadTemplates();
    } catch (e) {/* silent */}
  }

  Future<void> loadUpcomingSchedules() async {
    try {
      final res = await ApiService().getData(path: Endpoints.upcomingSchedules);
      if (res['status'] == true && res['data'] != null) {
        upcomingSchedules.value = res['data'];
        failedSchedules.value =
            upcomingSchedules.where((s) => s['m_status'] == 'failed').toList();
      }
    } catch (e) {/* silent */}
  }

  Future<void> saveDraft(Map<String, dynamic> draft) async {
    final drafts = _localDrafts();
    drafts.insert(0, {
      ...draft,
      'draft_id': DateTime.now().millisecondsSinceEpoch,
    });
    GetStorage().write(_draftsKey, drafts);
    draftSchedules.value = drafts;
    try {
      await ApiService().post(path: Endpoints.saveDraftScheduled, data: draft);
    } catch (_) {/* local copy is enough */}
    Utils.showGetSnackBar('Draft saved');
  }

  Future<void> loadDrafts() async {
    draftSchedules.value = _localDrafts();
    try {
      final res = await ApiService().getData(path: Endpoints.getDraftScheduled);
      if (res['status'] == true && res['data'] is List) {
        final remote =
            res['data'].map((e) => Map<String, dynamic>.from(e)).toList();
        final local = _localDrafts().where((l) => remote.every(
            (r) => r['draft_id'].toString() != l['draft_id'].toString()));
        draftSchedules.assignAll([...remote, ...local]);
        GetStorage().write(_draftsKey, draftSchedules.toList());
      }
    } catch (e) {/* keep local */}
  }

  Future<void> deleteDraft(String draftId) async {
    final drafts = _localDrafts();
    drafts.removeWhere((d) => d['draft_id'].toString() == draftId.toString());
    GetStorage().write(_draftsKey, drafts);
    draftSchedules.value = drafts;
    try {
      await ApiService().getData(
          path: Endpoints.deleteDraftScheduled,
          queryParameters: {'draft_id': draftId});
    } catch (e) {/* local copy is enough */}
  }

  static const _draftsKey = 'schedule_drafts';

  List<Map<String, dynamic>> _localDrafts() {
    final stored = GetStorage().read<List>(_draftsKey) ?? [];
    return stored
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> retryFailedSchedule(String messageId) async {
    try {
      final res = await ApiService()
          .post(path: Endpoints.retryFailedSchedule, data: {'m_id': messageId});
      if (res['status'] == true) {
        Utils.showGetSnackBar('Schedule retried');
        await getScheduledMessages();
        await loadUpcomingSchedules();
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to retry schedule');
    }
  }

  Future<Map<String, dynamic>> parseNaturalSchedule(String text) async {
    try {
      final res = await ApiService()
          .post(path: Endpoints.parseNaturalSchedule, data: {'text': text});
      if (res['status'] == true && res['data'] != null) {
        return res['data'];
      }
      return {};
    } catch (e) {
      return _localParseNaturalSchedule(text);
    }
  }

  Map<String, dynamic> _localParseNaturalSchedule(String text) {
    final now = DateTime.now();
    DateTime scheduledAt = now.add(const Duration(hours: 1));
    String category = 'reminder';
    String message = text;

    if (text.toLowerCase().contains('tomorrow')) {
      scheduledAt = now.add(const Duration(days: 1));
    }
    if (text.toLowerCase().contains('next week')) {
      scheduledAt = now.add(const Duration(days: 7));
    }
    if (text.toLowerCase().contains('birthday')) {
      category = 'birthday';
    }
    if (text.toLowerCase().contains('meeting')) {
      category = 'meeting';
    }
    if (text.toLowerCase().contains('remind') ||
        text.toLowerCase().contains('reminder')) {
      category = 'reminder';
    }
    final timeRegex =
        RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false);
    final match = timeRegex.firstMatch(text);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.tryParse(match.group(2) ?? '0') ?? 0;
      final ampm = match.group(3)?.toLowerCase();
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      scheduledAt = DateTime(
          scheduledAt.year, scheduledAt.month, scheduledAt.day, hour, minute);
    }

    return {
      'message': message,
      'scheduled_at': (scheduledAt.millisecondsSinceEpoch ~/ 1000).toString(),
      'category': category,
      'date': DateFormat('yyyy-MM-dd').format(scheduledAt),
      'time': DateFormat('HH:mm').format(scheduledAt),
    };
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    if (category == 'all') {
      filteredSchedules.value = List.from(allScheduledMessages);
    } else {
      filteredSchedules.value = allScheduledMessages
          .where((m) => (m.mMessage?.toLowerCase().contains(category) ?? false))
          .toList();
    }
  }

  void searchSchedules(String query) {
    scheduleSearchQuery.value = query;
    isScheduleSearching.value = query.isNotEmpty;
    if (query.isEmpty) {
      filteredSchedules.value = List.from(allScheduledMessages);
      return;
    }
    final lower = query.toLowerCase();
    filteredSchedules.value = allScheduledMessages.where((m) {
      return (m.mMessage?.toLowerCase().contains(lower) ?? false) ||
          (m.mReceiver?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  Timer? _searchDebounce;
  int _searchRequestId = 0;

  void serverSearchSchedules(String query) {
    scheduleSearchQuery.value = query;
    isScheduleSearching.value = query.isNotEmpty;
    if (query.isEmpty) {
      _searchDebounce?.cancel();
      _searchRequestId++;
      filteredSchedules.value = List.from(allScheduledMessages);
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _runServerSearch(query);
    });
  }

  Future<void> _runServerSearch(String query) async {
    final requestId = ++_searchRequestId;
    try {
      final results = await MessageApi()
          .searchSchedules(query)
          .timeout(const Duration(seconds: 8));
      if (!isScheduleSearching.value || requestId != _searchRequestId) return;
      if (results.isNotEmpty) {
        filteredSchedules.value = results;
        return;
      }
    } catch (_) {}
    if (!isScheduleSearching.value || requestId != _searchRequestId) return;
    searchSchedules(query);
  }

  void setScheduleFilter(String filter) {
    activeScheduleFilter.value = filter;
    if (filter == 'today') {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      filteredSchedules.value = scheduledMessagesMap[today] ?? [];
    } else if (filter == 'tomorrow') {
      final tomorrow = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(const Duration(days: 1)));
      filteredSchedules.value = scheduledMessagesMap[tomorrow] ?? [];
    } else if (filter == 'this_week') {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));
      final all = <Messages>[];
      for (var entry in scheduledMessagesMap.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date != null &&
            date.isAfter(now.subtract(const Duration(days: 1))) &&
            date.isBefore(weekEnd)) {
          all.addAll(entry.value);
        }
      }
      filteredSchedules.value = all;
    } else if (filter == 'completed') {
      filteredSchedules.value = allScheduledMessages
          .where((m) => m.mStatus?.toString() == 'sent')
          .toList();
    } else if (filter == 'cancelled') {
      filteredSchedules.value = allScheduledMessages
          .where((m) => m.mStatus?.toString() == 'cancelled')
          .toList();
    } else if (filter == 'missed') {
      filteredSchedules.value = allScheduledMessages
          .where((m) => m.mStatus?.toString() == 'failed')
          .toList();
    } else if (filter == 'pinned') {
      final pinned =
          List<String>.from(GetStorage().read<List>('pinned_schedules') ?? []);
      filteredSchedules.value =
          allScheduledMessages.where((m) => pinned.contains(m.mId)).toList();
    } else {
      filteredSchedules.value = List.from(allScheduledMessages);
    }
    update(['schedule-filter']);
  }

  Future<void> duplicateMessage(Messages message) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final scheduledAt = int.tryParse(message.mScheduledAt ?? '0') ?? now;
    final newScheduledAt = scheduledAt + 86400;

    final data = await MessageApi().sendMessage({
      'm_room_id': message.mRoomId,
      'm_sender_id': message.mSenderId,
      'm_receiver_id': message.mReceiverId,
      'm_message': message.mMessage,
      'm_message_type': message.mMessageType ?? '0',
      'm_is_scheduled': '1',
      'm_scheduled_at': newScheduledAt.toString(),
      'm_interval': message.interval ?? '0',
      'm_count': message.count ?? '0',
    });

    if (data?.status ?? false) {
      await getScheduledMessages();
      Utils.showGetSnackBar('Message duplicated');
    } else {
      Utils.showGetSnackBar('Failed to duplicate');
    }
  }

  void markComplete(Messages message) {
    final messageId = message.mId;
    allScheduledMessages.removeWhere((m) => m.mId == messageId);
    for (var key in scheduledMessagesMap.keys.toList()) {
      scheduledMessagesMap[key]?.removeWhere((m) => m.mId == messageId);
      if (scheduledMessagesMap[key]?.isEmpty ?? false) {
        scheduledMessagesMap.remove(key);
      }
    }
    scheduledDates.value = scheduledMessagesMap.keys.toList()..sort();
    if (allScheduledMessages.isEmpty) {
      selectedDate.value = '';
    }
    update();
  }

  ImageProvider getImageProvider(String url) {
    if (url.isNotEmpty) {
      return CachedNetworkImageProvider(
          '${Endpoints.mediaBaseUrl}${userController.user!.userImage}');
    } else {
      return const AssetImage(AppAssets.defaultProfilePic);
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scheduleSearchController.dispose();
    super.onClose();
  }

  void updateProfileImage() {
    update(['update-profile-pic']);
  }
}
