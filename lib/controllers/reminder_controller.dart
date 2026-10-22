import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/components/Models/reminder_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/services/notification_service.dart';
import 'package:intl/intl.dart';

/// Manages local follow-up reminders.
///
/// Everything lives in GetStorage — reminders fire as OS local notifications
/// (see [NotificationService.scheduleFollowUpReminder]). When OS notification
/// permission is missing (or the process died and the app is foregrounded),
/// a periodic in-app ticker fires the same reminder as a GetX snackbar so the
/// user is still nudged on the open chat.
class ReminderController extends GetxController {
  static const String storageKey = 'follow_up_reminders';

  GetStorage get _storage => GetStorage();

  final RxList<Reminder> reminders = <Reminder>[].obs;

  Timer? _foregroundTicker;

  @override
  void onInit() {
    super.onInit();
    _load();
    _startForegroundTicker();
  }

  @override
  void onClose() {
    _foregroundTicker?.cancel();
    super.onClose();
  }

  void _load() {
    try {
      final raw = _storage.read<List>(storageKey) ?? const [];
      final list = raw
          .map((e) {
            try {
              return Reminder.fromJson(
                e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
              );
            } catch (_) {
              return null;
            }
          })
          .whereType<Reminder>()
          .toList();
      reminders.value = list;
    } catch (_) {}
  }

  void _persist() {
    try {
      _storage.write(
        storageKey,
        reminders.map((r) => r.toJson()).toList(),
      );
    } catch (_) {}
  }

  Reminder? byId(String id) {
    for (final r in reminders) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<Reminder> get activeReminders =>
      reminders.where((r) => r.isActive).toList();

  /// Creates the reminder, persists it and schedules the OS notification.
  Future<void> createReminder({
    required String messageId,
    required String messageText,
    required String roomId,
    required String receiverId,
    required String roomUsers,
    required String name,
    required String userNumber,
    required String userProfile,
    required bool isGroup,
    required DateTime remindAt,
  }) async {
    if (remindAt.isBefore(DateTime.now())) {
      Utils.showGetSnackBar('Please pick a future time for the reminder');
      return;
    }
    final reminder = Reminder(
      id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
      messageId: messageId,
      messageText: messageText,
      roomId: roomId,
      receiverId: receiverId,
      roomUsers: roomUsers,
      name: name,
      userNumber: userNumber,
      userProfile: userProfile,
      isGroup: isGroup,
      remindAt: remindAt,
      createdAt: DateTime.now(),
    );
    reminders.insert(0, reminder);
    _persist();
    await NotificationService.scheduleFollowUpReminder(reminder);
    Utils.showGetSnackBar(
      'Reminder set for ${DateFormat('EEE, MMM d · h:mm a').format(remindAt)}',
    );
  }

  Future<void> snooze(String id,
      {Duration duration = const Duration(hours: 1)}) async {
    final r = byId(id);
    if (r == null) return;
    r.snoozeCount += 1;
    r.remindAt = DateTime.now().add(duration);
    r.state = 'snoozed';
    _persist();
    await NotificationService.scheduleFollowUpReminder(r);
  }

  Future<void> markCompleted(String id) async {
    final r = byId(id);
    if (r == null) return;
    r.state = 'completed';
    _persist();
    await NotificationService.cancelFollowUpReminder(r);
  }

  Future<void> dismiss(String id) async {
    final r = byId(id);
    if (r == null) return;
    r.state = 'dismissed';
    _persist();
    await NotificationService.cancelFollowUpReminder(r);
  }

  Future<void> removeReminder(String id) async {
    final r = byId(id);
    reminders.removeWhere((e) => e.id == id);
    _persist();
    if (r != null) {
      await NotificationService.cancelFollowUpReminder(r);
    }
  }

  /// Re-schedules every still-pending reminder. Called once at app start so
  /// reminders survive an app restart / device reboot (same id replaces).
  Future<void> respawnActiveReminders() async {
    for (final r in activeReminders) {
      if (r.remindAt.isAfter(DateTime.now())) {
        await NotificationService.scheduleFollowUpReminder(r);
      }
    }
  }

  /// Opens the chat the reminder belongs to, scrolling to + highlighting the
  /// attached message when possible, and marks the reminder as triggered.
  void openFromNotification(Reminder r, {String? messageId}) {
    if (byId(r.id) == null) return;
    if (r.state != 'dismissed') {
      r.state = 'triggered';
      _persist();
    }
    final targetId = messageId ?? r.messageId;
    Get.to(
      () => ChatScreen(
        name: r.name,
        roomId: r.roomId,
        userNumber: r.userNumber,
        receiverId: r.receiverId,
        isGroup: r.isGroup,
        userProfile: r.userProfile,
        userBio: '',
      ),
      arguments: (targetId.isNotEmpty)
          ? {'isScroll': true, 'messageId': targetId}
          : null,
    );
  }

  /// Background/enabled-permission path when the OS hands a reminder tap or
  /// quick action back to the app.
  Future<void> handleNotificationAction(
    String reminderId,
    String? actionId,
  ) async {
    final r = byId(reminderId);
    if (r == null) return;

    switch (actionId) {
      case 'reply':
        openFromNotification(r);
        _focusDraftForReply(r);
      case 'snooze':
        await snooze(reminderId);
      case 'done':
        await markCompleted(reminderId);
      default:
        openFromNotification(r);
    }
  }

  void _focusDraftForReply(Reminder r) {
    try {
      final chatController = Get.find<ChatController>();
      if (r.messageId.isNotEmpty) {
        chatController.isReplyOnMessage.value = true;
        chatController.repliedOnId = r.messageId;
      }
    } catch (_) {}
  }

  // ── Foreground in-app fallback ─────────────────────────────────────────────

  void _startForegroundTicker() {
    _foregroundTicker = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkForegroundDue(),
    );
  }

  void _checkForegroundDue() {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final now = DateTime.now();
    for (final r in reminders.toList()) {
      if (!r.isActive) continue;
      if (r.remindAt.isAfter(now)) continue;
      _fireForeground(r);
    }
  }

  void _fireForeground(Reminder r) {
    if (byId(r.id) == null) return;
    r.state = 'triggered';
    _persist();
    final preview = r.messageText.trim();
    final text = preview.length > 90 ? '${preview.substring(0, 90)}…' : preview;
    CustomSnackbar.show(
      title:
          'Reminder — follow up ${r.name.isNotEmpty ? 'with ${r.name}' : ''}',
      message: text.isEmpty ? 'Tap your reminder to go to the chat.' : text,
      actionLabel: 'Open',
      onAction: () => openFromNotification(r),
    );
  }

  /// Payload builder for notification taps (kept in one place).
  static String payloadFor(Reminder r) => jsonEncode({
        'type': 'reminder',
        'reminderId': r.id,
        'title': r.messageText,
      });
}
