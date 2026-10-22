import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/apis/user_api.dart';
import 'package:humming_bird/components/Models/custom_contacts_model.dart';
import 'package:humming_bird/components/Models/reminder_model.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/reminder_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_message_details.dart';
import 'package:humming_bird/pages/Schedule_Pages/scheduled_messages_page.dart';
import 'package:humming_bird/pages/status_updates/updates_screen.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void _handleLocalNotificationTap(NotificationResponse response) {
  try {
    final payload = response.payload;
    final actionId = response.actionId;

    if (payload == null || payload.isEmpty) return;

    final data = jsonDecode(payload) as Map<String, dynamic>;

    if (data['type'] == 'reminder') {
      final reminderId = data['reminderId']?.toString() ?? '';
      if (reminderId.isNotEmpty && Get.isRegistered<ReminderController>()) {
        Get.find<ReminderController>()
            .handleNotificationAction(reminderId, actionId);
      }
      return;
    }

    if (data['type'] == 'call') {
      final sessionId = data['sessionId']?.toString() ?? '';
      if (actionId == 'accept') {
        if (Get.isRegistered<CallController>()) {
          Get.find<CallController>().answerCall(sessionId);
        }
      } else if (actionId == 'reject') {
        if (Get.isRegistered<CallController>()) {
          Get.find<CallController>().rejectCall(sessionId);
        }
      }
      return;
    }

    if (data['type'] == 'status' || data['statusId'] != null) {
      // Story-reply/reaction notifications carry the actor's userId — open
      // the conversation with them directly (falls back to the Status tab).
      final senderId = data['senderId']?.toString();
      if (senderId != null && senderId.isNotEmpty) {
        _openChatWithUserId(senderId);
        return;
      }
      _openStatusUpdates();
      return;
    }

    if (data['type'] == 'moment_published') {
      // "Your moment is now live" push from the backend moment scheduler.
      _openStatusUpdates();
      return;
    }

    if (data['type'] == 'schedule') {
      _openScheduledMessages(data['scheduleId']?.toString());
      return;
    }

    final isGroup = data['isGroup'].toString() == '1';
    Get.to(() => ChatScreen(
          name: isGroup
              ? (data['groupName']?.toString() ?? 'Group')
              : (data['senderName']?.toString().isNotEmpty ?? false)
                  ? data['senderName'].toString()
                  : data['senderNumber']?.toString() ?? '',
          roomId: data['roomId']?.toString() ?? '',
          userNumber: data['senderNumber']?.toString() ?? '',
          receiverId: data['senderId']?.toString() ?? '',
          isGroup: isGroup,
          userProfile: data['profile_pic']?.toString() ?? '',
          userBio: data['bio']?.toString() ?? '',
        ));
  } catch (_) {}
}

void _openStatusUpdates() {
  try {
    if (Get.isRegistered<StatusController>()) {
      Get.find<StatusController>().refreshAll();
    }
  } catch (_) {}
  Get.to(() => const UpdatesScreen());
}

void _openScheduledMessages([String? scheduleId]) {
  Messages? target;
  try {
    if (Get.isRegistered<BirdController>()) {
      final bird = Get.find<BirdController>();
      bird.getScheduledMessages();
      if (scheduleId != null && scheduleId.isNotEmpty) {
        for (final m in bird.allScheduledMessages) {
          if (m.mId == scheduleId || m.mUniqueId == scheduleId) {
            target = m;
            break;
          }
        }
      }
    }
  } catch (_) {}
  final found = target;
  if (found != null) {
    Get.to(() => ScheduledMessageDetailsScreen(message: found));
  } else {
    Get.to(() => const ScheduledMessagesPage());
  }
}

/// Opens (or creates) the 1:1 conversation with [userId] — used for
/// status reply/reaction notifications so the user lands in the chat
/// context of whoever interacted with their story.
void _openChatWithUserId(String userId) {
  try {
    final home = Get.find<HomeController>();
    final myId = Get.find<UserController>().user?.userId?.toString();
    for (final r in home.singleChatsList) {
      try {
        final ids = (jsonDecode(r.rUsers ?? '[]') as List)
            .map((e) => e.toString())
            .toList();
        if (ids.contains(myId) && ids.contains(userId)) {
          final data = Get.find<ContactController>().getContactData(r);
          Get.to(() => ChatScreen(
                name: data.$1.isNotEmpty ? data.$1 : (r.rName ?? 'User'),
                roomId: r.rId ?? '',
                userNumber: data.$3,
                receiverId: data.$2.isNotEmpty ? data.$2 : userId,
                isGroup: false,
                userProfile: r.rAvatar ?? '',
                userBio: data.$4,
              ));
          return;
        }
      } catch (_) {}
    }
  } catch (_) {}
  _openStatusUpdates();
}

