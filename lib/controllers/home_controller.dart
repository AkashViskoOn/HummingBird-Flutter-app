import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/apis/user_api.dart';

import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:quick_actions/quick_actions.dart';

class HomeController extends GetxController {
  String currentRoom = '';
  bool homeLoading = false;
  bool contactLoading = true;
  RxBool searching = false.obs;
  RxList<Messages> searchedMessages = <Messages>[].obs;
  RxList<Rooms> singleChatsList = <Rooms>[].obs;
  RxList<User> onlineUsers = <User>[].obs;
  RxList<Rooms> groupsList = <Rooms>[].obs;
  RxBool isProcessing = false.obs;
  final RxString selectedFilter = 'All Chats'.obs;
  List<Rooms> data = [];

  // O(1) unread counter — maps roomId → count instead of a flat list with
  // repeated entries that required an O(n) filter on every frame.
  final Map<String, int> _unreadCounts = {};
  final RxInt totalUnreadCount = 0.obs;

  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;

  UserController userController = Get.find();

  @override
  void onInit() {
    singleChatsList = RxList.from(LocalDatabase.getSingleChats());
    groupsList = RxList.from(LocalDatabase.getGroupRooms());
    _initUnreadCounts();
    _searchListener();
    _addQuickActions();
    selectedFilter.listen((_) => update());
    super.onInit();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  void _initUnreadCounts() {
    final saved = LocalDatabase.getUnreadMessages() ?? [];
    for (final roomId in saved) {
      _unreadCounts[roomId] = (_unreadCounts[roomId] ?? 0) + 1;
    }
  }

  /// Wipes this controller's per-account state in memory. Called on logout /
  /// account switch because GetX reuses the already-registered instance (a
  /// plain `Get.put` does not rebuild it), so without this the previous
  /// account's chats and unread counts keep rendering.
  void resetAccountData() {
    singleChatsList.clear();
    groupsList.clear();
    data = [];
    onlineUsers.clear();
    searchedMessages.clear();
    searching.value = false;
    homeLoading = false;
    contactLoading = false;
    currentRoom = '';
    searchController.clear();
    selectedFilter.value = 'All Chats';
    _unreadCounts.clear();
    totalUnreadCount.value = 0;
    LocalDatabase.saveUnreadMessages([]);
  }

  void _addQuickActions() {
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((_) {});
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'action_main',
          localizedTitle: 'Main view',
          icon: 'ic_launcher'),
      const ShortcutItem(
          type: 'action_help', localizedTitle: 'Chat', icon: 'ic_launcher'),
    ]);
  }

  // ── Unread message counters ────────────────────────────────────────────────

  /// O(1) lookup — was previously an O(n) list filter called on every frame.
  String updateUnreadMsgCounter(String roomId) =>
      (_unreadCounts[roomId] ?? 0).toString();

  void makeUnreadReadMessage(String roomId) {
    _unreadCounts.remove(roomId);
    _persistUnreadCounts();
    RoomApi().markRead(roomId);
  }

  void saveUnreadMessages(String roomId, {bool refreshRooms = true}) {
    if (currentRoom != roomId) {
      _unreadCounts[roomId] = (_unreadCounts[roomId] ?? 0) + 1;
      _persistUnreadCounts();
      update(['update-card']);
      update();
      if (refreshRooms) fetchSingleChats();
    }
  }

  void _persistUnreadCounts() {
    final flat = _unreadCounts.entries
        .expand((e) => List.filled(e.value, e.key))
        .toList();
    LocalDatabase.saveUnreadMessages(flat);
    totalUnreadCount.value = _unreadCounts.values.fold(0, (sum, c) => sum + c);
  }

  /// Merges the server-authoritative per-room unread counts (computed in
  /// fetchRooms) into the in-memory map. The server is the source of truth, so
  /// a room it reports as having unread messages raises the local count, and a
  /// room it reports as fully read clears one left over from the Hive cache.
  /// Without the clearing half, messages read on another device (desktop) kept
  /// their old badge after a cold start: the persisted id was restored by
  /// [_initUnreadCounts] and the server's zero was ignored.
  void syncUnreadCountsFromRooms(Iterable<Rooms> rooms) {
    var changed = false;
    for (final room in rooms) {
      final id = room.rId;
      if (id == null) continue;
      final existing = _unreadCounts[id] ?? 0;
      if (room.unreadCount > existing) {
        _unreadCounts[id] = room.unreadCount;
        changed = true;
      } else if (room.unreadCount == 0 && existing > 0) {
        _unreadCounts.remove(id);
        changed = true;
      }
    }
    if (changed) {
      _persistUnreadCounts();
      update(['update-card']);
      update();
    }
  }

  // ── Room lists ─────────────────────────────────────────────────────────────

  void fetchSingleChats() async {
    final res = await RoomApi().fetchAllRooms(0);
    if (res?.status ?? false) {
      singleChatsList.value = res!.rooms ?? [];
      data = res.rooms ?? [];
      LocalDatabase.saveRooms(singleChatsList);
      syncUnreadCountsFromRooms(singleChatsList);
      update(['update-card']);
    } else {}
    homeLoading = false;
    update();
  }

  Future<void> fetchGroupChats() async {
    final res = await RoomApi().fetchAllRooms(1);
    if (res?.status ?? false) {
      groupsList.value = res!.rooms ?? [];
      LocalDatabase.saveRooms(groupsList);
      syncUnreadCountsFromRooms(groupsList);
      update(['update-card']);
    } else {}
    homeLoading = false;
    update();
  }

  // ── User profile ───────────────────────────────────────────────────────────

  Future<String> getUserProfilePic(String roomUsers) async {
    final userId = _getOtherUserId(roomUsers);
    final res = await UserApi().getUserData(userId);
    if (res?.status ?? false) {
      update(['profile-pic']);
      return res!.user?.userImage ?? '';
    }
    return '';
  }

  String _getOtherUserId(String roomUsers) {
    if (roomUsers.isEmpty) return '';
    try {
      final decoded = jsonDecode(roomUsers);
      if (decoded is! List || decoded.isEmpty) return '';
      final ids = decoded.cast<String>();
      final myId = userController.user?.userId ?? '';
      return ids.firstWhere((id) => id != myId, orElse: () => '').toString();
    } catch (_) {
      return '';
    }
  }

  String getUserName(User user) {
    final contacts = LocalDatabase.getAllCustomContacts();
    for (final c in contacts) {
      if (c.id == user.userId) {
        return (c.displayName ?? '').split(' ').first;
      }
    }
    return '';
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  void _searchListener() {
    searchController.addListener(() {
      searching.value = searchController.text.trim().isNotEmpty;
    });
  }

  void searchInChats(String keyword) {
    _searchDebounce?.cancel();
    if (keyword.isEmpty) {
      singleChatsList.value = List.from(data);
      searchedMessages.value = [];
      update(['search-update']);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(keyword);
    });
  }

  void searchInGroups(String keyword) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(keyword);
    });
  }

  void _runSearch(String keyword) {
    final lower = keyword.toLowerCase().trim();

    final filtered = data.where((room) {
      return _getContactName(room).contains(lower);
    }).toList();
    singleChatsList.value = filtered;

    final matched = LocalDatabase.getMessagesByKeyword(lower) ?? [];
    searchedMessages.value = matched;

    update(['search-update']);
  }

  void searchInMessages(String keyword) {
    final matched =
        LocalDatabase.getMessagesByKeyword(keyword.toLowerCase()) ?? [];
    searchedMessages.value = matched;
    update(['search-update']);
  }

  // ── Room-level actions with API + local sync ──────────────────────────────

  static const _archivedKey = 'archived_rooms';
  static const _favoriteRoomsKey = 'favorite_rooms';
  static const _pinnedRoomsKey = 'pinned_rooms';

  List<String> getArchivedRoomIds() {
    final storage = GetStorage();
    final raw = storage.read(_archivedKey) as List<dynamic>?;
    if (raw == null) return [];
    return raw.cast<String>();
  }

  List<String> getFavoriteRoomIds() {
    final storage = GetStorage();
    final raw = storage.read(_favoriteRoomsKey) as List<dynamic>?;
    if (raw == null) return [];
    return raw.cast<String>();
  }

  List<String> getPinnedRoomIds() {
    final storage = GetStorage();
    final raw = storage.read(_pinnedRoomsKey) as List<dynamic>?;
    if (raw == null) return [];
    return raw.cast<String>();
  }

  bool isArchived(String roomId) => getArchivedRoomIds().contains(roomId);
  bool isFavoriteRoom(String roomId) => getFavoriteRoomIds().contains(roomId);
  bool isPinnedRoom(String roomId) => getPinnedRoomIds().contains(roomId);

  Future<void> toggleArchive(String roomId) async {
    final storage = GetStorage();
    final archived = List<String>.from(getArchivedRoomIds());

    if (archived.contains(roomId)) {
      archived.remove(roomId);
    } else {
      archived.add(roomId);
    }
    storage.write(_archivedKey, archived);
    update(['update-card']);
    update();

    try {
      isProcessing.value = true;
      await RoomApi().toggleArchive(roomId);
    } catch (_) {
      // Revert on failure
      if (archived.contains(roomId)) {
        archived.remove(roomId);
      } else {
        archived.add(roomId);
      }
      storage.write(_archivedKey, archived);
    } finally {
      isProcessing.value = false;
      update(['update-card']);
      update();
    }
  }

  Future<void> toggleFavorite(String roomId) async {
    final storage = GetStorage();
    final favorites = List<String>.from(getFavoriteRoomIds());

    if (favorites.contains(roomId)) {
      favorites.remove(roomId);
    } else {
      favorites.add(roomId);
    }
    storage.write(_favoriteRoomsKey, favorites);
    update(['update-card']);
    update();

    try {
      isProcessing.value = true;
      await RoomApi().toggleFavorite(roomId);
    } catch (_) {
      if (favorites.contains(roomId)) {
        favorites.remove(roomId);
      } else {
        favorites.add(roomId);
      }
      storage.write(_favoriteRoomsKey, favorites);
    } finally {
      isProcessing.value = false;
      update(['update-card']);
      update();
    }
  }

  /// Toggles mute for the room and returns the new r_status ('0' = muted,
  /// '1' = unmuted), or null if the server call failed. Updates BOTH the
  /// single-chat and group copies so the respective list tiles and screens
  /// reflect the mute state instantly.
  Future<String?> toggleMute(String roomId) async {
    try {
      isProcessing.value = true;
      final res = await RoomApi().toggleMute(roomId);
      if (res['status'] == true) {
        final room = singleChatsList.firstWhereOrNull((r) => r.rId == roomId) ??
            groupsList.firstWhereOrNull((r) => r.rId == roomId);
        final newStatus =
            (res['r_status'] ?? (room?.rStatus == '1' ? '0' : '1')).toString();
        final single = singleChatsList.firstWhereOrNull((r) => r.rId == roomId);
        if (single != null) single.rStatus = newStatus;
        final group = groupsList.firstWhereOrNull((r) => r.rId == roomId);
        if (group != null) group.rStatus = newStatus;
        LocalDatabase.saveRooms([...singleChatsList, ...groupsList]);
        return newStatus;
      }
    } catch (_) {
    } finally {
      isProcessing.value = false;
      update(['update-card']);
      update();
    }
    return null;
  }

  Future<void> togglePin(String roomId) async {
    final storage = GetStorage();
    final pinned = List<String>.from(getPinnedRoomIds());

    if (pinned.contains(roomId)) {
      pinned.remove(roomId);
    } else {
      pinned.add(roomId);
    }
    storage.write(_pinnedRoomsKey, pinned);
    update(['update-card']);
    update();
  }

  Future<void> markAsUnread(String roomId) async {
    _unreadCounts[roomId] = 1;
    _persistUnreadCounts();
    update(['update-card']);
    update();
    try {
      await RoomApi().markUnread(roomId);
    } catch (_) {
      _unreadCounts.remove(roomId);
      _persistUnreadCounts();
    } finally {
      update(['update-card']);
      update();
    }
  }

  Future<void> deleteRoomAndSync(String roomId) async {
    final removedSingle = singleChatsList.any((r) => r.rId == roomId) ||
        data.any((r) => r.rId == roomId);
    final removedGroup = groupsList.any((r) => r.rId == roomId);
    if (removedSingle || removedGroup) {
      singleChatsList.removeWhere((r) => r.rId == roomId);
      data.removeWhere((r) => r.rId == roomId);
      groupsList.removeWhere((r) => r.rId == roomId);
      if (removedGroup) {
        final contact = Get.find<ContactController>();
        contact.groupsList.removeWhere((r) => r.rId == roomId);
        contact.groupData.removeWhere((r) => r.rId == roomId);
        contact.groupsList.refresh();
      }
      LocalDatabase.deleteRoom(roomId);
      LocalDatabase.deleteRoomMessages(roomId);
      _unreadCounts.remove(roomId);
      _persistUnreadCounts();
      update(['update-card']);
      update();
    }
    try {
      isProcessing.value = true;
      await RoomApi().deleteRoom(roomId);
      LocalDatabase.deleteRoom(roomId);
      LocalDatabase.deleteRoomMessages(roomId);
    } catch (_) {
      if (removedSingle) {
        fetchSingleChats();
      }
      if (removedGroup) {
        fetchGroupChats();
      }
    } finally {
      isProcessing.value = false;
      update(['update-card']);
      update();
    }
  }

  String getContactName(Rooms room) => _getContactName(room);

  String _getContactName(Rooms room) {
    try {
      final ids = jsonDecode(room.rUsers ?? '[]') as List;
      final myId = userController.user?.userId ?? '';
      final otherId = ids
          .firstWhere((id) => id != myId, orElse: () => '')
          .toString()
          .trim();
      if (otherId.isEmpty) return '';
      final contacts = LocalDatabase.getAllCustomContacts();
      final match = contacts.firstWhereOrNull((c) => c.id == otherId);
      return match?.displayName?.toLowerCase() ?? '';
    } catch (_) {
      return '';
    }
  }
}
