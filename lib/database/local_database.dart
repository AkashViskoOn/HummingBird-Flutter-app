import 'package:hive/hive.dart';
import 'package:humming_bird/components/Models/custom_contacts_model.dart';
import 'package:humming_bird/components/Models/media_model.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/res/constants.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;

  static Box<User>? userBox;
  static Box<User>? contactBox;
  static Box<CustomContactsModel>? customContactsBox;
  static Box<Rooms>? roomsBox;
  static Box<Messages>? messagesBox;
  static Box<MediaModel>? mediaBox;
  static Box<List<String>>? roomsNewMessagesBox;
  static Box<dynamic>? statusBox;
  static Box<String>? linkCacheBox;

  // In-memory caches to avoid repeated Hive scans on hot paths.
  static List<CustomContactsModel>? _customContactsCache;

  LocalDatabase._internal();

  static Future<void> openLocalDb() async {
    try {
      userBox = await Hive.openBox(
        Constants.USER_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      contactBox = await Hive.openBox(
        Constants.CONTACTS_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      customContactsBox = await Hive.openBox(
        Constants.CUSTOM_CONTACTS_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      roomsBox = await Hive.openBox(
        Constants.ROOMS_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      messagesBox = await Hive.openBox(
        Constants.MESSAGES_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      mediaBox = await Hive.openBox(
        Constants.MEDIA_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      roomsNewMessagesBox = await Hive.openBox(
        Constants.ROOMS_NEW_MSG_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      statusBox = await Hive.openBox(
        Constants.STATUS_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 10,
      );
    } catch (_) {}
    try {
      linkCacheBox = await Hive.openBox(
        Constants.LINK_CACHE_BOX,
        compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
      );
    } catch (_) {}
  }

  static Future<void> closeLocalDb() async {
    await userBox?.close();
    await contactBox?.close();
    await customContactsBox?.close();
    await roomsBox?.close();
    await messagesBox?.close();
    await mediaBox?.close();
    await roomsNewMessagesBox?.close();
    await statusBox?.close();
    await linkCacheBox?.close();
  }

  static Future<void> deleteLocalDatabase() async {
    await userBox?.clear();
    await contactBox?.clear();
    await customContactsBox?.clear();
    await roomsBox?.clear();
    await messagesBox?.clear();
    await mediaBox?.clear();
    await roomsNewMessagesBox?.clear();
    await statusBox?.clear();
    await linkCacheBox?.clear();
    _customContactsCache = null;
  }

  // ── Rooms ──────────────────────────────────────────────────────────────────

  static void saveRooms(List<Rooms> rooms) async {
    await Future.wait(rooms.map((room) => roomsBox!.put(room.rId, room)));
    // No need to call getRooms() here — callers manage their own lists.
  }

  static List<Rooms> getRooms() => _sortedRooms(roomsBox!.values.toList());

  static List<Rooms> getSingleChats() =>
      _sortedRooms(roomsBox!.values.where((r) => r.rType == '0').toList());

  static List<Rooms> getGroupRooms() =>
      _sortedRooms(roomsBox!.values.where((r) => r.rType == '1').toList());

  /// Shared comparator — most recent last-message first.
  static List<Rooms> _sortedRooms(List<Rooms> rooms) {
    rooms.sort((a, b) {
      final aTime = a.rLastMessage?.mCreatedAt;
      final bTime = b.rLastMessage?.mCreatedAt;
      if (aTime != null && bTime != null) return bTime.compareTo(aTime);
      if (aTime != null) return -1;
      if (bTime != null) return 1;
      return 0;
    });
    return rooms;
  }

  static void deleteRoom(String roomId) => roomsBox?.delete(roomId);

  // ── Messages ───────────────────────────────────────────────────────────────

  static void saveMessage(List<Messages> messages) async {
    await Future.wait(messages.map((m) async {
      final id = m.mId;
      if (id != null) {
        // Never persist an empty `m_message` over an existing one — status
        // socket events carry content-less payloads and were wiping the text.
        if (m.mMessage == null || m.mMessage!.trim().isEmpty) {
          final existing = messagesBox!.get(id);
          final existingText = existing?.mMessage;
          if (existingText != null && existingText.trim().isNotEmpty) {
            m.mMessage = existingText;
          }
        }
        await messagesBox!.put(id, m);
      }
    }));
  }

  static List<Messages> getMessages(String roomId) {
    final list = messagesBox!.values.where((m) => m.mRoomId == roomId).toList();
    // Reverse in-place — avoids creating an intermediate Iterable.
    return list.reversed.toList();
  }

  static List<Messages> getAllMessages() =>
      messagesBox!.values.toList().reversed.toList();

  static Messages? getSingleMessages(String messageId) =>
      messagesBox!.get(messageId);

  static List<Messages>? getMessagesByKeyword(String keyword) {
    final lower = keyword.toLowerCase();
    return messagesBox!.values
        .where((m) => m.mMessage?.toLowerCase().contains(lower) ?? false)
        .toList();
  }

  static List<Messages>? getGroupMsgByKeyword(String keyword) =>
      getMessagesByKeyword(keyword);

  static void deleteMessages(List<String> messageIds) {
    for (final id in messageIds) {
      messagesBox?.delete(id);
    }
  }

  static void deleteRoomMessages(String roomId) {
    final ids = messagesBox!.values
        .where((m) => m.mRoomId == roomId)
        .map((m) => m.mId)
        .whereType<String>()
        .toList();
    for (final id in ids) {
      messagesBox?.delete(id);
    }
  }

  // ── Media ──────────────────────────────────────────────────────────────────

  static void saveMedia(List<MediaModel> medias) async {
    await Future.wait(medias.map((m) => mediaBox!.put(m.id, m)));
  }

  /// O(1) lookup — media is stored with its ID as the Hive key.
  static MediaModel? getMedia(String mediaId) => mediaBox?.get(mediaId);

  static void deleteMedia(List<String> mediaIds) {
    for (final id in mediaIds) {
      mediaBox?.delete(id);
    }
  }

  static List<MediaModel?> getRoomMedia(String roomId) {
    try {
      return mediaBox!.values.where((m) => m.mediaRoomId == roomId).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  static Future<void> saveUser(User user) async =>
      userBox?.put(user.userId, user);

  static User? getUser(String userId) => userBox?.get(userId);

  static Future<void> saveHummingContacts(List<User> contacts) async {
    await Future.wait(contacts.map((c) => contactBox!.put(c.userId, c)));
  }

  static List<User>? getHummingContacts() => contactBox?.values.toList();

  // ── Custom contacts ────────────────────────────────────────────────────────

  static Future<void> saveCustomContacts(
      CustomContactsModel customContact) async {
    await customContactsBox!.put(customContact.id, customContact);
    _customContactsCache = null; // Invalidate cache on write.
  }

  static CustomContactsModel? getCustomContacts(String contactId) =>
      customContactsBox!.get(contactId);

  /// Cached read — the contacts list rarely changes; avoid rebuilding on every
  /// call from hot paths such as chat-card and search.
  static List<CustomContactsModel> getAllCustomContacts() {
    _customContactsCache ??= customContactsBox!.values.toList();
    return _customContactsCache!;
  }

  /// Call this whenever contacts are mutated externally so the cache stays
  /// coherent.
  static void invalidateContactsCache() => _customContactsCache = null;

  // ── Unread messages ────────────────────────────────────────────────────────

  static Future<void> saveUnreadMessages(List<String> messages) async =>
      roomsNewMessagesBox!.put('unread-messages', messages);

  static List<String>? getUnreadMessages() =>
      roomsNewMessagesBox!.get('unread-messages')?.toList();

  static Future<void> saveBackgroundUnreadMessages(String id) async {
    final saved =
        roomsNewMessagesBox!.get('unread-messages')?.toList() ?? <String>[];
    saved.add(id);
    await roomsNewMessagesBox!.put('unread-messages', saved);
  }

  // ── Link preview cache ────────────────────────────────────────────────────

  static void saveLinkPreview(String url, String json) async {
    try {
      linkCacheBox?.put(url, json);
    } catch (_) {}
  }

  static String? getLinkPreview(String url) {
    try {
      return linkCacheBox?.get(url);
    } catch (_) {
      return null;
    }
  }
}