class NotificationService {
  /// Resolved lazily (never in the constructor) so building a
  /// [NotificationService] can't crash during app startup before
  /// [HomeController] is registered.
  HomeController get homeController => Get.find<HomeController>();
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterNotification =
      FlutterLocalNotificationsPlugin();
  static final Map<String, DateTime> _recentNotifications = {};
  static bool _localInitialized = false;
  static bool _started = false;
  static bool _notificationsPermissionRequested = false;

  /// Starts FCM token registration + permission flow exactly once per app
  /// run. Fired after login (MainHummingScreen) and by the contacts flow so a
  /// token is always registered even if the contacts permission was denied.
  Future<void> startIfNeeded() async {
    if (_started) return;
    _started = true;
    try {
      await initNotification();
    } catch (_) {
      _started = false;
    }
  }

  // Phase 4 - Smart Notification Grouping
  static final Map<String, _GroupedNotification> _groupedNotifications = {};
  static Timer? _groupFlushTimer;

  FlutterLocalNotificationsPlugin flutterNotification = _flutterNotification;
  List<CustomContactsModel> contacts = [];

  Future<void> initNotification() async {
    try {
      final fcmToken = await firebaseMessaging.getToken();
      if (fcmToken != null) {
        UserApi().updateUser({'fcm_token': fcmToken});
      }
      // Keep the backend token in sync when Firebase rotates the device token.
      firebaseMessaging.onTokenRefresh.listen((token) {
        try {
          if (token.isNotEmpty) {
            UserApi().updateUser({'fcm_token': token});
          }
        } catch (_) {}
      });
    } catch (_) {}
    try {
      contacts = LocalDatabase.getAllCustomContacts();
    } catch (_) {
      contacts = [];
    }
    getPermission();
  }

