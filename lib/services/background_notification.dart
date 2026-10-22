import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:humming_bird/components/Models/custom_contacts_model.dart';
import 'package:humming_bird/components/Models/media_model.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';

@pragma('vm:entry-point')
void onBackgroundNotificationTap(NotificationResponse message) async {
  var data = jsonDecode(message.payload ?? '{}');
  if (data != null) {
    Get.to(() => ChatScreen(
          name: data['senderNumber'],
          roomId: data['roomId'],
          userNumber: data['senderNumber'],
          receiverId: data['senderId']?.toString() ?? '',
          isGroup: data['isGroup'] == '1' ? true : false,
          userProfile: data['profile_pic'],
          userBio: data['bio'],
        ));
  }
}

class BackgroundNotificationService {
  final FlutterLocalNotificationsPlugin _flutterNotification =
      FlutterLocalNotificationsPlugin();
  List<CustomContactsModel> contacts = [];

  void initNotification(RemoteMessage event) async {
    try {
      await Hive.initFlutter();
    } catch (_) {}

    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserAdapter());
        Hive.registerAdapter(CustomContactsModelAdapter());
        Hive.registerAdapter(RoomsAdapter());
        Hive.registerAdapter(MessagesAdapter());
        Hive.registerAdapter(MediaModelAdapter());
      }
    } catch (_) {}

    try {
      await LocalDatabase.openLocalDb();
    } catch (_) {}

    try {
      LocalDatabase.saveBackgroundUnreadMessages(event.data['roomId'] ?? '');
    } catch (_) {}

    try {
      contacts = LocalDatabase.getAllCustomContacts();
    } catch (_) {}

    try {
      CustomContactsModel? contact;
      try {
        contact =
            contacts.firstWhereOrNull((e) => e.id == event.data['senderId']);
      } catch (_) {}

      await initializeService(
          contact?.displayName ?? event.data['senderNumber'] ?? '',
          event.data['roomId'] ?? '',
          event.data['senderNumber'] ?? '',
          event.data['isGroup'] == '1' ? true : false,
          event.data['profile_pic'] ?? '',
          event.data['bio'] ?? '');

      if (event.data['isGroup'] == '0') {
        sendNotification(
            title: contact?.displayName ?? event.data['senderNumber'] ?? '',
            body: _notificationBody(event.data['body'] ?? ''),
            id: event.hashCode,
            data: event.data);
      } else {
        sendNotification(
            title: event.data['groupName'] ?? '',
            body: _notificationBody(event.data['body'] ?? ''),
            id: event.hashCode,
            data: event.data);
      }
    } catch (_) {}
  }

  String _notificationBody(String value) {
    try {
      final decrypted = EncryptionHelper().decryptMessage(value);
      return decrypted.trim().isNotEmpty ? decrypted : value;
    } catch (_) {
      return value;
    }
  }

  Future<void> initializeService(String userName, String roomId,
      String userNumber, bool isGroup, profile, bio) async {
    try {
      var androidInitializeSettings =
          const AndroidInitializationSettings('ic_stat_hummingbird');
      var initializationSettings = InitializationSettings(
        android: androidInitializeSettings,
      );
      await _flutterNotification.initialize(initializationSettings,
          onDidReceiveBackgroundNotificationResponse:
              onBackgroundNotificationTap);
    } catch (_) {}
  }

  void sendNotification(
      {int id = 0,
      required String title,
      required String body,
      required Map<String, dynamic> data}) {
    // Respect Notification Settings sound/vibration toggles (dynamic channel)
    final bool sound = GetStorage().read('notif_sound') ?? true;
    final bool vibration = GetStorage().read('notif_vibration') ?? true;
    var androidNotificationDetails = AndroidNotificationDetails(
      'bg2_${sound ? 'sound' : 'silent'}_${vibration ? 'vib' : 'novib'}',
      'message',
      priority: Priority.max,
      importance: Importance.max,
      playSound: sound,
      enableVibration: vibration,
      largeIcon: const DrawableResourceAndroidBitmap('hummingbird_logo'),
    );
    var notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    _flutterNotification.show(id, title, body, notificationDetails,
        payload: jsonEncode(data));
  }
}