  void getPermission() async {
    try {
      await ensureLocalNotificationsInitialized();
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging.onMessage.listen((event) {
          try {
            if (event.data['type'] == 'status' ||
                event.data['statusId'] != null) {
              return;
            }
            if (event.data['title'] != null && event.data['body'] != null) {
              homeController.saveUnreadMessages(event.data['roomId']);
              if (event.data['roomId'] != homeController.currentRoom) {
                initializeService(event);
                CustomContactsModel? contact = contacts
                    .firstWhereOrNull((e) => e.id == event.data['senderId']);

                if (event.data['isGroup'] == '0') {
                  showLocalMessageNotification(
                    title: contact?.displayName ?? event.data['senderNumber'],
                    body: notificationBody(event.data['body'] ?? ''),
                    id: event.hashCode,
                    dedupeKey: _dedupeKeyFromData(event.data),
                    payload: event.data,
                  );
                } else {
                  showLocalMessageNotification(
                    title: event.data['groupName'],
                    body: notificationBody(event.data['body'] ?? ''),
                    id: event.hashCode,
                    dedupeKey: _dedupeKeyFromData(event.data),
                    payload: event.data,
                  );
                }
              }
            }
          } catch (_) {}
        });

        FirebaseMessaging.onMessageOpenedApp.listen(
          (event) => handleForegroundNotificationTap(event),
        );

        try {
          RemoteMessage? initialMessage =
              await FirebaseMessaging.instance.getInitialMessage();
          if (initialMessage != null) {
            handleForegroundNotificationTap(initialMessage);
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  void initializeService(RemoteMessage event) {
    try {
      ensureLocalNotificationsInitialized();
    } catch (_) {}
  }

  static Future<void> ensureLocalNotificationsInitialized() async {
    if (_localInitialized) return;
    try {
      var androidInitializeSettings =
          const AndroidInitializationSettings('ic_stat_hummingbird');
      var initializationSettings = InitializationSettings(
        android: androidInitializeSettings,
      );
      await _flutterNotification.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );
      await _initTimezone();
      _localInitialized = true;
      // Android 13+ shows notifications only after the runtime permission is
      // granted. Firebase's requestPermission() is iOS-only (a no-op here), so
      // without this explicit local-notifications permission request the app
      // silently drops every notification after upgrading to targetSdk 33+.
      // Request exactly once per app run to avoid re-prompting on every show.
      if (_notificationsPermissionRequested) return;
      _notificationsPermissionRequested = true;
      try {
        final android =
            _flutterNotification.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      } catch (_) {}
    } catch (_) {}
  }

  /// Initializes the tz database + the device's local timezone. Required for
  /// [FlutterLocalNotificationsPlugin.zonedSchedule] (follow-up reminders).
  static Future<void> _initTimezone() async {
    try {
      tz_data.initializeTimeZones();
      String name;
      try {
        name = await FlutterTimezone.getLocalTimezone();
      } catch (_) {
        name = 'UTC';
      }
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}
  }

  static tz.TZDateTime _tzNow() {
    try {
      return tz.TZDateTime.from(DateTime.now(), tz.local);
    } catch (_) {
      return tz.TZDateTime.now(tz.UTC);
    }
  }

  static String notificationBody(String value) {
    try {
      final decrypted = EncryptionHelper().decryptMessage(value);
      final text = decrypted.trim();
      if (text.isNotEmpty) {
        // Link messages notify as a short 🔗 domain label instead of a huge,
        // noisy URL (same style as the in-app/banner path).
        if (LinkPreviewService.isLink(text)) {
          return LinkPreviewService.linkSummary(text);
        }
        return decrypted;
      }
      return value;
    } catch (_) {
      return value;
    }
  }

  static String _dedupeKeyFromData(Map<String, dynamic> data) {
    final roomId = data['roomId']?.toString() ?? '';
    final messageId = data['messageId']?.toString() ??
        data['m_id']?.toString() ??
        data['timestamp']?.toString() ??
        '';
    return '$roomId:$messageId';
  }

  static bool _shouldSkipNotification(String key) {
    if (key == ':') return false;
    final now = DateTime.now();
    _recentNotifications.removeWhere(
      (_, time) => now.difference(time).inSeconds > 12,
    );
    if (_recentNotifications.containsKey(key)) return true;
    _recentNotifications[key] = now;
    return false;
  }

  static Future<void> showLocalMessageNotification({
    int id = 0,
    required String title,
    required String body,
    required String dedupeKey,
    Map<String, dynamic>? payload,
  }) async {
    try {
      if (_shouldSkipNotification(dedupeKey)) return;
      await ensureLocalNotificationsInitialized();

      final senderKey = payload?['senderId']?.toString() ?? title;
      final roomId = payload?['roomId']?.toString() ?? '';
      if (_groupedNotifications.containsKey(senderKey)) {
        final existing = _groupedNotifications[senderKey]!;
        existing.count++;
        existing.lastBody = body;
        existing.lastTitle = title;
        existing.lastPayload = payload;
        existing.lastRoomId = roomId;
        _scheduleGroupFlush();
        return;
      }

      final grouped = _GroupedNotification(
        count: 1,
        lastTitle: title,
        lastBody: body,
        lastPayload: payload,
        lastRoomId: roomId,
      );
      _groupedNotifications[senderKey] = grouped;
      _scheduleGroupFlush();

      await _showSingleNotification(id, title, body, payload);
    } catch (_) {}
  }

  static void _scheduleGroupFlush() {
    _groupFlushTimer?.cancel();
    _groupFlushTimer = Timer(const Duration(seconds: 3), () {
      _flushGroupedNotifications();
    });
  }

  static Future<void> _flushGroupedNotifications() async {
    for (final entry in _groupedNotifications.entries) {
      final grouped = entry.value;
      if (grouped.count <= 1) continue;
      final displayTitle = grouped.count == 2
          ? '2 messages from ${grouped.lastTitle}'
          : '${grouped.count} messages from ${grouped.lastTitle}';
      await _showSingleNotification(
        grouped.lastRoomId.hashCode + grouped.count,
        displayTitle,
        grouped.lastBody,
        grouped.lastPayload,
      );
    }
    _groupedNotifications.clear();
  }

  static Future<void> _showSingleNotification(
    int id,
    String title,
    String body,
    Map<String, dynamic>? payload,
  ) async {
    // Notification Settings: sound / vibration (channel id varies so Android
    // picks up toggled settings without reinstall)
    final storage = GetStorage();
    final sound = storage.read('notif_sound') ?? true;
    final vibration = storage.read('notif_vibration') ?? true;
    var androidNotificationDetails = AndroidNotificationDetails(
      'msg2_${sound ? 'sound' : 'silent'}_${vibration ? 'vib' : 'novib'}',
      'Messages',
      priority: Priority.max,
      importance: Importance.max,
      playSound: sound,
      enableVibration: vibration,
      largeIcon: const DrawableResourceAndroidBitmap('hummingbird_logo'),
    );
    var notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await _flutterNotification.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload == null ? null : jsonEncode(payload),
    );
  }

  static void cancelGroupedNotifications() {
    _groupFlushTimer?.cancel();
    _groupedNotifications.clear();
  }

  // ── Call Notifications ────────────────────────────────────────────────────

  // ── Schedule & Status Notifications ────────────────────────────────────────

  static Future<void> showScheduleReminderNotification({
    required String title,
    required String body,
    required String scheduleId,
  }) async {
    try {
      if (GetStorage().read('notif_schedule_show') == false) return;
      await ensureLocalNotificationsInitialized();
      final payload = jsonEncode({
        'type': 'schedule',
        'scheduleId': scheduleId,
        'title': title,
      });
      final androidDetails = const AndroidNotificationDetails(
        'schedule_channel_v2',
        'Schedules',
        channelDescription: 'Schedule reminders and notifications',
        priority: Priority.high,
        importance: Importance.high,
        largeIcon: DrawableResourceAndroidBitmap('hummingbird_logo'),
      );
      await _flutterNotification.show(
        scheduleId.hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> showStatusNotification({
    required String userName,
    required String statusId,
  }) async {
    try {
      await ensureLocalNotificationsInitialized();
      final payload = jsonEncode({
        'type': 'status',
        'statusId': statusId,
        'userName': userName,
      });
      final androidDetails = const AndroidNotificationDetails(
        'status_channel_v2',
        'Status Updates',
        channelDescription: 'Status update notifications',
        priority: Priority.defaultPriority,
        importance: Importance.defaultImportance,
        largeIcon: DrawableResourceAndroidBitmap('hummingbird_logo'),
      );
      await _flutterNotification.show(
        statusId.hashCode,
        'New Status Update',
        '$userName posted a new status',
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> cancelFollowUpReminder(Reminder reminder) async {
    try {
      await _flutterNotification.cancel(reminder.reminderNotificationId);
    } catch (_) {}
  }

  /// Schedules a one-shot follow-up reminder notification at [Reminder.remindAt]
  /// with quick actions (Reply / Snooze / Done / Dismiss). Re-scheduling with
  /// the same reminder replaces the existing alert.
  static Future<void> scheduleFollowUpReminder(Reminder reminder) async {
    try {
      await ensureLocalNotificationsInitialized();
      final at = _tzNow().add(reminder.remindAt.difference(DateTime.now()));
      if (at.isBefore(_tzNow())) return;

      final preview = reminder.messageText.trim();
      final body = preview.length > 70
          ? '${preview.substring(0, 70)}…'
          : (preview.isEmpty ? 'Tap to open the chat' : preview);

      final androidDetails = const AndroidNotificationDetails(
        'reminder_channel_v2',
        'Reminders',
        channelDescription: 'Follow-up reminders',
        priority: Priority.high,
        importance: Importance.high,
        largeIcon: DrawableResourceAndroidBitmap('hummingbird_logo'),
        actions: [
          AndroidNotificationAction('reply', 'Reply', showsUserInterface: true),
          AndroidNotificationAction('snooze', 'Snooze'),
          AndroidNotificationAction('done', 'Done'),
          AndroidNotificationAction('dismiss', 'Dismiss'),
        ],
      );

      await _flutterNotification.zonedSchedule(
        reminder.reminderNotificationId,
        'Follow up${reminder.name.isNotEmpty ? ' with ${reminder.name}' : ''}',
        body,
        at,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payloadForReminder(reminder),
      );
    } catch (_) {}
  }

  static String payloadForReminder(Reminder reminder) =>
      ReminderController.payloadFor(reminder);

  static Future<void> showReminderNotification({
    required String title,
    required String body,
    required String reminderId,
  }) async {
    try {
      await ensureLocalNotificationsInitialized();
      final payload = jsonEncode({
        'type': 'reminder',
        'reminderId': reminderId,
        'title': title,
      });
      final androidDetails = const AndroidNotificationDetails(
        'reminder_channel_v2',
        'Reminders',
        channelDescription: 'General reminders',
        priority: Priority.high,
        importance: Importance.high,
        largeIcon: DrawableResourceAndroidBitmap('hummingbird_logo'),
      );
      await _flutterNotification.show(
        reminderId.hashCode,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> showIncomingCallNotification({
    required String callerName,
    required String sessionId,
    required String callerId,
    required String callType,
  }) async {
    try {
      await ensureLocalNotificationsInitialized();

      final payload = jsonEncode({
        'type': 'call',
        'sessionId': sessionId,
        'callerId': callerId,
        'callerName': callerName,
        'callType': callType,
      });

      // When the app is already ringing in the foreground it plays the
      // looping custom ringtone (`sounds/ringtone.wav`). The heads-up call
      // notification must stay silent so the Android default "ring" never
      // plays on top of it. In the background the notification itself rings
      // with the app's own ringtone (raw resource) instead of the system one.
      final isForeground =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

      final androidDetails = AndroidNotificationDetails(
        'call_channel_v2',
        'Calls',
        channelDescription: 'Incoming call notifications',
        priority: Priority.max,
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('humming_ringtone'),
        playSound: !isForeground,
        enableVibration: !isForeground,
        fullScreenIntent: true,
        largeIcon: const DrawableResourceAndroidBitmap('hummingbird_logo'),
        actions: [
          AndroidNotificationAction('accept', 'Accept',
              showsUserInterface: true),
          AndroidNotificationAction('reject', 'Reject'),
        ],
      );

      await _flutterNotification.show(
        sessionId.hashCode,
        'Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call',
        'From $callerName',
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> showMissedCallNotification({
    required String callerName,
    required String callerId,
    String? callType,
  }) async {
    try {
      await ensureLocalNotificationsInitialized();

      final payload = jsonEncode({
        'type': 'missed_call',
        'callerId': callerId,
        'callerName': callerName,
      });

      final androidDetails = const AndroidNotificationDetails(
        'missed_calls_channel_v2',
        'Missed Calls',
        channelDescription: 'Missed call notifications',
        priority: Priority.high,
        importance: Importance.high,
        largeIcon: DrawableResourceAndroidBitmap('hummingbird_logo'),
      );

      await _flutterNotification.show(
        DateTime.now().millisecondsSinceEpoch.hashCode,
        'Missed Call',
        'Missed ${callType == 'video' ? 'video' : 'audio'} call from $callerName',
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (_) {}
  }

  void handleForegroundNotificationTap(RemoteMessage event) {
    try {
      if (event.data['type'] == 'status' || event.data['statusId'] != null) {
        _openStatusUpdates();
        return;
      }
      if (event.data['type'] == 'moment_published') {
        _openStatusUpdates();
        return;
      }
      if (event.data['type'] == 'schedule') {
        _openScheduledMessages(event.data['scheduleId']?.toString());
        return;
      }
      String roomId = event.data['roomId'] ?? '';
      if (roomId.isEmpty) return;
      CustomContactsModel? contact =
          contacts.firstWhereOrNull((e) => e.id == event.data['senderId']);
      Get.to(() => ChatScreen(
            name: contact?.displayName ?? event.data['senderNumber'] ?? '',
            roomId: roomId,
            userNumber: event.data['senderNumber'] ?? '',
            receiverId: event.data['senderId']?.toString() ?? '',
            isGroup: event.data['isGroup'] == '1' ? true : false,
            userProfile: event.data['profile_pic'] ?? '',
            userBio: event.data['bio'] ?? '',
          ));
    } catch (_) {}
  }
}

class _GroupedNotification {
  int count;
  String lastTitle;
  String lastBody;
  Map<String, dynamic>? lastPayload;
  String lastRoomId;

  _GroupedNotification({
    required this.count,
    required this.lastTitle,
    required this.lastBody,
    this.lastPayload,
    this.lastRoomId = '',
  });
}
