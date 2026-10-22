import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/apis/message_api.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/apis/user_api.dart';
import 'package:humming_bird/components/Models/composer_media_item.dart';
import 'package:humming_bird/components/Models/custom_contacts_model.dart';
import 'package:humming_bird/components/Models/media_model.dart';
import 'package:humming_bird/components/Models/message_model.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/pages/chats/chat_screens/forward_message_screen.dart';
import 'package:humming_bird/components/schedule/schedule_confirmation_sheet.dart';
import 'package:humming_bird/components/chat_ui/record_audio_anim.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/main_humming_screen.dart';
import 'package:dio/dio.dart' as Dio;
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/document_preview_screen.dart';
import 'package:humming_bird/pages/chats/chat_screens/image_preview_screen.dart';
import 'package:humming_bird/pages/chats/chat_screens/media_composer_screen.dart';
import 'package:humming_bird/pages/chats/chat_screens/video_preview_screen.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/services/audio_service.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:humming_bird/services/group_system_message_service.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:humming_bird/services/notification_service.dart';
import 'package:humming_bird/services/offline_queue_service.dart';
import 'package:humming_bird/services/text_generation_service.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:just_audio/just_audio.dart' as justAudio;
import 'package:vibration/vibration.dart';

/// Reactive socket connection state derived exclusively from the existing
/// socket_io_client lifecycle callbacks in [ChatController.connectToSocket].
enum SocketConnectionState { connected, connecting, reconnecting, disconnected }

class ChatController extends GetxController {
  RxBool showLoading = false.obs;
  RxBool uploadingFile = false.obs;
  RxBool loadingSingleChats = false.obs;
  RxString pickedMediaPath = ''.obs;
  RxString selectedRoom = 'new'.obs;
  RxString selectedContactId = '0'.obs;
  RxString isScheduledMessage = '0'.obs;
  RxDouble audioIconSize = 35.0.sp.obs;
  File? file;
  MessageModel? allMessage;
  RxList<Messages> messages = <Messages>[].obs;

  /// Chat rooms that are currently open on a ChatScreen. Used instead of the
  /// global [selectedRoom] (which keeps the last-opened value even after a
  /// chat is closed) to decide whether an incoming socket message belongs to
  /// the conversation the user is actually looking at.
  final List<String> _activeRoomStack = [];

  /// Session-scoped dedupe for incoming socket messages (roomId|messageId).
  /// Guards against double-processing during reconnects / duplicate deliveries
  /// so unread counters and notifications are not duplicated.
  final Set<String> _processedIncomingIds = {};
  static const int _processedIdsCap = 5000;

  void openChatRoom(String roomId) {
    if (roomId.isEmpty) return;
    if (_activeRoomStack.contains(roomId)) _activeRoomStack.remove(roomId);
    _activeRoomStack.add(roomId);
    selectedRoom.value = roomId;
  }

  void closeChatRoom(String roomId) {
    _activeRoomStack.remove(roomId);
    if (selectedRoom.value == roomId) {
      selectedRoom.value =
          _activeRoomStack.isEmpty ? 'new' : _activeRoomStack.last;
    }
  }

  /// Wipes the previous account's chat state from memory on logout / account
  /// switch. The controller instance survives re-login (GetX reuses it), so
  /// without this the old account's messages and search state keep showing.
  void resetAccountData() {
    messages.clear();
    selectedRoom.value = 'new';
    selectedContactId.value = '0';
    selectedRoomList.clear();
    youMessages.clear();
    roomsNewMessagesMap.clear();
    messageReactions.clear();
    pinnedMessages.clear();
    starredMessages.clear();
    searchResults.clear();
    searchQuery.value = '';
    isSearching.value = false;
    showPinnedBar.value = false;
    showEmojiPicker.value = false;
    isReplyOnMessage.value = false;
    repliedMessage = null;
    repliedOnId = null;
    editingMessage = false;
    editingMessageId = null;
    isMultiSelectMode.value = false;
    receiverId = '';
    currentRoom = '';
    aiReplySuggestions.clear();
    messageCategories.clear();
    messageSentiments.clear();
    messageTranslations.clear();
    spamMessages.clear();
    showLoading.value = false;
    uploadingFile.value = false;
    composerItems.clear();
    composerSending.value = false;
    _composerSending = false;
    scrollToBottomUnreadCount.value = 0;
    showScrollToBottom.value = false;
    _manualScrollSinceJump = false;
    _jumpToLatestInFlight = false;
    _viewportExtent = 0;
  }

  /// True when [roomId] is the conversation currently on screen.
  bool _isActiveChatRoom(String? roomId) {
    if (roomId == null || roomId.isEmpty) return false;
    return roomId == selectedRoom.value &&
        (_activeRoomStack.isNotEmpty ? _activeRoomStack.last == roomId : true);
  }

  /// Keeps the in-memory thread list ordered newest-first by send time so
  /// late-arriving / in-flight messages never end up out of order.
  void _resortMessages() {
    messages.sort((a, b) => b.sentEpochSeconds.compareTo(a.sentEpochSeconds));
  }

  /// Marks a received socket message as already processed for the session.
  /// Returns true when it is a duplicate that should be ignored.
  bool _markIncomingProcessed(String roomId, String messageId) {
    if (roomId.isEmpty || messageId.isEmpty) return false;
    if (_processedIncomingIds.length >= _processedIdsCap) {
      _processedIncomingIds.clear();
    }
    return !_processedIncomingIds.add('$roomId|$messageId');
  }

  DateTime? pickedDate;
  TimeOfDay? pickedTime;
  DateTime? scheduledMessageDateTime;
  ScrollController chatScrollController = ScrollController();

  RxBool isReplyOnMessage = false.obs;
  Messages? repliedMessage;
  String? repliedOnId;
  String receiverId = '';
  RxBool generatingMessage = false.obs;
  RxString generatedMessage = ''.obs;
  RxList selectedRoomList = [].obs;
  RxBool showEmojiPicker = false.obs;

  RxMap messageSelectorMap = {}.obs;
  List<String> youMessages = [];
  bool hideActions = false;
  bool editingMessage = false;
  String? editingMessageId;
  List typingUsers = [];
  late ItemScrollController itemScrollController;
  late ItemPositionsListener itemPositionsListener;
  RxBool showScrollToBottom = false.obs;

  /// Number of new messages that arrived while the user was scrolled away
  /// from the latest message. Reset when the user reaches the bottom.
  RxInt scrollToBottomUnreadCount = 0.obs;

  /// Vertical distance (px) from the bottom of the viewport that still counts
  /// as "at the latest message". A small band instead of pixel-perfect so the
  /// jump button does not flicker on tiny scroll nudges.
  static const double kNearBottomThresholdPx = 120;

  bool uploadMedia = true;

  // Scroll-state tracking. `_viewportExtent` is fed from ScrollMetrics by the
  // chat screen's NotificationListener; `itemPositionsListener` drives the
  // actual near-bottom decision so insertions (not just scrolls) re-evaluate.
  double _viewportExtent = 0;
  bool _manualScrollSinceJump = false;
  bool _jumpToLatestInFlight = false;

  late IO.Socket socket;
  late Timer _onlineTimer;

  /// Exposes the existing socket lifecycle (onConnect/onDisconnect/
  /// onConnectError/onReconnect*) to the connectivity UI. No new socket,
  /// no new listeners — the same callbacks set this value.
  final Rx<SocketConnectionState> socketConnectionState =
      Rx(SocketConnectionState.connecting);

  Uint8List? sentFile;
  // RxMap downloadingMediaMap = {}.obs;

  // ── Media composer state ────────────────────────────────────────────────
  // Transient multi-media attachments shown in MediaComposerScreen. Unlike the
  // legacy single-slot flow (pickedMediaPath/sentFile), here each selected
  // media keeps its own slot until the batch is sent (or the user cancels).
  final RxList<ComposerMediaItem> composerItems = <ComposerMediaItem>[].obs;

  /// Guards against duplicate send taps / double-submits while a batch is
  /// in flight. Resets as soon as the whole batch resolves.
  bool _composerSending = false;

  /// Drives the composer UI (disable interactions, show progress).
  RxBool composerSending = false.obs;

  /// HD toggle: when true, image compression is skipped at send time so the
  /// receiver gets the original picker output. Video keeps its source quality
  /// either way (client-side video compression is not available).
  RxBool composerHdQuality = false.obs;

  final ImagePicker _composerPicker = ImagePicker();

  RxBool toggleSendButton = false.obs;
  RxBool playVideo = false.obs;
  RxMap isVideoPlayingMap = {}.obs;
  bool scheduleOn = false;
  RxBool scheduleSheetVisible = false.obs;
  String? scheduleMessageContext;
  bool _scheduledSendInFlight = false;
  RxBool showTyping = false.obs;

  RxMap isAudioPlayingMap = {}.obs;
  Duration? audioDuration;
  Duration? audioPosition;
  RxDouble audioCurrentPosition = 0.0.obs;
  RxString audioCurrentPositionString = '00:00'.obs;
  RxBool isRecording = false.obs;
  RxBool isRecordingPaused = false.obs;
  RxInt recordingDuration = 0.obs;
  RxString recordingQuality = 'medium'.obs;
  Timer? _recordingTimer;

  AudioRecorder? _recorder;
  bool _recorderStarting = false;
  final justAudio.AudioPlayer _audioPlayer = justAudio.AudioPlayer();
  String? _activeAudioId;
  UniqueKey? _activeAudioKey;
  bool _audioStreamsBound = false;
  double playbackSpeed = 1.0;
  List<Map<String, dynamic>> roomsNewMessagesMap = [];
  RxInt selectedInterval = 0.obs;
  RxInt scheduleCount = 0.obs;
  String currentRoom = '';
  RxBool deleteRoomMedia = true.obs;

  // Phase 1 - Advanced Features
  RxBool isMultiSelectMode = false.obs;
  RxMap<String, List<String>> messageReactions = <String, List<String>>{}.obs;
  RxList<Messages> pinnedMessages = <Messages>[].obs;
  RxList<Messages> starredMessages = <Messages>[].obs;
  RxList<Messages> searchResults = <Messages>[].obs;
  RxString searchQuery = ''.obs;
  RxBool isSearching = false.obs;
  RxBool showPinnedBar = false.obs;
  TextEditingController searchController = TextEditingController();

  BirdController birdController = Get.find();
  UserController userController = Get.find();
  HomeController homeController = Get.find();
  ContactController contactController = Get.find();
  late RxList<Map<String, dynamic>> shareContactsList;
  late TextEditingController textMessageController;
  late TextEditingController promptController;
  late TextEditingController aiMessageController;
  late TextEditingController previewController;
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();

  @override
  void onInit() {
    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();
    itemPositionsListener.itemPositions.addListener(_trackScrollPosition);
    // Establish connection with socket server.
    connectToSocket();
    // Replay any offline queued sends once this controller is live.
    if (Get.isRegistered<OfflineQueueService>()) {
      OfflineQueueService.to.resendHandler = resendPendingOfflineMessages;
    }
    // Keep the socket joined to every known room so the server always knows
    // where to deliver messages (older socket servers deliver only to sockets
    // inside the room — no receiver-targeted routing).
    ever(homeController.singleChatsList, (_) => joinAllRooms());
    ever(homeController.groupsList, (_) => joinAllRooms());
    super.onInit();
  }

  @override
  void onReady() {
    // If changes in contacts send contacts to humming bird website.
    // Site will receive contacts if user online.
    if (userController.storage.read('contact_db_changed') ?? false) {
      sendContactsToWeb();
    }
    super.onReady();
  }

  @override
  void onClose() {
    try {
      itemPositionsListener.itemPositions.removeListener(_trackScrollPosition);
    } catch (_) {}
    chatScrollController.dispose();
    dateController.dispose();
    timeController.dispose();
    searchController.dispose();
    try {
      _recorder?.dispose();
    } catch (_) {}
    _audioPlayer.dispose();
    try {
      _onlineTimer.cancel();
    } catch (_) {}
    _recordingTimer?.cancel();
    try {
      debugPrint('[SOCKET-TRACE] onClose: disconnecting socket ${socket.id}');
      socket.disconnect();
      socket.dispose();
    } catch (_) {}
    super.onClose();
  }

  void connectToSocket() async {
    try {
      final uid = await getUserId();
      final token = userController.storage.read('userToken')?.toString() ?? '';
      if (uid.isEmpty || token.isEmpty) {
        debugPrint(
            '[SOCKET-TRACE] connectToSocket skipped: missing user ID or token');
        return;
      }
      debugPrint(
          '[SOCKET-TRACE] connectToSocket: userId=$uid url=${Endpoints.socketUrl}');
      socket = IO.io(
          Endpoints.socketUrl,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .enableReconnection()
              .setReconnectionDelay(2000)
              .setReconnectionAttempts(100)
              .setAuth({'token': token})
              .setQuery({'userId': uid}) // send user id to socket server
              .build());

      socket.onConnect((_) {
        socketConnectionState.value = SocketConnectionState.connected;
        debugPrint('[SOCKET-TRACE] CONNECTED id=${socket.id} userId=$uid');
      });
      socket.onDisconnect((reason) {
        socketConnectionState.value = SocketConnectionState.disconnected;
        debugPrint(
            '[SOCKET-TRACE] DISCONNECTED id=${socket.id} userId=$uid reason=$reason');
      });
      socket.onConnectError((err) {
        socketConnectionState.value =
            socketConnectionState.value == SocketConnectionState.connected
                ? SocketConnectionState.reconnecting
                : SocketConnectionState.connecting;
        debugPrint(
            '[SOCKET-TRACE] CONNECT_ERROR id=${socket.id} userId=$uid error=$err');
      });
      socket.onError((err) {
        debugPrint(
            '[SOCKET-TRACE] SOCKET_ERROR id=${socket.id} userId=$uid error=$err');
      });
      socket.onReconnect((attempt) {
        socketConnectionState.value = SocketConnectionState.connected;
        debugPrint(
            '[SOCKET-TRACE] RECONNECTED id=${socket.id} userId=$uid attempt=$attempt');
      });
      socket.onReconnectError((err) {
        socketConnectionState.value = SocketConnectionState.reconnecting;
        debugPrint(
            '[SOCKET-TRACE] RECONNECT_ERROR id=${socket.id} userId=$uid error=$err');
      });
      socket.onReconnectFailed((_) {
        socketConnectionState.value = SocketConnectionState.disconnected;
        debugPrint(
            '[SOCKET-TRACE] RECONNECT_FAILED id=${socket.id} userId=$uid');
      });

      socket.connect();

      messageListener();
      // Join every known room right away (also re-fires after reconnects via
      // the 'connect' listener registered in messageListener()).
      joinAllRooms();
    } catch (e) {
      debugPrint('[SOCKET-TRACE] connectToSocket EXCEPTION: $e');
    }
  }

  /// Re-establishes the EXISTING socket instance (never creates a second
  /// one). Safe to call from the connectivity UI's "Retry connection".
  void retryConnection() {
    try {
      if (!socket.connected) {
        socketConnectionState.value = SocketConnectionState.connecting;
        socket.connect();
      }
    } catch (_) {}
  }

  // Socket listener
  void messageListener() {
    try {
      // Emit current user is online
      socket.emit('user-online', userController.userId);
    } catch (_) {}

    // Emit current user is online in every 5 sec.
    try {
      _onlineTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        try {
          socket.emit('user-online', userController.userId);
        } catch (_) {}
      });
    } catch (_) {}

    // Remove old listeners to prevent duplicates
    const events = [
      'online',
      'offline',
      'scheduled-message-sent',
      'message-receive',
      'delivered',
      'seen',
      'fetch-groups',
      'on-typing',
      'on-not-typing',
      'message-deleted',
      'message-reaction-update',
      'message-edited',
      'message-pinned-status',
      'message-forwarded',
      'requesting-contacts',
      'pending-room-activated',
      'group-updated',
      'profile-updated',
      'moment-created',
      'moment-updated',
      'moment-deleted',
      'moment-published',
      'moment-expired',
      'new-message',
    ];
    for (final event in events) {
      try {
        socket.off(event);
      } catch (_) {}
    }

    // Listen who is online in humming bird
    socket.on('online', (userId) {
      try {
        if (userId != null) {
          getOnlineUser([userId]);
        }
      } catch (_) {}
    });

    // Listen if anyone goes offline in humming bird
    socket.on('offline', (userId) {
      try {
        removeOfflineUser(userId);
      } catch (_) {}
    });

    // Re-join every known room after (re)connects — the socket server drops
    // room membership on disconnect, and older servers route message-receive
    // only to sockets that joined the room.
    socket.on('connect', (_) {
      debugPrint('[SOCKET-TRACE] on connect event — re-joining rooms');
      joinAllRooms();
    });

    // Broadcast sent for every message. Older socket servers rely on it as the
    // only live signal for recipients outside the room: join the room so
    // subsequent messages arrive, and pull the room into the local chat list
    // when it is not known yet.
    socket.on('new-message', (roomId) {
      try {
        final id = roomId?.toString() ?? '';
        if (id.isEmpty) return;
        socket.emit('join-room', id);
        if (homeController.singleChatsList.any((r) => r.rId == id) ||
            homeController.groupsList.any((r) => r.rId == id)) {
          return;
        }
        homeController.fetchSingleChats();
        homeController.fetchGroupChats();
      } catch (_) {}
    });

    // Listen if scheduled message is sent.
    socket.on('scheduled-message-sent', (data) async {
      try {
        if (data is Map<String, dynamic>) {
          final lastMessageForList = Messages.fromJson(data);
          Messages msg = Messages.fromJson(data);
          msg.mMessage =
              await EncryptionHelper.decryptAsync(msg.mMessage ?? '');
          updateLocalRoomLastMessage(lastMessageForList);
          LocalDatabase.saveMessage([msg]);
          int index = messages.indexWhere((e) => e.mId == msg.mId);
          if (index >= 0) {
            messages[index] = msg;
          } else if (msg.mRoomId == selectedRoom.value) {
            messages.insert(0, msg);
            _handleNewMessageInsert(isOwn: true);
          }
          await birdController.getScheduledMessages();
          update();
        } else {
          String mId = data.toString();
          int index = messages.indexWhere((element) => element.mId == mId);
          if (index >= 0) {
            Messages msg = messages[index];
            msg.mReadStatus = '1';
            messages.removeAt(index);
            messages.insert(index, msg);
            updateLocalRoomLastMessage(msg);
            update();
          }
        }
      } catch (_) {}
    });

    // Listen for new messages
    socket.on('message-receive', (data) async {
      try {
        final lastMessageForList = Messages.fromJson(data);
        Messages msg = Messages.fromJson(data);
        if (kDebugMode) {
          debugPrint('STATUS-REPLY-TRACE → received chat message '
              'storyRef=${msg.mStoryRef}');
        }
        final roomId = msg.mRoomId ?? '';
        final messageId = msg.mId ?? '';
        // Session-level duplicate guard: ignores re-deliveries (reconnects /
        // overlapping scheduled + manual broadcasts) so unread counters and
        // notifications are never inflated.
        if (_markIncomingProcessed(roomId, messageId)) return;

        // Decrypt on an isolate; a decryption failure (e.g. legacy layers)
        // must never drop the message from the UI.
        try {
          msg.mMessage =
              await EncryptionHelper.decryptAsync(msg.mMessage ?? '');
        } catch (_) {}
        try {
          LocalDatabase.saveMessage([msg]);
        } catch (_) {}

        // Persisted group events (m_message_type '7') are informational rows:
        // they never inflate unread badges, fire notifications, feed AI
        // replies, or trigger media/mention handling — history + realtime
        // delivery go through the exact same pipeline as every other message.
        final isSystemEvent = GroupSystemMessageService.isSystem(msg);

        if (msg.mSenderId != userController.user?.userId) {
          // Best-effort, never blocks delivery.
          try {
            _autoDownloadIncomingMedia(msg);
            final senderId = msg.mSenderId ?? '';
            if (senderId.isNotEmpty && Get.isRegistered<ContactController>()) {
              final contactController = Get.find<ContactController>();
              if (!contactController.hasLocalUserName(senderId)) {
                contactController.resolveUserIdentity(senderId);
              }
            }
          } catch (_) {}
        }

        if (_isActiveChatRoom(roomId)) {
          messages.removeWhere((e) => e.showTyping == true);
          int existingIndex = messages.indexWhere((e) => e.mId == messageId);
          if (existingIndex >= 0) {
            messages[existingIndex] = msg;
          } else {
            messages.insert(0, msg);
            _resortMessages();
          }
          update();
          if (!isSystemEvent) {
            _handleNewMessageInsert(
              isOwn: msg.mSenderId == userController.user?.userId,
            );
          }
          msg.mReadStatus = '2';
          try {
            socket.emit('message-delivered', msg);
          } catch (_) {}
          if (msg.mSenderId != userController.user?.userId &&
              msg.mMessageType == '0') {
            final plainText = msg.mMessage ?? '';
            if (plainText.isNotEmpty) {
              final fallbackId = messageId.isNotEmpty
                  ? messageId
                  : DateTime.now().millisecondsSinceEpoch.toString();
              loadReplySuggestions(plainText);
              categorizeMessage(plainText, messageId: fallbackId);
              analyzeSentiment(plainText, messageId: fallbackId);
              checkSpam(plainText, messageId: fallbackId);
            }
          }
        } else {
          // Never inflate the sender's own unread badge or fire a local
          // notification for their own message (scheduled-message relays and
          // multi-device broadcasts both re-deliver own messages to this
          // client's other sockets).
          final isOwn = msg.mSenderId == userController.user?.userId;
          if (!isOwn && !isSystemEvent && roomId.isNotEmpty) {
            homeController.saveUnreadMessages(roomId, refreshRooms: false);
          }
          if (!isOwn && !isSystemEvent) {
            await _showIncomingSocketNotification(msg);
          }
        }
        updateLocalRoomLastMessage(lastMessageForList);
        try {
          await birdController.getScheduledMessages();
        } catch (_) {}
      } catch (_) {}
    });

    // Listen for delivered messages.
    socket.on('delivered', (data) {
      try {
        final msg = Messages.fromJson(data);
        _patchMessageStatus(msg, msg.mReadStatus ?? '2');
      } catch (_) {}
    });

    // Listen for message is seen
    socket.on('seen', (data) {
      try {
        if (data != null) {
          final msg = Messages.fromJson(data);
          _patchMessageStatus(msg, '3');
        }
      } catch (_) {}
    });

    // Fetch groups
    socket.on('fetch-groups', (data) async {
      try {
        await homeController.fetchGroupChats();
        if (Get.isRegistered<ContactController>()) {
          final contactController = Get.find<ContactController>();
          contactController.groupsList = RxList.from(homeController.groupsList);
          contactController.groupData = List.from(homeController.groupsList);
          contactController.update(['group-search-update', 'Update Group']);
        }
      } catch (_) {}
    });

    // Group state changed (members joined/left, name/photo/admin changed)
    socket.on('group-updated', (roomId) async {
      try {
        var wasMember = false;
        if (Get.isRegistered<GroupController>()) {
          final groupController = Get.find<GroupController>();
          if (groupController.groupData?.room?.rId == roomId) {
            wasMember = true;
            groupController.fetchGroupInfo(roomId);
          }
        }
        await homeController.fetchGroupChats();
        if (Get.isRegistered<ContactController>()) {
          final contactController = Get.find<ContactController>();
          contactController.groupsList = RxList.from(homeController.groupsList);
          contactController.groupData = List.from(homeController.groupsList);
          contactController.update(['group-search-update', 'Update Group']);
        }
        await _handleGroupMembershipChanged(
          roomId,
          wasMember: wasMember,
        );
      } catch (_) {}
    });

    // User profile changed (name/photo/bio) — refresh local copies
    socket.on('profile-updated', (data) async {
      try {
        if (data is! Map) return;
        final User updated = User.fromJson(Map<String, dynamic>.from(data));
        if (updated.userId == null || updated.userId == userController.userId) {
          return;
        }
        // Update contact list copy
        if (Get.isRegistered<ContactController>()) {
          final contactController = Get.find<ContactController>();
          final i = contactController.hummingContacts
              .indexWhere((u) => u.userId == updated.userId);
          if (i >= 0) {
            contactController.hummingContacts[i] = updated;
            contactController.update([
              'group-search-update',
              'Update Group',
              'update-contacts-search'
            ]);
          }
        }
        // Update group members copy (so header avatars/names refresh)
        if (Get.isRegistered<GroupController>()) {
          final groupController = Get.find<GroupController>();
          final members = groupController.groupData?.members;
          if (members != null) {
            final j = members.indexWhere((u) => u.userId == updated.userId);
            if (j >= 0) {
              members[j] = updated;
              groupController.update(['Update Group State']);
              groupController.update();
            }
          }
        }
      } catch (_) {}
    });

    // Typing Listener
    socket.on('on-typing', (data) {
      try {
        if (data['roomId'] == selectedRoom.value && currentRoom.isNotEmpty) {
          showTyping.value = true;
        }
        updateChatCardForTyping(data['userId']);
      } catch (_) {}
    });

    // Stop Typing Listener
    socket.on('on-not-typing', (data) {
      try {
        showTyping.value = false;
        typingUsers.removeWhere(
          (value) => value == data['userId'],
        );
        update(['update-typing']);
      } catch (_) {}
    });

    // Listen for deleted messages.
    socket.on('message-deleted', (msgId) async {
      try {
        final id = msgId?.toString();
        if (id == null || id.isEmpty) return;
        int idx = messages.indexWhere((e) => e.mId == id);
        Messages? msg;
        if (idx >= 0) {
          msg = messages[idx];
        } else {
          // The message may belong to a thread that is not currently loaded
          // (user is on the chat list or in another chat) — still purge it
          // locally so it never re-appears with its original content.
          msg = LocalDatabase.getSingleMessages(id);
        }
        if (msg == null) return;
        msg.mIsDeleted = '1';
        msg.mDeletedAt = DateTime.now().toIso8601String();
        msg.mMessage = '';
        msg.mMedia = null;
        msg.mRepliedOn = null;
        LocalDatabase.saveMessage([msg]);
        if (idx >= 0) {
          messages.refresh();
        } else {
          _maybeRefreshRoomLastMessage(msg);
        }
        update();
      } catch (_) {}
    });

    // Phase 1 - Socket event listeners
    socket.on('message-reaction-update', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final mId = data['m_id']?.toString();
          final reactionsStr = data['m_reactions']?.toString();
          if (mId != null) {
            _applyReactionsToMessage(mId, reactionsStr);
            // Real-time pulse so the bubble plays the Instagram-style
            // floating reaction animation when a reaction arrives over
            // the socket (connectivity-driven).
            if (reactionsStr != null && reactionsStr.isNotEmpty) {
              _pulseReaction(mId);
            }
          }
        }
      } catch (_) {}
    });

    socket.on('message-edited', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final mId = data['m_id']?.toString();
          final newMsg = data['m_message']?.toString();
          if (mId != null) {
            final idx = messages.indexWhere((m) => m.mId == mId);
            if (idx >= 0) {
              messages[idx].mMessage = newMsg ?? messages[idx].mMessage;
              messages[idx].mIsEdited = '1';
              messages[idx].mUpdatedAt = data['m_updated_at']?.toString();
              LocalDatabase.saveMessage([messages[idx]]);
              update();
            }
          }
        }
      } catch (_) {}
    });

    socket.on('message-pinned-status', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final mId = data['m_id']?.toString();
          final pinned = data['pinned']?.toString() ?? '0';
          final roomId = data['m_room_id']?.toString();
          if (mId != null && roomId == selectedRoom.value) {
            final idx = messages.indexWhere((m) => m.mId == mId);
            if (idx >= 0) {
              messages[idx].mPinned = pinned;
              LocalDatabase.saveMessage([messages[idx]]);
              if (pinned == '1' && !pinnedMessages.any((m) => m.mId == mId)) {
                pinnedMessages.add(messages[idx]);
              } else {
                pinnedMessages.removeWhere((m) => m.mId == mId);
              }
              showPinnedBar.value = pinnedMessages.isNotEmpty;
              update();
            }
          }
        }
      } catch (_) {}
    });

    socket.on('message-forwarded', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final Messages fwdMsg = Messages.fromJson(data);
          fwdMsg.mMessage = '';
          EncryptionHelper.decryptAsync(data['m_message'] ?? '')
              .then((decrypted) {
            try {
              fwdMsg.mMessage = decrypted;
              if (fwdMsg.mRoomId == selectedRoom.value) {
                messages.insert(0, fwdMsg);
                LocalDatabase.saveMessage([fwdMsg]);
                update();
                _handleNewMessageInsert(
                  isOwn: fwdMsg.mSenderId == userController.user?.userId,
                );
              } else {
                final roomId = fwdMsg.mRoomId ?? '';
                if (roomId.isNotEmpty) {
                  homeController.saveUnreadMessages(roomId,
                      refreshRooms: false);
                }
              }
              updateLocalRoomLastMessage(fwdMsg);
            } catch (_) {}
          });
        }
      } catch (_) {}
    });

    // Listen if humming website requesting phone contacts.
    socket.on('requesting-contacts', (userId) async {
      try {
        var id = await getUserId();
        if (id.toString() == userId.toString()) {
          sendContactsToWeb();
        }
      } catch (_) {}
    });

    // Listen for pending room activation
    socket.on('pending-room-activated', (data) async {
      try {
        homeController.fetchSingleChats();
        homeController.update(['update-card']);
      } catch (_) {}
    });

    // Scheduled Moments socket events
    try {
      final momentEvents = [
        'moment-created',
        'moment-updated',
        'moment-deleted',
        'moment-published',
        'moment-expired',
      ];
      for (final event in momentEvents) {
        socket.on(event, (data) {
          try {
            if (data is Map<String, dynamic> &&
                Get.isRegistered<ScheduledMomentController>()) {
              Get.find<ScheduledMomentController>()
                  .handleSocketEvent(event, data);
            }
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  /// Updates the last message on the local room list so we avoid a full API
  /// round-trip on every incoming socket message.
  void updateLocalRoomLastMessage(Messages msg) {
    final isGroupMessage = _isGroupMessage(msg);
    final rooms = isGroupMessage
        ? homeController.groupsList
        : homeController.singleChatsList;
    final idx = rooms.indexWhere((r) => r.rId == msg.mRoomId);
    if (idx >= 0) {
      final room = rooms[idx];
      room.rLastMessage = msg;
      rooms.removeAt(idx);
      rooms.insert(0, room);
      LocalDatabase.saveRooms([room]);
      if (!isGroupMessage) {
        homeController.data = List.from(homeController.singleChatsList);
      } else if (Get.isRegistered<ContactController>()) {
        final contactController = Get.find<ContactController>();
        contactController.groupsList = RxList.from(homeController.groupsList);
        contactController.groupData = List.from(homeController.groupsList);
        contactController.update(['group-search-update', 'Update Group']);
      }
      homeController.update(['search-update', 'update-card']);
      homeController.update();
    } else {
      // Room not yet in the local list — fetch from API once.
      isGroupMessage
          ? homeController.fetchGroupChats()
          : homeController.fetchSingleChats();
    }
  }

  /// Public helper used by the Status viewer / share sheet after sending a
  /// story-reply message: inserts the confirmed message into the open chat
  /// (decrypted, like incoming socket messages), persists it locally and
  /// updates the chat-list last-message preview.
  void addSentMessage(Messages msg) {
    try {
      messages.removeWhere((e) => e.mId == msg.mId);
      if (msg.mRoomId == selectedRoom.value) {
        final display = Messages.fromJson(msg.toJson());
        display.mMessage =
            EncryptionHelper().decryptMessage(msg.mMessage ?? '');
        messages.insert(0, display);
        LocalDatabase.saveMessage([display]);
      } else {
        LocalDatabase.saveMessage([msg]);
      }
      updateLocalRoomLastMessage(msg);
      update();
    } catch (_) {}
  }

  bool _isGroupMessage(Messages msg) {
    final roomId = msg.mRoomId;
    if (roomId == null || roomId.isEmpty) return false;
    if (homeController.groupsList.any((r) => r.rId == roomId)) return true;
    if (Get.isRegistered<ContactController>()) {
      final contactController = Get.find<ContactController>();
      if (contactController.groupsList.any((r) => r.rId == roomId)) {
        return true;
      }
    }
    return (msg.mReceiverId ?? '').isEmpty;
  }

  /// Applies delivery/read status from a socket event WITHOUT touching the
  /// message content. The previous handlers rebuilt the message object from
  /// the event payload (whose `m_message` can be missing/empty) and replaced
  /// the local + persisted copy — wiping the text out of the bubble until the
  /// chat was reopened. This only patches status fields and preserves content.
  void _patchMessageStatus(Messages incoming, String status) {
    try {
      final id = incoming.mId;
      if (id == null) return;
      final index = messages.indexWhere((e) => e.mId == id);
      if (index >= 0) {
        final existing = messages[index];
        existing.mReadStatus = status;
        final seenBy = incoming.mSeenBy;
        if (seenBy != null && seenBy.isNotEmpty) {
          existing.mSeenBy = seenBy;
        }
        messages[index] = existing;
        LocalDatabase.saveMessage([existing]);
        update();
      }
      _updateLocalRoomStatus(incoming, status);
    } catch (_) {}
  }

  /// Updates only the delivery/read status of the room's last message in the
  /// local lists (no reordering, no API round-trip) so the chat-list tick
  /// refreshes when 'delivered'/'seen' events arrive.
  void _updateLocalRoomStatus(Messages msg, String status) {
    try {
      final rooms = _isGroupMessage(msg)
          ? homeController.groupsList
          : homeController.singleChatsList;
      final idx = rooms.indexWhere((r) => r.rId == msg.mRoomId);
      if (idx < 0) return;
      final last = rooms[idx].rLastMessage;
      if (last == null || last.mId == null || last.mId != msg.mId) return;
      last.mReadStatus = status;
      LocalDatabase.saveRooms([rooms[idx]]);
      homeController.update(['update-card']);
      homeController.update();
    } catch (_) {}
  }

  /// Refreshes the chat-list preview only when [msg] is the room's last
  /// message (used by delete-for-everyone arriving over the socket while the
  /// thread is not loaded). Does not reorder the room.
  void _maybeRefreshRoomLastMessage(Messages msg) {
    try {
      final rooms = _isGroupMessage(msg)
          ? homeController.groupsList
          : homeController.singleChatsList;
      final idx = rooms.indexWhere((r) => r.rId == msg.mRoomId);
      if (idx < 0) return;
      final last = rooms[idx].rLastMessage;
      if (last == null || last.mId == null || last.mId != msg.mId) return;
      rooms[idx].rLastMessage = msg;
      LocalDatabase.saveRooms([rooms[idx]]);
      homeController.update(['update-card']);
      homeController.update();
    } catch (_) {}
  }

  /// Auto-downloads incoming media according to Storage Settings
  /// (auto_download_mobile / auto_download_wifi) and current connectivity.
  Future<void> _autoDownloadIncomingMedia(Messages msg) async {
    try {
      final type = msg.mMessageType ?? '';
      if (!{'1', '2', '3', '4'}.contains(type)) return;
      final url = msg.mMedia ?? '';
      if (url.isEmpty) return;
      final mediaId = msg.mId ?? '';
      if (mediaId.isEmpty) return;
      if (LocalDatabase.getMedia(mediaId) != null) return;

      final storage = userController.storage;
      final allowMobile = storage.read('auto_download_mobile') ?? true;
      final allowWifi = storage.read('auto_download_wifi') ?? true;

      final result = await Connectivity().checkConnectivity();
      final bool allowed;
      if (result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet)) {
        allowed = allowWifi;
      } else if (result.contains(ConnectivityResult.mobile)) {
        allowed = allowMobile;
      } else {
        allowed = false;
      }
      if (!allowed) return;

      downloadMedia(url, mediaId, msg.mRoomId ?? '', type,
          showErrorSnackbar: false);
    } catch (_) {}
  }

  /// A room is muted when its shared r_status is '0'. Falls back to the
  /// contact-controller copy of the group list in case the home lists are
  /// stale.
  bool _isRoomMuted(String roomId) {
    Rooms? room = homeController.groupsList
            .firstWhereOrNull((r) => r.rId == roomId) ??
        homeController.singleChatsList.firstWhereOrNull((r) => r.rId == roomId);
    if (room != null) return (room.rStatus ?? '1') == '0';
    if (Get.isRegistered<ContactController>()) {
      final contactController = Get.find<ContactController>();
      room =
          contactController.groupsList.firstWhereOrNull((r) => r.rId == roomId);
      if (room != null) return (room.rStatus ?? '1') == '0';
    }
    return false;
  }

  List<String> _decodeRoomUsers(String? rUsers) {
    if (rUsers == null || rUsers.isEmpty) return [];
    try {
      final decoded = jsonDecode(rUsers);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  /// After a group-updated event, if this device's user is no longer a group
  /// member (removed by an admin) — or the group simply disappeared from the
  /// server's group list — wipe it locally and kick the user off the chat.
  Future<void> _handleGroupMembershipChanged(
    Object? roomIdData, {
    bool wasMember = false,
  }) async {
    final roomId = roomIdData?.toString();
    if (roomId == null || roomId.isEmpty) return;
    final myId = userController.user?.userId ?? '';
    if (myId.isEmpty) return;

    final wasInChat =
        homeController.currentRoom == roomId || selectedRoom.value == roomId;

    // Self-initiated exit already wiped + navigated with its own message; the
    // broadcast that follows is just a no-op refresh on this device.
    final groupControllerSet = Get.isRegistered<GroupController>();
    if (groupControllerSet &&
        Get.find<GroupController>().selfLeftRoomId == roomId) {
      Get.find<GroupController>().selfLeftRoomId = null;
      return;
    }

    final room =
        homeController.groupsList.firstWhereOrNull((r) => r.rId == roomId);
    final removed = room != null
        ? !_decodeRoomUsers(room.rUsers).contains(myId)
        : (wasMember || wasInChat);
    if (!removed) return;

    LocalDatabase.deleteRoom(roomId);
    LocalDatabase.deleteRoomMessages(roomId);
    homeController.groupsList.removeWhere((r) => r.rId == roomId);
    if (Get.isRegistered<ContactController>()) {
      final contactController = Get.find<ContactController>();
      contactController.groupsList.removeWhere((r) => r.rId == roomId);
      contactController.groupData.removeWhere((r) => r.rId == roomId);
      contactController.groupsList.refresh();
    }
    homeController.update(['update-card']);
    homeController.update();

    if (wasInChat) {
      Get.offAll(() => const MainHummingScreen());
    }
    Utils.showGetSnackBar('You were removed from this group');
  }

  Future<void> _showIncomingSocketNotification(Messages msg) async {
    final roomId = msg.mRoomId ?? '';
    if (roomId.isEmpty || roomId == homeController.currentRoom) return;
    // Muted rooms never notify (badge-only, exactly like WhatsApp)
    if (_isRoomMuted(roomId)) return;

    final storage = userController.storage;
    final isGroup = _isGroupMessage(msg);
    // Respect Notification Settings toggles
    if (isGroup && storage.read('notif_groups_show') == false) return;
    if (!isGroup && storage.read('notif_messages_show') == false) return;
    // Never notify about messages from users this account has blocked
    final senderId = msg.mSenderId ?? '';
    if (senderId.isNotEmpty &&
        Get.isRegistered<ContactController>() &&
        Get.find<ContactController>().checkIfUserIsBlocked(senderId)) {
      return;
    }

    final title = isGroup
        ? _groupName(roomId)
        : _senderDisplayName(msg.mSenderId ?? '') ?? 'New message';
    String body = _notificationPreview(msg);
    if (storage.read('notif_preview') == false &&
        (msg.mMessageType == '0' || msg.mMessageType == '5')) {
      body = 'New message';
    }

    await NotificationService.showLocalMessageNotification(
      id: int.tryParse(msg.mId ?? '') ?? msg.hashCode,
      title: title,
      body: body,
      dedupeKey: '$roomId:${msg.mId ?? msg.mCreatedAt ?? body}',
      payload: {
        'roomId': roomId,
        'senderId': msg.mSenderId ?? '',
        'senderName': _senderDisplayName(msg.mSenderId ?? '') ?? '',
        'senderNumber': '',
        'isGroup': isGroup ? '1' : '0',
        'groupName': isGroup ? title : '',
        'profile_pic': '',
        'bio': '',
        'messageId': msg.mId ?? '',
      },
    );
  }

  String _notificationPreview(Messages msg) {
    if (msg.mMessageType == '0' || msg.mMessageType == '5') {
      final text = (msg.mMessage ?? '').trim();
      if (text.isEmpty) return 'New message';
      return LinkPreviewService.isLink(text)
          ? LinkPreviewService.linkSummary(text)
          : text;
    }
    return AppHelper.getMediaName(fileType: msg.mMessageType ?? '0');
  }

  String _groupName(String roomId) {
    Rooms? room = homeController.groupsList.firstWhereOrNull(
      (room) => room.rId == roomId,
    );
    if (room == null && Get.isRegistered<ContactController>()) {
      final contactController = Get.find<ContactController>();
      room = contactController.groupsList.firstWhereOrNull(
        (room) => room.rId == roomId,
      );
    }
    return room?.rName?.trim().isNotEmpty == true ? room!.rName! : 'Group';
  }

  String? _senderDisplayName(String senderId) {
    if (senderId.isEmpty) return null;
    if (Get.isRegistered<ContactController>()) {
      final resolved =
          Get.find<ContactController>().resolveUserNameLocal(senderId);
      if (resolved.isNotEmpty) return resolved;
    }
    final contacts = LocalDatabase.getAllCustomContacts();
    final contact = contacts.firstWhereOrNull((e) => e.id == senderId);
    if (contact?.displayName?.trim().isNotEmpty == true) {
      return contact!.displayName!;
    }
    final user = LocalDatabase.getUser(senderId);
    final name =
        '${user?.userFirstName ?? ''} ${user?.userLastName ?? ''}'.trim();
    return name.isNotEmpty ? name : null;
  }

  String _scheduleCountPayload() {
    if (isScheduledMessage.value != '1') return '0';
    if (selectedInterval.value == 0) return '0';
    return scheduleCount.value == 0 ? '-1' : scheduleCount.value.toString();
  }

  void typingListener() {
    textMessageController.addListener(
      () async {
        if (textMessageController.text.trim().isNotEmpty) {
          toggleSendButton.value = true;
          socket.emit('typing', {
            'roomId': selectedRoom.value,
            'userId': await getUserId(),
            'receiverId': receiverId,
          });
        } else {
          toggleSendButton.value = false;
          editingMessage = false;
          editingMessageId = null;
          messageSelectorMap.clear();
          removeTyping();
        }
      },
    );
  }

  void removeTyping() async {
    socket.emit('not-typing', {
      'roomId': selectedRoom.value,
      'userId': await getUserId(),
      'receiverId': receiverId,
    });
  }

  void emitNewGroup(userIds) {
    socket.emit('new-group', userIds);
  }

  /// Notify all group members that the group state changed
  /// (members joined/left, name/photo/admin changed).
  void emitGroupUpdate(String roomId, [List<String>? memberIds]) {
    try {
      socket.emit('group-update', {
        'roomId': roomId,
        'memberIds': memberIds,
      });
    } catch (_) {}
  }

  /// Notify everyone that the current user changed their profile
  /// (name, photo or bio).
  void emitProfileUpdated(User user) {
    try {
      socket.emit('profile-updated', {
        'user_id': user.userId,
        'first_name': user.userFirstName,
        'last_name': user.userLastName,
        'user_image': user.userImage,
        'user_bio': user.userBio,
      });
    } catch (_) {}
  }

  // Send all device contacts to humming website
  void sendContactsToWeb() async {
    userController.storage.write('contact_db_changed', false);

    List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true, withPhoto: true);
    List<Map<String, dynamic>> allContacts = [];

    for (int i = 0; i < contacts.length; i++) {
      if (contacts[i].phones.isNotEmpty) {
        String number = contacts[i].phones[0].number;

        if (number[0] == '+') {
          number =
              number.substring(3).replaceAllMapped(RegExp(r'\D'), (_) => '');
        } else {
          number = number.replaceAllMapped(RegExp(r'\D'), (_) => '');
        }
        allContacts.add({
          'name': contacts[i].displayName,
          'number': number,
        });
      }
    }

    socket.emit('send-contacts', jsonEncode(allContacts));
  }

  // Display typing in chat card.
  void updateChatCardForTyping(userId) {
    List<CustomContactsModel> contacts = LocalDatabase.getAllCustomContacts();

    List<String> contactIds = contacts.map((e) => e.id!).toList();

    if (contactIds.contains(userId)) {
      typingUsers.add(userId);
      update(['update-typing']);
    }
  }

  void joinRoom(String roomId) {
    socket.emit('join-room', roomId);
  }

  /// Joins every chat the user has locally (single + group rooms). Keeps the
  /// socket inside all rooms at all times so incoming messages are delivered
  /// regardless of whether the socket server routes by receiver id or by room.
  /// Idempotent server-side; emits are buffered until the socket connects.
  void joinAllRooms() {
    try {
      final roomIds = <String>{};
      for (final room in homeController.singleChatsList) {
        if (room.rId != null && room.rId!.isNotEmpty) roomIds.add(room.rId!);
      }
      for (final room in homeController.groupsList) {
        if (room.rId != null && room.rId!.isNotEmpty) roomIds.add(room.rId!);
      }
      debugPrint(
          '[SOCKET-TRACE] joinAllRooms: ${roomIds.length} rooms to join');
      for (final id in roomIds) {
        socket.emit('join-room', id);
      }
    } catch (e) {
      debugPrint('[SOCKET-TRACE] joinAllRooms EXCEPTION: $e');
    }
  }

  void leaveRoom(String roomId) {
    socket.emit('leave-room', roomId);
  }

  void updateRooms(String roomId) {
    if (roomId != currentRoom) {
      roomsNewMessagesMap.add({
        'roomId': roomId,
      });
    }
  }

  Future<String> getUserId() async {
    String? userId = userController.storage.read('userId');

    if (userId != null && userId.isNotEmpty) {
      return userId;
    } else {
      return userId ?? '';
    }
  }

  String updateRoomUI(String roomId) {
    List<Map<String, dynamic>> newMessages =
        roomsNewMessagesMap.where((element) {
      return element['roomId'] == roomId;
    }).toList();

    if (newMessages.isEmpty) {
      return '0';
    } else {
      return newMessages.length.toString();
    }
  }

  void getOnlineUser(List<String> userIds) async {
    List<Future<UserModel?>> users = [];
    List<CustomContactsModel> contacts = LocalDatabase.getAllCustomContacts();

    List<String> contactIds = contacts.map((e) => e.id!).toList();
    List<String> onlineIds =
        homeController.onlineUsers.map((e) => e.userId!).toList();

    List<String> userBlockList = <String>[];
    try {
      final raw = userController.user?.userBlockList ?? '[]';
      userBlockList = (jsonDecode(raw) as List? ?? []).cast<String>();
    } catch (_) {}

    for (var userId in userIds) {
      if (contactIds.contains(userId) &&
          !onlineIds.contains(userId) &&
          !userBlockList.contains(userId)) {
        users.add(UserApi().getUserData(userId));
      }
    }

    List<UserModel?> usersData = await Future.wait(users);

    if (usersData.isNotEmpty) {
      for (var user in usersData) {
        if (user?.status ?? false) {
          homeController.onlineUsers.add(user!.user!);
        }
      }
      Set<User> tempSet = homeController.onlineUsers.toSet();
      homeController.onlineUsers = RxList.from(tempSet.toList());
      update(['active-users']);
    }
  }

  void _trackScrollPosition() {
    if (messages.isEmpty) {
      _setLatestScrollState(false);
      return;
    }
    final positions = itemPositionsListener.itemPositions.value;
    // Layout hasn't caught up yet — keep the last known state instead of
    // flipping the affordance on spuriously.
    if (positions.isEmpty) return;
    // The list is reversed, so index 0 is the newest message (bottom). A user
    // is "at the latest" when the newest item sits within a small pixel band
    // above the viewport bottom — tracked via its leading edge, which is 0 at
    // the bottom and negative when scrolled up.
    final newest = positions.firstWhere(
      (p) => p.index == 0,
      orElse: () =>
          ItemPosition(index: -1, itemLeadingEdge: 0, itemTrailingEdge: 0),
    );
    if (newest.index != 0) {
      _setLatestScrollState(true);
      return;
    }
    _setLatestScrollState(
      _distanceFromLatestPx(newest.itemLeadingEdge) > kNearBottomThresholdPx,
    );
  }

  /// Distance in px between the newest message's bottom edge and the bottom of
  /// the viewport. For a reversed vertical list the package reports edges in
  /// scroll-offset space: index 0 has `itemLeadingEdge == 0` when flush with
  /// the bottom edge, and it grows *negative* by the scrolled-up pixels. So the
  /// distance is `-leadingEdge * extent` (0 at the bottom).
  double _distanceFromLatestPx(double itemLeadingEdge) {
    final extent = _viewportExtent > 0 ? _viewportExtent : 600.0;
    final dist = -itemLeadingEdge;
    return (dist < 0 ? 0.0 : dist) * extent;
  }

  double _latestDistancePx() {
    final positions = itemPositionsListener.itemPositions.value;
    for (final p in positions) {
      if (p.index == 0) {
        return _distanceFromLatestPx(p.itemLeadingEdge);
      }
    }
    return double.infinity;
  }

  /// True when the newest message is visible within the near-bottom band.
  bool _isUserNearBottom() {
    if (messages.isEmpty) return true;
    return _latestDistancePx() <= kNearBottomThresholdPx;
  }

  void _setLatestScrollState(bool show) {
    if (showScrollToBottom.value != show) {
      showScrollToBottom.value = show;
    }
    // Reaching the latest message clears the "N new messages" affordance.
    if (!show && scrollToBottomUnreadCount.value != 0) {
      scrollToBottomUnreadCount.value = 0;
    }
  }

  /// Fed by the chat screen's NotificationListener: keeps the pixel-accurate
  /// viewport size so near-bottom detection works without layout queries.
  void onScrollMetrics(
      {required double pixels, required double viewportDimension}) {
    if (viewportDimension > 0) _viewportExtent = viewportDimension;
  }

  /// Marks that the user is driving the scroll with their finger (Flutter
  /// reports `dragDetails` for user-initiated drags). Used to avoid fighting
  /// the user if they grab the list mid jump-to-latest animation.
  void markManualScroll() {
    _manualScrollSinceJump = true;
  }

  /// Keeps the chat pinned to the newest message after an insertion when the
  /// user is already at the bottom. Never moves the user when scrolled up.
  void _keepPinnedToLatest() {
    if (messages.isEmpty || _jumpToLatestInFlight) return;
    if (!itemScrollController.isAttached) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      if (messages.isEmpty || _jumpToLatestInFlight) return;
      if (!_isUserNearBottom()) return;
      try {
        itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    });
  }

  /// Central handling for a message inserted while the chat is on screen:
  /// near the bottom → glide to the newest message; scrolled up → just count
  /// it (own messages are never counted).
  void _handleNewMessageInsert({required bool isOwn}) {
    if (_isUserNearBottom()) {
      _keepPinnedToLatest();
    } else if (!isOwn) {
      scrollToBottomUnreadCount.value = scrollToBottomUnreadCount.value + 1;
    }
  }

  Future<void> scrollToBottom() async {
    if (messages.isEmpty || !itemScrollController.isAttached) return;
    scrollToBottomUnreadCount.value = 0;
    _manualScrollSinceJump = false;
    _jumpToLatestInFlight = true;
    try {
      await itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
    _jumpToLatestInFlight = false;
    if (isClosed) return;
    // Race-condition guard: if the list grew while the animation ran (new
    // messages arrived mid-flight) and the user did not grab the list, land
    // on the *real* latest message instead of ending a hair above it.
    if (!_manualScrollSinceJump &&
        messages.isNotEmpty &&
        !_isUserNearBottom()) {
      try {
        await itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    }
  }

  void scrollToMessage(String messageId) {
    int index = messages.indexWhere((element) => element.mId == messageId);
    if (index < 0) return;

    hideActions = true;
    itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 500),
        alignment: 0.5);

    messageSelectorMap[messageId] = true;
    Timer(const Duration(seconds: 3), () {
      messageSelectorMap.remove(messageId);
      hideActions = false;
    });
  }

  void removeOfflineUser(String userId) {
    homeController.onlineUsers
        .removeWhere((element) => element.userId == userId);
    update(['active-users']);
  }

  void replyOnMessage(Messages message) {
    isReplyOnMessage.value = !isReplyOnMessage.value;
    isReplyOnMessage.value = true;
    repliedMessage = message;
    repliedOnId = message.mId!;
  }

  void generateMessageWithAi() async {
    if (promptController.text.trim().isNotEmpty) {
      generatingMessage.value = true;

      String? aiMessage =
          await TextGeneration().getGeneratedText(promptController.text.trim());

      promptController.clear();

      if (aiMessage != null) {
        generatedMessage.value = aiMessage;
      } else {
        Utils.showGetSnackBar(
            'AI generation failed. Check your network connection and API key, then try again.');
      }
      generatingMessage.value = false;
    } else {
      Utils.showGetSnackBar('Please enter what you want to generate.');
    }
  }

  Future<void> enhanceInputMessageWithAi() async {
    final input = textMessageController.text.trim();
    if (input.isEmpty) {
      Utils.showGetSnackBar('Please write a message first.');
      return;
    }

    String? enhanced;
    generatingMessage.value = true;
    try {
      enhanced = await TextGeneration().getGeneratedText(
        'Rewrite and enhance this chat message. Keep the original meaning, keep it concise, and return only the improved message: "$input"',
      );
    } finally {
      generatingMessage.value = false;
    }

    if (enhanced == null || enhanced.trim().isEmpty) return;
    textMessageController.text = enhanced.trim();
    textMessageController.selection = TextSelection.fromPosition(
      TextPosition(offset: textMessageController.text.length),
    );
    toggleSendButton.value = true;
  }

  void sendMessageOrAudio(BuildContext context) {
    if (toggleSendButton.value == false) {
      if (dateController.text.isNotEmpty && timeController.text.isNotEmpty) {
        recordAudio();
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const RecordAudioAnim(fromScheduleScreen: false));
      } else {
        Utils.showGetSnackBar('Please pick scheduling date and time first');
      }
    } else {
      setDateAndTime();
    }
  }

  Future<void> sendMessage(
      {bool aiGenerated = false,
      String generatedMessage = '',
      bool fromScheduledScreen = false,
      bool contactShare = false,
      String contacts = '',
      List<String> mentionIds = const []}) async {
    final schedulingNow = isScheduledMessage.value == '1';
    if (aiGenerated) {
      if (aiMessageController.text.trim().isNotEmpty) {
        Map<String, dynamic> messageData = {
          'm_room_id': selectedRoom.value,
          'm_message_type': '0',
          'm_message': EncryptionHelper()
              .encryptMessage(aiMessageController.text.trim()),
          'm_sender_id': userController.user!.userId,
          'm_replied_on': repliedOnId,
          'me': true,
          'receiver_id': selectedContactId.value,
          'm_read_status': '0',
          if (schedulingNow) 'm_is_scheduled': isScheduledMessage.value,
          if (schedulingNow)
            'm_scheduled_at':
                AppHelper.convertScheduledTimeToEpoch(scheduledMessageDateTime)
                    .toString(),
          if (schedulingNow) 'm_interval': selectedInterval.value.toString(),
          if (schedulingNow) 'm_count': _scheduleCountPayload(),
        };

        isReplyOnMessage.value = false;
        repliedMessage = null;
        repliedOnId = null;

        Messages message = Messages.fromJson(messageData);
        // Show plaintext locally — we already have it, no need to decrypt.
        message.mMessage = aiMessageController.text.trim();
        message.mReadStatus = '1';
        // Optimistic entry has no server id yet — give it a temp one so
        // bubble builders that force-unwrap mId don't crash before the
        // confirmed message replaces it.
        message.mId ??= 'tmp${DateTime.now().microsecondsSinceEpoch}';
        if (!schedulingNow) {
          messages.insert(0, message);
        }

        update();
        textMessageController.clear();
        if (!schedulingNow) {
          itemScrollController.scrollTo(
              index: 0, duration: const Duration(milliseconds: 500));
        }

        MessageModel? res;
        try {
          res = await MessageApi().sendMessage(messageData);
        } catch (_) {
          try {
            res = await MessageApi().sendMessage(messageData);
          } catch (_) {}
        }
        scheduledMessageDateTime = null;
        pickedDate = null;
        pickedTime = null;
        dateController.clear();
        timeController.clear();

        if (res?.status ?? false) {
          if (res?.msg != null) {
            selectedRoom.value = res!.msg!.mRoomId!;
            final lastMessageForList = Messages.fromJson(res.msg!.toJson());
            final confirmedMsg = res.msg!
              ..mMessage = aiMessageController.text.trim();
            socket.emit('message', res.msg!.toJson());
            if (schedulingNow) {
              await birdController.getScheduledMessages();
              if (!fromScheduledScreen) {
                _showScheduleConfirmation(res.msg!);
              } else {
                Utils.showGetSnackBar('Message Scheduled Successfully');
              }
            } else {
              final optimisticIndex = messages.indexOf(message);
              if (optimisticIndex >= 0) {
                messages[optimisticIndex] = confirmedMsg;
              } else {
                messages.insert(0, confirmedMsg);
              }
              LocalDatabase.saveMessage([confirmedMsg]);
              updateLocalRoomLastMessage(lastMessageForList);
            }
            update();
            _safePopRoute();
          }
        } else {
          _handleOfflineSendFailure(
              optimistic: message,
              payload: messageData,
              result: res,
              schedulingNow: schedulingNow);
        }
      }
    } else {
      if (editingMessage && editingMessageId != null) {
        final editText = textMessageController.text.trim();
        final editIndex = messages.indexWhere((e) => e.mId == editingMessageId);
        if (editText.isNotEmpty && editIndex >= 0) {
          updateMessage(messages[editIndex], false, false,
              newMessage: editText);
        } else if (editText.isNotEmpty) {
          Utils.showGetSnackBar('This message can no longer be edited.');
        }
        editingMessage = false;
        editingMessageId = null;
        messageSelectorMap.value = {};
        youMessages = [];
        textMessageController.clear();
        return;
      }
      if (textMessageController.text.trim().isNotEmpty || contactShare) {
        Map<String, dynamic> messageData = {
          'm_room_id': selectedRoom.value,
          'm_message_type': contactShare ? '6' : '0',
          'm_message': contactShare
              ? EncryptionHelper().encryptMessage(contacts)
              : EncryptionHelper()
                  .encryptMessage(textMessageController.text.trim()),
          'm_sender_id': userController.user!.userId,
          'm_replied_on': repliedOnId,
          'me': true,
          'receiver_id': selectedContactId.value,
          'm_read_status': '0',
          if (mentionIds.isNotEmpty) 'm_mentions': jsonEncode(mentionIds),
          if (schedulingNow) 'm_is_scheduled': isScheduledMessage.value,
          if (schedulingNow)
            'm_scheduled_at':
                AppHelper.convertScheduledTimeToEpoch(scheduledMessageDateTime)
                    .toString(),
          if (schedulingNow) 'm_interval': selectedInterval.value.toString(),
          if (schedulingNow) 'm_count': _scheduleCountPayload(),
        };

        isReplyOnMessage.value = false;
        repliedMessage = null;
        repliedOnId = null;

        // Capture plaintext before clearing the field.
        final plainText =
            contactShare ? contacts : textMessageController.text.trim();
        Messages message = Messages.fromJson(messageData);
        // Show plaintext locally — avoids a pointless decrypt of what we just encrypted.
        message.mMessage = plainText;
        message.mReadStatus = '1';
        // Optimistic entry has no server id yet — give it a temp one so
        // bubble builders that force-unwrap mId don't crash before the
        // confirmed message replaces it.
        message.mId ??= 'tmp${DateTime.now().microsecondsSinceEpoch}';
        if (mentionIds.isNotEmpty) message.mMentions = mentionIds;
        if (!schedulingNow) {
          messages.insert(0, message);
        }
        update();
        textMessageController.clear();
        if (!fromScheduledScreen && !schedulingNow) {
          itemScrollController.scrollTo(
              index: 0, duration: const Duration(milliseconds: 500));
        }

        MessageModel? res;
        try {
          res = await MessageApi().sendMessage(messageData);
        } catch (_) {
          try {
            res = await MessageApi().sendMessage(messageData);
          } catch (_) {}
        }
        scheduledMessageDateTime = null;
        pickedDate = null;
        pickedTime = null;
        dateController.clear();
        timeController.clear();

        if (res?.status ?? false) {
          if (res?.msg != null) {
            socket.emit('message', res!.msg!.toJson());
            selectedRoom.value = res.msg!.mRoomId!;
            final lastMessageForList = Messages.fromJson(res.msg!.toJson());
            // Replace optimistic entry with confirmed message; keep plaintext.
            final confirmedMsg = res.msg!..mMessage = plainText;
            if (schedulingNow) {
              await birdController.getScheduledMessages();
              if (!fromScheduledScreen) {
                _showScheduleConfirmation(confirmedMsg);
              } else {
                Utils.showGetSnackBar('Message Scheduled Successfully');
              }
            } else {
              LocalDatabase.saveMessage([confirmedMsg]);
              int existingIndex =
                  messages.indexWhere((e) => e.mId == confirmedMsg.mId);
              if (existingIndex >= 0) {
                messages[existingIndex] = confirmedMsg;
              } else {
                final optimisticIndex = messages.indexOf(message);
                if (optimisticIndex >= 0) {
                  messages[optimisticIndex] = confirmedMsg;
                } else {
                  messages.insert(0, confirmedMsg);
                }
              }
              updateLocalRoomLastMessage(lastMessageForList);
            }
            messages.refresh();
            update();
            selectedInterval.value = 0;
            scheduleCount.value = 1;
          }
        } else {
          _handleOfflineSendFailure(
              optimistic: message,
              payload: messageData,
              result: res,
              schedulingNow: schedulingNow);
        }
      } else {
        Utils.showGetSnackBar('Please enter message before scheduling');
      }
    }
  }

  /// Offline send fallback. A genuine network failure (`result.status ==
  /// null`, produced by a swallowed transport error) preserves the optimistic
  /// bubble and queues the encrypted payload for replay when connectivity
  /// returns. A real server rejection (`status == false`) is unchanged: the
  /// bubble is removed and the reason surfaced. Scheduled sends are never
  /// queued — the schedule screen already guards on connectivity.
  void _handleOfflineSendFailure({
    required Messages optimistic,
    required Map<String, dynamic> payload,
    required MessageModel? result,
    required bool schedulingNow,
  }) {
    final isNetworkFailure = result?.status == null;
    if (isNetworkFailure && !schedulingNow) {
      try {
        OfflineQueueService.to.enqueue({
          'id': optimistic.mId,
          'room_id': selectedRoom.value,
          'payload': payload,
          'queued_at': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      } catch (_) {
        // Queue unavailable — fall through to the standard failure path.
      }
      Utils.showGetSnackBar(
        'No internet — message saved. Will send automatically when online.',
        duration: 3,
      );
      update();
      return;
    }
    messages.remove(optimistic);
    update();
    final reason = (result?.message?.isNotEmpty ?? false)
        ? result!.message!
        : 'Something went wrong.';
    Utils.showGetSnackBar(reason, duration: 5);
  }

  /// Replay of queued offline sends, wired to [OfflineQueueService] when
  /// connectivity returns. Re-sends the encrypted payload, replaces the
  /// optimistic tmp-id bubble with the confirmed message, persists, and
  /// relays the confirmed message to the room. Failures stay queued.
  Future<void> resendPendingOfflineMessages() async {
    final queue = OfflineQueueService.to.getQueue();
    if (queue.isEmpty) return;
    for (final item in queue) {
      final id = item['id']?.toString();
      final payload = item['payload'] as Map<String, dynamic>?;
      if (payload == null) {
        OfflineQueueService.to.dequeue(id ?? '');
        continue;
      }
      MessageModel? res;
      try {
        res = await MessageApi().sendMessage(payload);
      } catch (_) {
        try {
          res = await MessageApi().sendMessage(payload);
        } catch (_) {}
      }
      if (res?.status ?? false) {
        final confirmed = res?.msg;
        if (confirmed != null) {
          final roomId = item['room_id']?.toString();
          // Replace only if this conversation is still on screen; otherwise
          // just persist + relay so the other thread updates on next open.
          if (_isActiveChatRoom(roomId)) {
            final idx = messages.indexWhere((e) => e.mId == id);
            if (idx >= 0) {
              final plain = messages[idx].mMessage;
              confirmed.mMessage = plain;
              messages[idx] = confirmed;
            } else {
              messages.insert(0, confirmed);
            }
          }
          try {
            LocalDatabase.saveMessage([confirmed]);
          } catch (_) {}
          try {
            socket.emit('message', confirmed.toJson());
          } catch (_) {}
          updateLocalRoomLastMessage(confirmed);
          update();
        }
        OfflineQueueService.to.dequeue(id ?? '');
      }
      // Failure — keep in queue; next reconnect retries.
    }
  }

  void updateMessage(Messages message, bool isForSeen, bool isGroup,
      {String? newMessage}) async {
    if (newMessage != '') birdController.showLoading.value = true;
    Map<String, dynamic> messageData = {
      'm_id': message.mId,
      'new_message': isForSeen
          ? null
          : EncryptionHelper().encryptMessage(newMessage ?? ''),
      'message_status': message.mReadStatus,
      'seen_by': await getUserId(),
    };
    MessageModel? updatedMessage =
        await MessageApi().updateMessage(messageData);

    if (updatedMessage?.status ?? false) {
      int index = messages
          .indexWhere((element) => element.mId == updatedMessage?.msg?.mId);
      Messages updatedMsg = updatedMessage!.msg!;
      updatedMsg.mMessage =
          EncryptionHelper().decryptMessage(updatedMessage.msg?.mMessage ?? '');

      if (index >= 0) {
        messages.removeAt(index);
        messages.insert(index, updatedMsg);
      } else {
        messages.insert(0, updatedMsg);
      }
      update();
      if (isForSeen) {
        socket.emit('message-seen', updatedMessage.msg);
      }
      if (!isForSeen && newMessage != null && updatedMsg.mIsEdited == '1') {
        socket.emit('message-edit', {
          'm_id': updatedMsg.mId,
          'm_message': updatedMsg.mMessage,
          'm_room_id': updatedMsg.mRoomId ?? message.mRoomId,
          'm_updated_at': updatedMsg.mUpdatedAt,
        });
      }
      LocalDatabase.saveMessage([updatedMsg]);
    } else {
      Utils.showGetSnackBar(
          updatedMessage?.message ?? 'Something went wrong. Try again later');
    }
    textMessageController.clear();
    if (newMessage != '') birdController.showLoading.value = false;
  }

  void sendMedia(
      {required int messageType,
      bool isScheduled = false,
      bool includeText = false}) async {
    final schedulingMedia = scheduleOn || isScheduledMessage.value == '1';
    if (scheduleOn) {
      if (pickedDate != null && pickedTime != null) {
        scheduledMessageDateTime = DateTime(
          pickedDate!.year,
          pickedDate!.month,
          pickedDate!.day,
          pickedTime!.hour, // This is already in 24-hour format
          pickedTime!.minute,
        );

        if (DateTime.now().isAfter(scheduledMessageDateTime!)) {
          Utils.showGetSnackBar(
              'You picked time that has been already passed. Please pick future date and time.',
              duration: 5);
          pickedDate = null;
          pickedTime = null;
          dateController.clear();
          timeController.clear();
          isScheduledMessage.value = '0';
        } else {
          isScheduledMessage.value = '1';
          Dio.FormData data = Dio.FormData.fromMap({
            'message': includeText ? previewController.text.trim() : '',
            'room_id': selectedRoom.value,
            'message_type': messageType.toString(),
            'is_scheduled': isScheduledMessage.value,
            'scheduled_at': AppHelper.convertScheduledTimeToEpoch(
                    scheduledMessageDateTime ?? DateTime.now())
                .toString(),
            'me': true,
            'receiver_id': selectedContactId.value,
            'm_interval': selectedInterval.value.toString(),
            'm_count': _scheduleCountPayload(),
            'm_replied_on': repliedOnId,
            'media_file': await Dio.MultipartFile.fromFile(
                pickedMediaPath.value.toString(),
                filename: pickedMediaPath.value.split('/').last)
          });

          final MessageModel? message =
              await MessageApi().sendFormData(formData: data);

          isReplyOnMessage.value = false;
          repliedMessage = null;
          repliedOnId = null;
          uploadingFile.value = false;
          birdController.uploadValue.value = 0.0;

          if (message?.status ?? false) {
            if (message?.msg == null) {
              Utils.showGetSnackBar('Failed to send. Please try again.');
              return;
            }
            selectedRoom.value = message!.msg!.mRoomId!;
            _safePopRoute();
            socket.emit('message', message.msg!.toJson());
            if (sentFile != null && !schedulingMedia) {
              messages.insert(0, message.msg!);
              saveMediaInDeviceDirectory(
                  messageType.toString(),
                  message.msg!.mId!,
                  message.msg!.mRoomId!,
                  sentFile!,
                  message.msg!.mMedia!);
              LocalDatabase.saveMessage([message.msg!]);
              homeController.fetchSingleChats();
            }
            if (schedulingMedia) {
              await birdController.getScheduledMessages();
            }
            if (schedulingMedia && !isScheduled) {
              _showScheduleConfirmation(message.msg!);
            }
          } else {
            Utils.showGetSnackBar(
                message?.message ?? 'Failed to send. Please try again.');
          }
          dateController.clear();
          timeController.clear();
          isScheduledMessage.value = '0';
          sentFile = null;
          update();
          if (!isScheduled) {
            itemScrollController.scrollTo(
                index: 0, duration: const Duration(milliseconds: 500));
          }
          if (schedulingMedia && isScheduled) {
            Utils.showGetSnackBar('Message Scheduled Successfully');
          }
        }
      } else {
        Utils.showGetSnackBar('Pick both Date and Time for Scheduling');
      }
    } else {
      Dio.FormData data = Dio.FormData.fromMap({
        'message': includeText ? previewController.text.trim() : '',
        'room_id': selectedRoom.value,
        'message_type': messageType.toString(),
        'is_scheduled': isScheduledMessage.value,
        'scheduled_at': '0',
        'me': true,
        'receiver_id': selectedContactId.value,
        'm_interval': selectedInterval.value.toString(),
        'm_count': _scheduleCountPayload(),
        'm_replied_on': repliedOnId,
        'media_file': await Dio.MultipartFile.fromFile(
            pickedMediaPath.value.toString(),
            filename: pickedMediaPath.value.split('/').last)
      });

      final MessageModel? message =
          await MessageApi().sendFormData(formData: data);

      isReplyOnMessage.value = false;
      repliedMessage = null;
      repliedOnId = null;
      uploadingFile.value = false;
      birdController.uploadValue.value = 0.0;
      uploadMedia = true;

      if (message?.status ?? false) {
        if (message?.msg == null) {
          Utils.showGetSnackBar('Failed to send. Please try again.');
          return;
        }
        selectedRoom.value = message!.msg!.mRoomId!;
        messages.insert(0, message.msg!);
        socket.emit('message', message.msg!.toJson());
        if (sentFile != null) {
          saveMediaInDeviceDirectory(messageType.toString(), message.msg!.mId!,
              message.msg!.mRoomId!, sentFile!, message.msg!.mMedia!);
          LocalDatabase.saveMessage([message.msg!]);
          homeController.fetchSingleChats();
          textMessageController.clear();
        }
      } else {
        Utils.showGetSnackBar(
            message?.message ?? 'Failed to send. Please try again.');
      }
      dateController.clear();
      timeController.clear();
      isScheduledMessage.value = '0';
      sentFile = null;
      update();
      itemScrollController.scrollTo(
          index: 0, duration: const Duration(milliseconds: 500));
    }
    if (messageType != 3) {
      previewController.dispose();
    }
  }

  void deleteAllMessage(String roomId, bool isDeleteMedia) {
    List<String> messageIds = messages.map((element) => element.mId!).toList();
    deleteMessage(messageIds, '0', isDeleteMedia);
    if (isDeleteMedia) {
      List<MediaModel?> roomMedias = LocalDatabase.getRoomMedia(roomId);
      deleteMedia(List.from(roomMedias.map((e) => e?.id).toList()));
    }
  }

  void deleteMessage(
      List<String> messageId, String deleteFor, bool isDeleteMedia) async {
    Map<String, dynamic> res =
        await MessageApi().deleteMessage(messageId, deleteFor);

    if (res['status'] ?? false) {
      String myId = '';
      try {
        myId = (await getUserId()).toString();
      } catch (_) {}

      for (String id in messageId) {
        Messages? msg = LocalDatabase.getSingleMessages(id);
        final isMine = msg != null && msg.mSenderId.toString() == myId;

        if (deleteFor == '1' && msg != null) {
          socket.emit('message-delete', msg);
        }

        final idx = messages.indexWhere((element) => element.mId! == id);
        if (idx >= 0) {
          if (deleteFor == '1' && isMine) {
            // WhatsApp-style: keep the bubble, mark it deleted so the UI
            // renders "You deleted this message".
            messages[idx].mIsDeleted = '1';
            messages[idx].mDeletedAt = DateTime.now().toIso8601String();
            messages[idx].mMessage = '';
            messages[idx].mMedia = null;
            messages[idx].mRepliedOn = null;
            LocalDatabase.saveMessage([messages[idx]]);
          } else {
            messages.removeWhere((element) => element.mId! == id);
            LocalDatabase.deleteMessages([id]);
          }
        } else if (deleteFor == '0') {
          LocalDatabase.deleteMessages([id]);
        }
      }

      if (isDeleteMedia) {
        deleteMedia(messageId);
      }
      messages.refresh();
      update();
      _safePopRoute();
    } else {
      final reason = res['message']?.toString() ??
          'Something went wrong while deleting the message';
      Utils.showGetSnackBar(reason);
    }
    messageSelectorMap.value = {};
  }

  void deleteRoom(String roomId, bool isDeleteMedia, bool fromUserInfo) async {
    Map<String, dynamic> res = await RoomApi().deleteRoom(roomId);

    if (res['status'] ?? false) {
      _safePopRoute();
      if (fromUserInfo) {
        _safePopRoute();
        _safePopRoute();
      }
      LocalDatabase.deleteRoom(roomId);
      LocalDatabase.deleteRoomMessages(roomId);
      if (isDeleteMedia) {
        List<MediaModel?> roomMedias = LocalDatabase.getRoomMedia(roomId);
        deleteMedia(List.from(roomMedias.map((e) => e?.id).toList()));
      }
      homeController.singleChatsList.removeWhere((r) => r.rId == roomId);
      homeController.data.removeWhere((r) => r.rId == roomId);
      homeController.groupsList.removeWhere((r) => r.rId == roomId);
      homeController.update(['update-card']);
      homeController.update();
      homeController.fetchSingleChats();
      Utils.showGetSnackBar('Chat deleted successfully');
    } else {
      Utils.showGetSnackBar('Something went wrong, Try again later.');
    }
  }

  Future<void> saveMediaInDeviceDirectory(String mediaType, String mediaId,
      String roomId, Uint8List bytes, String url) async {
    try {
      final Directory dir = await getApplicationDocumentsDirectory();

      String path =
          '${dir.path}/Humming-Bird/${AppHelper.getMediaPathName(mediaType)}';

      Directory(path).createSync(recursive: true);

      LocalDatabase.saveMedia([
        MediaModel(
            id: mediaId,
            mediaPath: '$path/$mediaId.${AppHelper.getFileExtension(url)}',
            mediaRoomId: roomId)
      ]);
      final File file =
          File('$path/$mediaId.${AppHelper.getFileExtension(url)}');
      await file.writeAsBytes(bytes);

      update([mediaId]);
    } catch (e) {
      // Silently handle
    }
  }

  Future<Uint8List?> getMediaFromPath(String mediaId) async {
    try {
      MediaModel? mediaModel = LocalDatabase.getMedia(mediaId);

      if (mediaModel != null) {
        final File file = File(mediaModel.mediaPath!);
        if (!file.existsSync()) return null;
        return await file.readAsBytes();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void downloadMedia(
      String mediaUrl, String mediaId, String roomId, String mediaType,
      {bool showErrorSnackbar = true}) async {
    if (birdController.downloadingMediaMap[mediaId] == true) return;
    birdController.downloadingMediaMap[mediaId] = true;
    try {
      Uint8List? media =
          await ApiService().downloadMedia(url: mediaUrl, mediaId: mediaId);
      if (media != null) {
        birdController.downloadingMediaMap['${mediaId}_attempted'] = true;
        saveMediaInDeviceDirectory(mediaType, mediaId, roomId, media, mediaUrl);
        update([mediaId]);
      }
    } catch (e) {
      birdController.downloadingMediaMap['${mediaId}_attempted'] = true;
      if (showErrorSnackbar) {
        CustomSnackbar.error(
            title: 'Download failed',
            message: 'Could not download media. Check your connection.');
      }
    } finally {
      birdController.downloadingMediaMap[mediaId] = false;
      birdController.downloadingMediaMap['${mediaId}_downloaded'] = true;
    }
  }

  void cancelDownload(String mediaId) {
    birdController.downloadingMediaMap[mediaId] = false;
    birdController.downloadingMediaMap['${mediaId}_progress'] = 0.0;
    birdController.downloadingMediaMap['${mediaId}_cancelled'] = true;
  }

  Future<void> deleteMedia(List<String> mediaIds) async {
    await Permission.manageExternalStorage.request();

    try {
      for (String id in mediaIds) {
        MediaModel? media = LocalDatabase.getMedia(id);

        if (media != null) {
          final File file = File(media.mediaPath!);
          await file.delete();
        }
      }
      LocalDatabase.deleteMedia(mediaIds);
      update(mediaIds);
    } catch (e) {
      // Silently handle
    }
  }

  void manageMessageSelector(String messageId, {bool isYouMessage = false}) {
    if (messageSelectorMap.isNotEmpty) {
      if (messageSelectorMap[messageId] == true) {
        messageSelectorMap.remove(messageId);
        if (isYouMessage) youMessages.remove(messageId);
        if (messageSelectorMap.isEmpty) isMultiSelectMode.value = false;
      } else {
        messageSelectorMap[messageId] = true;
        if (isYouMessage) youMessages.add(messageId);
      }
    }
  }

  void manageRoomSelector(String roomId) {
    if (selectedRoomList.contains(roomId)) {
      selectedRoomList.remove(roomId);
    } else {
      selectedRoomList.add(roomId);
    }
  }

  void clearRoomSelection() {
    selectedRoomList.clear();
  }

  void selectAllRooms(List<String> roomIds) {
    selectedRoomList
      ..clear()
      ..addAll(roomIds);
  }

  void selectMessageOnLongPress(String messageId, {bool isYouMessage = false}) {
    messageSelectorMap[messageId] = true;
    if (isYouMessage) youMessages.add(messageId);
  }

  void fetchMessages(roomId, receiverId) async {
    // showLoading.value = true;
    // loadingSingleChats.value = true;
    messages = RxList.from(
      LocalDatabase.getMessages(roomId)
          .where((message) => message.mIsScheduled != '1')
          .toList(),
    );
    selectedRoom.value = roomId;
    selectedContactId.value = receiverId;

    final RoomMessagesModel? allMessagesData =
        await MessageApi().fetchAllMessages(roomId);

    if (allMessagesData?.status ?? false) {
      final rawMessages = (allMessagesData!.room!.messages ?? [])
          .where((message) => message.mIsScheduled != '1')
          .toList();

      // Batch-decrypt in a background isolate — keeps the main thread free.
      final encrypted = rawMessages.map((m) => m.mMessage ?? '').toList();
      final decrypted = await EncryptionHelper.decryptListAsync(encrypted);
      for (var i = 0; i < rawMessages.length; i++) {
        rawMessages[i].mMessage = decrypted[i];
      }

      // The incoming socket handler may have inserted messages while the API
      // call was in flight — merge (server wins on conflict, locally-seen ids
      // dedupe by mId) instead of wholesale replacing the list.
      final serverById = <String, Messages>{
        for (final m in rawMessages)
          if (m.mId != null) m.mId!: m
      };
      final merged = <Messages>[];
      final seenIds = <String>{};
      for (final m in [...rawMessages, ...messages]) {
        final id = m.mId;
        if (id != null) {
          if (seenIds.add(id)) merged.add(serverById[id] ?? m);
        } else {
          merged.add(m);
        }
      }
      merged.sort((a, b) => b.sentEpochSeconds.compareTo(a.sentEpochSeconds));

      messages.value = merged;
      LocalDatabase.saveMessage(rawMessages);
    } else {
      Utils.showGetSnackBar('Something went wrong');
    }

    // Fresh chat open → always land on the latest message (reversed list, so
    // index 0 is the newest). Deep-link "scroll to message" entries keep the
    // highlight flow pointing at their target instead of the bottom.
    scrollToBottomUnreadCount.value = 0;
    showScrollToBottom.value = false;
    final args = Get.arguments;
    final wantsMessageJump = args is Map && args['isScroll'] != null;
    if (!wantsMessageJump) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isClosed || !itemScrollController.isAttached) return;
        try {
          itemScrollController.jumpTo(index: 0);
        } catch (_) {}
      });
    }

    // showLoading.value = false;
    // loadingSingleChats.value = false;

    // Map<String, List<Messages>> grouped = {};
    // for (var message in messages) {
    //   DateTime now = DateTime.now();
    //   DateTime messageDate = DateTime.parse(message.mScheduledAt == '0'
    //       ? message.mCreatedAt!
    //       : message.mUpdatedAt!);
    //   String timeFrameKey;
    //
    //   if (messageDate.isAtSameMomentAs(now)) {
    //     timeFrameKey = 'Today';
    //   } else if (now.difference(messageDate).inDays == 1) {
    //     timeFrameKey = 'Yesterday';
    //   } else {
    //     timeFrameKey = DateFormat('dd/mm/yyyy').format(messageDate);
    //   }
    //
    //   if (!grouped.containsKey(timeFrameKey)) {
    //     grouped[timeFrameKey] = [];
    //   }
    //   grouped[timeFrameKey]?.add(message);
    // }
    update();
  }

  void setDateAndTime(
      {bool aiGenerated = false, bool fromScheduleScreen = false}) {
    if (pickedDate != null && pickedTime != null) {
      scheduledMessageDateTime = DateTime(
        pickedDate!.year,
        pickedDate!.month,
        pickedDate!.day,
        pickedTime!.hour,
        pickedTime!.minute,
      );
      if (DateTime.now().isAfter(scheduledMessageDateTime!)) {
        Utils.showGetSnackBar(
            'You picked time that has been already passed. Please pick date and time from future.',
            duration: 5);
        pickedDate = null;
        pickedTime = null;
        dateController.clear();
        timeController.clear();
        isScheduledMessage.value = '0';
      } else if (aiGenerated && aiMessageController.text.trim().isEmpty) {
        pickedDate = null;
        pickedTime = null;
        dateController.clear();
        timeController.clear();
        isScheduledMessage.value = '0';
        _safePopRoute();
        Utils.showGetSnackBar(
            'Please generate a message first that schedule it.');
      } else {
        // Guard against double-tap on Schedule/Create: pickedDate/time are
        // only cleared after the send request completes, so a second tap in
        // that window would dispatch an identical duplicate schedule. The
        // lock is released once the in-flight send finishes (success, error,
        // empty-text early return) regardless of outcome.
        if (_scheduledSendInFlight) return;
        _scheduledSendInFlight = true;
        isScheduledMessage.value = '1';
        // The send runs on the next frame so the sheet can settle first, but
        // `isScheduledMessage` (and `scheduledMessageDateTime`) must stay armed
        // until `sendMessage` has built its payload — it reads both
        // synchronously to decide between scheduling and an immediate send.
        // Resetting the flag here (before the callback ran) made every
        // chat/group schedule leave as an immediate message. Release the
        // schedule state only once the in-flight send has finished, success or
        // failure, so double-tap protection still holds.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            if (aiGenerated) {
              await sendMessage(
                  aiGenerated: aiGenerated,
                  fromScheduledScreen: fromScheduleScreen);
            } else {
              await sendMessage(fromScheduledScreen: fromScheduleScreen);
            }
          } finally {
            _scheduledSendInFlight = false;
            isScheduledMessage.value = '0';
            dateController.clear();
            timeController.clear();
          }
        });
        _safePopRoute();
      }
    } else {
      Utils.showGetSnackBar('Pick both Date and Time for Scheduling');
    }
  }

  void closeScheduleSheet() {
    scheduleSheetVisible.value = false;
    toggleSendButton.value = false;
    scheduleOn = false;
    dateController.clear();
    timeController.clear();
  }

  /// Saves the composer's scheduled draft (message + date/time + repeat)
  /// locally and to the backend drafts table so it shows under the
  /// Drafts tab of the Schedules screen.
  Future<void> saveScheduleAsDraft() async {
    if (pickedDate == null || pickedTime == null) {
      Utils.showGetSnackBar('Pick both Date and Time first');
      return;
    }
    final text = textMessageController.text.trim().isNotEmpty
        ? textMessageController.text.trim()
        : aiMessageController.text.trim();
    if (text.isEmpty) {
      Utils.showGetSnackBar('Type a message first to save as draft');
      return;
    }

    final epoch = (DateTime(
              pickedDate!.year,
              pickedDate!.month,
              pickedDate!.day,
              pickedTime!.hour,
              pickedTime!.minute,
            ).millisecondsSinceEpoch ~/
            1000)
        .toString();

    await birdController.saveDraft({
      'message': text,
      'message_type': '0',
      'room_id': selectedRoom.value,
      'scheduled_at': epoch,
      'interval': selectedInterval.value.toString(),
      'count': _scheduleCountPayload(),
      'category': 'custom',
    });
    closeScheduleSheet();
  }

  void _safePopRoute() {
    if (scheduleSheetVisible.value) {
      closeScheduleSheet();
      return;
    }
    final navigator = Get.key.currentState;
    if (navigator?.canPop() ?? false) {
      navigator!.pop();
    }
  }

  /// Opens the "Message Scheduled!" confirmation sheet after a successful
  /// schedule from the chat composer.
  void _showScheduleConfirmation(Messages message) {
    try {
      Get.bottomSheet(
        ScheduleConfirmationSheet(message: message),
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
      );
    } catch (_) {}
  }

  /// Cancels a schedule directly from the chat bubble menu — hits the
  /// backend, flips the local bubble to a cancelled state and refreshes the
  /// Schedule tab data.
  Future<void> cancelScheduledMessageFromChat(Messages message) async {
    final messageId = message.mId;
    if (messageId == null) return;
    final data = await MessageApi().cancelScheduledMessage(messageId);
    if (data['status'] == true) {
      message.mStatus = 'cancelled';
      messages.refresh();
      update();
      await birdController.cancelScheduleById(messageId);
    } else {
      Utils.showGetSnackBar('Something went wrong');
    }
  }

  /// Copies the freshest schedule fields (text, time, repeat, status) from
  /// the Schedule tab data onto a chat-bubble message after an edit.
  void syncScheduledMessageFromList(Messages message) {
    final messageId = message.mId;
    if (messageId == null) return;
    final fresh = birdController.allScheduledMessages
        .where((m) => m.mId == messageId)
        .toList();
    if (fresh.isEmpty) return;
    final latest = fresh.first;
    message.mMessage = latest.mMessage;
    message.mScheduledAt = latest.mScheduledAt;
    message.interval = latest.interval;
    message.count = latest.count;
    message.mStatus = latest.mStatus;
    messages.refresh();
    update();
  }

  /// Compresses a picked image according to Media Settings
  /// (autoCompressMedia + mediaCompressionQuality). Falls back to the
  /// original file when compression is disabled or fails.
  Future<File> _maybeCompressImage(File pickedFile) async {
    try {
      final storage = userController.storage;
      if (storage.read('autoCompressMedia') != true) return pickedFile;
      final quality = storage.read('mediaCompressionQuality') ?? 'medium';
      const qualityMap = {'low': 40, 'medium': 60, 'high': 80};
      final q = qualityMap[quality];
      if (q == null) return pickedFile;
      final bytes = await FlutterImageCompress.compressWithFile(
        pickedFile.path,
        quality: q,
      );
      if (bytes == null || bytes.isEmpty) return pickedFile;
      final compressedFile = File(
          '${Directory.systemTemp.path}/hb_compress_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(bytes);
      return compressedFile;
    } catch (_) {
      return pickedFile;
    }
  }

  void pickFile(FileType fileType, int messageType,
      {bool fromScheduleScreen = false}) async {
    FilePickerResult? result = await FilePicker.pickFiles(type: fileType);

    if (result != null) {
      File pickedFile = File(result.files.single.path!);
      if (messageType == 1) {
        pickedFile = await _maybeCompressImage(pickedFile);
      }
      pickedMediaPath.value = pickedFile.path;
      sentFile = await pickedFile.readAsBytes();

      int fileSizeInBytes = await pickedFile.length();

      /// Converting bytes to MB
      double fileSizeInKB = (fileSizeInBytes / 1024).toPrecision(1);
      double fileSizeInMB = (fileSizeInKB / 1024).toPrecision(1);
      String fileSize =
          fileSizeInMB < 1 ? '$fileSizeInKB KB' : '$fileSizeInMB MB';

      if (fromScheduleScreen &&
          (messageType == 1 || messageType == 4 || messageType == 2)) {
        // Stage into composerItems WITHOUT opening the full-screen media
        // composer — the schedule page renders its own inline preview list
        // and sends everything through its single Schedule button.
        _addPickedFiles([
          _PickedFile(
            file: pickedFile,
            name: pickedFile.path.split('/').last,
            type: messageType == 1
                ? ComposerMediaType.image
                : (messageType == 4
                    ? ComposerMediaType.video
                    : ComposerMediaType.document),
          ),
        ], autoOpenComposer: false);
        return;
      }

      if (messageType == 1) {
        Get.to(() => ImagePreviewScreen(
              imageFile: pickedFile,
              isScheduled: fromScheduleScreen,
            ));
      } else if (messageType == 4) {
        Get.to(() => VideoPreviewScreen(
              videoFile: pickedFile,
              isScheduled: fromScheduleScreen,
            ));
      } else if (messageType == 2) {
        Get.to(() => DocumentPreviewScreen(
              fileExtension: pickedFile.path.split('.').last,
              fileSize: fileSize,
              isSchedule: fromScheduleScreen,
            ));
      } else {
        sendMedia(messageType: messageType, isScheduled: fromScheduleScreen);
      }
    }
  }

  void selectScheduleInterval(int value) {
    if (selectedInterval.value == value) {
      selectedInterval.value = 0;
    } else {
      selectedInterval.value = value;
      // A repeat interval implies sending at least once. If the count was
      // still 0 (the Forever checkbox), normalize it so the message doesn't
      // silently repeat forever and the flip counter shows a real number.
      if (scheduleCount.value == 0) scheduleCount.value = 1;
    }
  }

  /// Take a photo with the camera and open the image preview, mirroring the
  /// exact flow used for picking an image from the gallery (messageType 1).
  void pickCamera({bool fromScheduleScreen = false}) async {
    try {
      final XFile? taken = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (taken == null) return;
      File pickedFile = File(taken.path);
      pickedFile = await _maybeCompressImage(pickedFile);

      if (fromScheduleScreen) {
        // Stage into composerItems WITHOUT the direct-send ImagePreviewScreen
        // — the schedule page renders its own inline preview list (with an
        // edit option on image tiles) and only its "Schedule Message" button
        // schedules anything.
        _addPickedFiles([
          _PickedFile(
            file: pickedFile,
            name: pickedFile.path.split('/').last,
            type: ComposerMediaType.image,
          ),
        ], autoOpenComposer: false);
        return;
      }

      pickedMediaPath.value = pickedFile.path;
      sentFile = await pickedFile.readAsBytes();
      Get.to(() => ImagePreviewScreen(
            imageFile: pickedFile,
            isScheduled: fromScheduleScreen,
          ));
    } catch (e) {
      debugPrint('pickCamera error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // MULTI-MEDIA COMPOSER (WhatsApp-style attach → preview → send)
  // ══════════════════════════════════════════════════════════════════

  /// Best-effort file-type guess used when a mixed picker returns files we
  /// cannot tell apart by MIME type only (file_picker gives us an extension).
  ComposerMediaType _classifyByName(String name) {
    final ext = name.split('.').last.toLowerCase();
    const images = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
      'svg',
    };
    const videos = {
      'mp4',
      'mov',
      'm4v',
      'mkv',
      'webm',
      'avi',
      '3gp',
      'wmv',
      'flv',
      'mpeg',
      'mpg',
    };
    if (images.contains(ext)) return ComposerMediaType.image;
    if (videos.contains(ext)) return ComposerMediaType.video;
    return ComposerMediaType.document;
  }

  void _addPickedFiles(List<_PickedFile> picked,
      {bool autoOpenComposer = true}) {
    if (picked.isEmpty) return;
    final millis = DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i < picked.length; i++) {
      composerItems.add(ComposerMediaItem(
        id: 'hb_c_${millis}_$i',
        type: picked[i].type,
        file: picked[i].file,
      ));
    }
    if (autoOpenComposer) openMediaComposer();
  }

  /// Opens the full-screen media composer with whatever items are staged.
  void openMediaComposer() {
    if (composerItems.isEmpty) return;
    if (Get.currentRoute.toLowerCase().contains('mediacomposer')) return;
    Get.to(() => const MediaComposerScreen());
  }

  /// Removes a single staged media item (used by the strip / remove button).
  void removeComposerItem(String id) {
    composerItems.removeWhere((e) => e.id == id);
  }

  /// Clears every staged media item (composer close / cancel / logout).
  void clearComposer() {
    composerItems.clear();
    composerSending.value = false;
    _composerSending = false;
  }

  /// Gallery entry from the attach sheet: multi-select images AND videos.
  ///
  /// On iOS the image_picker gallery supports mixed content natively; on
  /// Android we use file_picker's media mode (system photo grid) so both
  /// images and videos can be picked in one go.
  Future<void> pickGalleryMedia() async {
    if (uploadingFile.value) return;
    try {
      List<_PickedFile> picked;
      if (Platform.isIOS) {
        final List<XFile> xfiles = await _composerPicker.pickMultipleMedia();
        picked = xfiles
            .map((x) => _PickedFile(
                  file: File(x.path),
                  name: x.name,
                  type: _classifyByName(x.name),
                ))
            .toList();
      } else {
        final FilePickerResult? result = await FilePicker.pickFiles(
          type: FileType.media,
          allowMultiple: true,
        );
        if (result == null) return;
        picked = result.files
            .where((f) => f.path != null)
            .map((f) => _PickedFile(
                  file: File(f.path!),
                  name: f.name,
                  type: _classifyByName(f.name),
                ))
            .toList();
      }
      _addPickedFiles(picked);
    } catch (e) {
      debugPrint('pickGalleryMedia error: $e');
      Utils.showGetSnackBar('Could not open the gallery. Please try again.');
    }
  }

  /// Requests camera access before launching the camera intent. The manifest
  /// declares CAMERA, so Android enforces the runtime grant; shows a branded
  /// message when denied or permanently blocked.
  Future<bool> _ensureCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    final PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      Utils.showGetSnackBar(
          'Camera access is blocked. Enable it in your app settings.');
    } else {
      Utils.showGetSnackBar(
          'Camera permission is required to take photos and videos.');
    }
    return false;
  }

  /// Camera entry from the attach sheet / gallery toolbar: photo lands in
  /// the composer instead of the legacy single-preview screen.
  Future<void> pickCameraComposer() async {
    if (uploadingFile.value) return;
    if (!await _ensureCameraPermission()) return;
    try {
      final XFile? taken = await _composerPicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (taken == null) return;
      _addPickedFiles([
        _PickedFile(
          file: File(taken.path),
          name: taken.name,
          type: ComposerMediaType.image,
        ),
      ]);
    } catch (e) {
      debugPrint('pickCameraComposer error: $e');
      Utils.showGetSnackBar('Could not open the camera. Please try again.');
    }
  }

  /// Camera video: a short clip lands in the composer.
  Future<void> pickCameraVideoComposer() async {
    if (uploadingFile.value) return;
    if (!await _ensureCameraPermission()) return;
    try {
      final XFile? taken = await _composerPicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (taken == null) return;
      _addPickedFiles([
        _PickedFile(
          file: File(taken.path),
          name: taken.name,
          type: ComposerMediaType.video,
        ),
      ]);
    } catch (e) {
      debugPrint('pickCameraVideoComposer error: $e');
      Utils.showGetSnackBar('Could not open the camera. Please try again.');
    }
  }

  /// Documents entry from the attach sheet: multi-select any file type.
  Future<void> pickDocuments() async {
    if (uploadingFile.value) return;
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );
      if (result == null) return;
      final picked = result.files
          .where((f) => f.path != null)
          .map((f) => _PickedFile(
                file: File(f.path!),
                name: f.name,
                type: ComposerMediaType.document,
              ))
          .toList();
      _addPickedFiles(picked);
    } catch (e) {
      debugPrint('pickDocuments error: $e');
      Utils.showGetSnackBar(
          'Could not open the file picker. Please try again.');
    }
  }

  /// "Add photos" inside the composer (images-only gallery grid).
  Future<void> addComposerPhotos() async {
    try {
      final List<XFile> xfiles =
          await _composerPicker.pickMultiImage(imageQuality: 95);
      _addPickedFiles(xfiles
          .map((x) => _PickedFile(
                file: File(x.path),
                name: x.name,
                type: ComposerMediaType.image,
              ))
          .toList());
    } catch (e) {
      debugPrint('addComposerPhotos error: $e');
      Utils.showGetSnackBar('Could not open the gallery. Please try again.');
    }
  }

  /// "Add videos" inside the composer (videos-only, multi-select).
  Future<void> addComposerVideos() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );
      if (result == null) return;
      final picked = result.files
          .where((f) => f.path != null)
          .map((f) => _PickedFile(
                file: File(f.path!),
                name: f.name,
                type: ComposerMediaType.video,
              ))
          .toList();
      _addPickedFiles(picked);
    } catch (e) {
      debugPrint('addComposerVideos error: $e');
      Utils.showGetSnackBar('Could not open the gallery. Please try again.');
    }
  }

  /// Sends the whole staged batch through the SAME pipeline as the legacy
  /// single-media send (multipart POST to /message/send-message + socket
  /// 'message' event), one item per request, sequentially.
  ///
  /// Reuses MessageApi.sendFormData and the exact success handling from
  /// [sendMedia] so messages, media storage, local DB and thread-list
  /// refresh stay consistent with single-media sends.
  Future<void> sendComposerMedia({bool isScheduled = false}) async {
    if (_composerSending) return; // duplicate-send protection
    if (composerItems.isEmpty) return;

    // Schedule-mode detection mirrors sendMedia: a composer opened from a
    // schedule surface (ScheduleScreen / chat schedule panel) schedules its
    // media against the picked date+time instead of sending it immediately.
    final bool schedulingMedia =
        isScheduled || scheduleOn || isScheduledMessage.value == '1';
    if (schedulingMedia) {
      if (pickedDate == null || pickedTime == null) {
        Utils.showGetSnackBar('Pick both Date and Time for Scheduling');
        return;
      }
      final DateTime scheduledWhen = DateTime(
        pickedDate!.year,
        pickedDate!.month,
        pickedDate!.day,
        pickedTime!.hour,
        pickedTime!.minute,
      );
      if (DateTime.now().isAfter(scheduledWhen)) {
        Utils.showGetSnackBar(
            'You picked time that has been already passed. Please pick future date and time.',
            duration: 5);
        pickedDate = null;
        pickedTime = null;
        dateController.clear();
        timeController.clear();
        isScheduledMessage.value = '0';
        return;
      }
      scheduledMessageDateTime = scheduledWhen;
      isScheduledMessage.value = '1';
    }

    _composerSending = true;
    composerSending.value = true;
    uploadingFile.value = true;

    try {
      for (final item in List<ComposerMediaItem>.from(composerItems)) {
        final int index = composerItems.indexWhere((e) => e.id == item.id);
        if (index < 0) continue; // removed while the batch was sending

        final ComposerMediaItem current = composerItems[index];
        final int messageType = current.isVideo ? 4 : (current.isImage ? 1 : 2);
        current.state = ComposerSendState.sending;
        current.progress = 0;
        composerItems.refresh();

        try {
          File toSend = current.file;
          if (current.isImage && !composerHdQuality.value) {
            toSend = await _maybeCompressImage(current.file);
          }

          final Dio.FormData data = Dio.FormData.fromMap({
            'message': current.caption.trim(),
            'room_id': selectedRoom.value,
            'message_type': messageType.toString(),
            'is_scheduled': schedulingMedia ? '1' : isScheduledMessage.value,
            'scheduled_at': schedulingMedia
                ? AppHelper.convertScheduledTimeToEpoch(
                        scheduledMessageDateTime ?? DateTime.now())
                    .toString()
                : '0',
            'me': true,
            'receiver_id': selectedContactId.value,
            'm_interval': selectedInterval.value.toString(),
            'm_count': _scheduleCountPayload(),
            'm_replied_on': repliedOnId,
            'media_file': await Dio.MultipartFile.fromFile(
              toSend.path,
              filename: toSend.path.split('/').last,
            ),
          });

          final StreamSubscription<double>? progressSub =
              birdController.uploadValue.listen((v) {
            current.progress = v.clamp(0.0, 1.0);
            composerItems.refresh();
          });

          final MessageModel? message =
              await MessageApi().sendFormData(formData: data);
          await progressSub?.cancel();
          birdController.uploadValue.value = 0.0;

          if (message?.status ?? false) {
            if (message?.msg == null) {
              current.state = ComposerSendState.failed;
              composerItems.refresh();
              Utils.showGetSnackBar('Failed to send. Please try again.');
              break;
            }
            final Messages m = message!.msg!;
            selectedRoom.value = m.mRoomId!;
            socket.emit('message', m.toJson());
            if (schedulingMedia) {
              await birdController.getScheduledMessages();
            } else {
              messages.insert(0, m);
              if (m.mMedia != null) {
                try {
                  final Uint8List bytes = await current.file.readAsBytes();
                  saveMediaInDeviceDirectory(messageType.toString(), m.mId!,
                      m.mRoomId!, bytes, m.mMedia!);
                } catch (_) {
                  // non-fatal: message was sent; local media file failed to
                  // buffer (e.g. file deleted while queued).
                }
              }
              LocalDatabase.saveMessage([m]);
              homeController.fetchSingleChats();
            }
            current.state = ComposerSendState.done;
            current.progress = 1;
            composerItems.refresh();
          } else {
            current.state = ComposerSendState.failed;
            composerItems.refresh();
            Utils.showGetSnackBar(
                message?.message ?? 'Failed to send. Please try again.');
            break;
          }
        } catch (e) {
          current.state = ComposerSendState.failed;
          composerItems.refresh();
          debugPrint('sendComposerMedia item error: $e');
          Utils.showGetSnackBar('Could not send. Please try again.');
          break;
        }
      }
    } finally {
      _composerSending = false;
      composerSending.value = false;
      uploadingFile.value = false;

      _resortMessages();

      final bool stillPending =
          composerItems.any((e) => e.state != ComposerSendState.done);
      if (!stillPending) {
        composerItems.clear();
        if (Get.currentRoute.toLowerCase().contains('mediacomposer')) {
          Get.back();
        }
        if (schedulingMedia) {
          dateController.clear();
          timeController.clear();
          isScheduledMessage.value = '0';
          if (scheduleSheetVisible.value) {
            closeScheduleSheet();
          }
          Utils.showGetSnackBar('Message Scheduled Successfully');
        }
      } else {
        Utils.showGetSnackBar(
            'Some media could not be sent. The rest has been delivered.');
      }
    }
  }

  /// Shares the user's current location as a chat message. Lightweight
  /// implementation that reuses the existing text-send pipeline (encryption,
  /// socket + optimistic UI) by composing a location string with a Maps link.
  Future<void> sendLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Utils.showGetSnackBar(
            'Location services are disabled. Please enable them.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Utils.showGetSnackBar(
            'Location permission is required to share your location.');
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      textMessageController.text =
          'My Location\nhttps://maps.google.com/?q=$lat,$lng';
      sendMessage();
    } catch (e) {
      debugPrint('sendLocation error: $e');
      Utils.showGetSnackBar('Could not fetch your location. Please try again.');
    }
  }

  void setRecordingQuality(String quality) {
    recordingQuality.value = quality;
  }

  Future<void> forwardMedia({
    required String messageIds,
    required String roomIds,
  }) async {
    try {
      await MessageApi().forwardMessage(
        messageIds: [messageIds],
        roomIds: [roomIds],
      );
    } catch (e) {
      // Silently handle
    }
  }

  /// Recording Audio Section
  void recordAudio() async {
    if (isRecording.value || _recorderStarting) return;
    _recorderStarting = true;
    try {
      final recorder = AudioRecorder();
      try {
        await _recorder?.dispose();
      } catch (_) {}
      _recorder = recorder;

      if (await Permission.microphone.request().isGranted) {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate();
        }
        audioIconSize.value = 45.0;
        isRecording.value = true;
        isRecordingPaused.value = false;
        recordingDuration.value = 0;
        var dir = await getApplicationDocumentsDirectory();

        final quality = recordingQuality.value;
        int bitRate;
        switch (quality) {
          case 'low':
            bitRate = 32000;
            break;
          case 'high':
            bitRate = 128000;
            break;
          default:
            bitRate = 64000;
        }
        final config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: bitRate,
          sampleRate: quality == 'low' ? 22050 : 44100,
          numChannels: 1,
        );
        final recordingPath =
            '${dir.path}/humming-bird-${DateTime.now().millisecondsSinceEpoch}.m4a';
        print('Recording path: $recordingPath');

        final staleFile = File(recordingPath);
        if (staleFile.existsSync()) {
          try {
            staleFile.deleteSync();
          } catch (e) {
            print('Failed to delete stale recording file: $e');
          }
        }
        await recorder.start(config, path: recordingPath);
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          recordingDuration.value++;
        });
      }
    } catch (e, stackTrace) {
      print('Failed to start recording: $e');
      print('Stack trace: $stackTrace');
      isRecording.value = false;
      isRecordingPaused.value = false;
      audioIconSize.value = 35.0;
      try {
        await _recorder?.dispose();
      } catch (_) {}
      _recorder = null;
      Utils.showGetSnackBar('Could not start recording. Please try again.');
    } finally {
      _recorderStarting = false;
    }
  }

  void pauseRecording() async {
    _recordingTimer?.cancel();
    isRecordingPaused.value = true;
    try {
      await _recorder?.pause();
    } catch (_) {}
  }

  void resumeRecording() async {
    isRecordingPaused.value = false;
    try {
      await _recorder?.resume();
    } catch (_) {}
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      recordingDuration.value++;
    });
  }

  void cancelRecording() async {
    _recordingTimer?.cancel();
    recordingDuration.value = 0;
    isRecording.value = false;
    isRecordingPaused.value = false;
    audioIconSize.value = 35.0;
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      try {
        await recorder.stop();
      } catch (_) {}
      try {
        await recorder.dispose();
      } catch (_) {}
    }
  }

  void saveAudio({bool fromScheduleScreen = false}) async {
    _recordingTimer?.cancel();
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate();
    }
    audioIconSize.value = 35.0;
    isRecording.value = false;
    isRecordingPaused.value = false;
    recordingDuration.value = 0;

    final recorder = _recorder;
    _recorder = null;
    String? audioPath;
    if (recorder != null) {
      try {
        audioPath = await recorder.stop();
      } catch (_) {}
      try {
        await recorder.dispose();
      } catch (_) {}
    }

    if (audioPath != null) {
      try {
        final File file = File(audioPath);
        if (!file.existsSync() || file.lengthSync() == 0) {
          Utils.showGetSnackBar('Recording was empty. Please try again.');
          return;
        }
        pickedMediaPath.value = audioPath;
        sentFile = await file.readAsBytes();
        uploadMedia = false;
        sendMedia(messageType: 3, isScheduled: fromScheduleScreen);
      } catch (_) {
        Utils.showGetSnackBar('Failed to save recording. Please try again.');
      }
    } else {
      Utils.showGetSnackBar('Failed to finish recording. Please try again.');
    }
  }

  void disposeRecorder() async {
    _recordingTimer?.cancel();
    isRecording.value = false;
    isRecordingPaused.value = false;
    recordingDuration.value = 0;
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      try {
        await recorder.stop();
      } catch (_) {}
      try {
        await recorder.dispose();
      } catch (_) {}
    }
  }

  /// Play pause audio section
  void _bindAudioStreams() {
    if (_audioStreamsBound) return;
    _audioStreamsBound = true;

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) audioDuration = duration;
    });

    _audioPlayer.positionStream.listen((position) {
      audioPosition = position;
      final duration = audioDuration;
      if (duration == null || duration.inMilliseconds <= 0) return;
      final progress = position.inMilliseconds / duration.inMilliseconds;
      audioCurrentPosition.value = progress;
      audioCurrentPositionString.value = AppHelper.formatDuration(position);
      if (_activeAudioId != null) {
        isAudioPlayingMap[_activeAudioId] = progress;
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == justAudio.ProcessingState.completed) {
        audioPosition = null;
        audioCurrentPosition.value = 0.0;
        audioCurrentPositionString.value = '00:00';
        final key = _activeAudioKey;
        if (key != null) {
          isAudioPlayingMap[key] = false;
        }
      }
    });
  }

  Future<void> playRecordedAudio(UniqueKey audioKey, String audioId) async {
    Uint8List? audioBytes = await getMediaFromPath(audioId);
    if (audioBytes == null) {
      Utils.showGetSnackBar('Audio file not found');
      return;
    }

    _activeAudioId = audioId;
    _activeAudioKey = audioKey;
    _bindAudioStreams();

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    isAudioPlayingMap.clear();
    audioCurrentPosition.value = 0.0;
    audioCurrentPositionString.value = '00:00';

    try {
      await _audioPlayer.setAudioSource(AudioService(bytes: audioBytes));
      await _audioPlayer.setSpeed(playbackSpeed);
      isAudioPlayingMap[audioKey] = true;
      await _audioPlayer.play();
    } catch (_) {
      isAudioPlayingMap[audioKey] = false;
      Utils.showGetSnackBar('Failed to play audio. Please try again.');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed = speed;
    try {
      await _audioPlayer.setSpeed(speed);
    } catch (_) {}
  }

  void pauseAudio(UniqueKey audioKey) async {
    isAudioPlayingMap[audioKey] = false;
    _audioPlayer.pause();
  }

  void seekAudio(double position) {
    _audioPlayer.seek(Duration(milliseconds: position.round()));
  }

  Future<File?> initVideo(
      String mediaId, String mediaUrl, UniqueKey videoKey) async {
    Uint8List? media = await getMediaFromPath(mediaId);

    if (media != null) {
      File videoFile = await getFileFromBytes(media, mediaId);
      return videoFile;
    }
    return null;
  }

  void playPauseVideo(UniqueKey videoKey) {
    if (isVideoPlayingMap[videoKey] == true) {
      isVideoPlayingMap[videoKey] = false;
    } else {
      isVideoPlayingMap[videoKey] = true;
    }
  }

  Future<File> getFileFromBytes(Uint8List data, String mediaId) async {
    Directory dir = await getApplicationDocumentsDirectory();
    File file = File('${dir.path}/humming-videos-$mediaId');
    await file.writeAsBytes(data);
    return file;
  }

  MediaModel? getMedia(String mediaId) {
    return LocalDatabase.getMedia(mediaId);
  }

  /// Returns true if two messages are of different dates.
  bool compareMessagesDates(int index) {
    String currentMessageDate =
        AppHelper.getDate(_displayDateFor(message: messages[index]));
    String anotherMessageDate = AppHelper.getDate(
        _displayDateFor(message: messages[index == 0 ? index : index - 1]));
    return currentMessageDate != anotherMessageDate;
  }

  /// Date (yyyy-MM-dd) used to bucket messages — the actual send date.
  String _displayDateFor({required Messages message}) {
    final epoch = message.sentEpochSeconds;
    if (epoch > 0) return AppHelper.getFormattedDateFromEpoch(epoch);
    final createdAt = message.mCreatedAt;
    if (createdAt != null && createdAt.isNotEmpty) return createdAt;
    return '';
  }

  /// For displaying timestamp (Today, Yesterday or date) in messages ui.
  /// Returns timestamp widget and true or false,
  /// returns true only if all messages are of same date.
  (bool, Widget) showTimestamp(int index) {
    Widget timeStampContainer;
    /*
    1. Checking if message contains mCreatedAt date.
    2. Comparing dates between 2 messages -
    First one is with index and second one is with index + 1 or index - 1 if message is last in the messages list
     */
    if (messages[index].mCreatedAt != null &&
        AppHelper.getDate(messages[index].mCreatedAt) !=
            AppHelper.getDate(
                messages[index == 0 ? index : index - 1].mCreatedAt)) {
      timeStampContainer = _buildDateSeparator(messages[index]);
      return (false, timeStampContainer);
    } else if (messages[index].mCreatedAt != null &&
        messages.isNotEmpty &&
        checkIfAllMessagesOfSameDate()) {
      timeStampContainer = _buildDateSeparator(messages[index]);
      return (true, timeStampContainer);
    } else {
      return (false, const SizedBox.shrink());
    }
  }

  Widget _buildDateSeparator(Messages message) {
    final isDark = Get.isDarkMode;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl.w, vertical: AppSpacing.sm.h),
      margin: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [CustomColor.kDarkFloating, CustomColor.kDarkSurface2]
              : [
                  CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                  CustomColor.kPrimaryMedium.withValues(alpha: 0.04)
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
        border: Border.all(
          color: isDark
              ? CustomColor.kDarkBorder
              : CustomColor.kPrimaryColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.1)
                : CustomColor.kPrimaryColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        AppHelper.getTimeStamp(_displayDateFor(message: message)),
        style: AppTextStyles.labelSm.copyWith(
          fontSize: 11.sp,
          color: isDark
              ? CustomColor.kTextOnDarkSecondary
              : CustomColor.kTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Returns true if all messages are of same date else false.
  bool checkIfAllMessagesOfSameDate() {
    bool isSameDate = true;
    for (int i = 0; i < messages.length; i++) {
      // Comparing two message if their date are not equal
      if (AppHelper.getDate(messages[i].mCreatedAt) !=
          AppHelper.getDate(messages[i == 0 ? i : i - 1].mCreatedAt)) {
        isSameDate = false;
        break;
      }
    }
    return isSameDate;
  }

  void shareContacts() {
    if (shareContactsList.isNotEmpty) {
      for (final contact in shareContactsList) {
        sendMessage(contactShare: true, contacts: jsonEncode(contact));
      }
      _safePopRoute();
    } else {
      Utils.showToast('Please select contacts to share', Toast.LENGTH_SHORT);
    }
  }

  void selectSharingContact(Map<String, dynamic> data) {
    if (shareContactsList.isEmpty) {
      shareContactsList.add(data);
    } else {
      if (!shareContactsList
          .any((contact) => contact['number'] == data['number'])) {
        shareContactsList.add(data);
      } else {
        shareContactsList.removeWhere((e) => e['number'] == data['number']);
      }
    }
  }

  (bool, Messages) checkIfSelectedMessageIsScheduled() {
    if (messageSelectorMap.keys.isEmpty) return (false, Messages());
    String mId = messageSelectorMap.keys.toList()[0];
    Messages msg =
        messages.firstWhere((e) => e.mId == mId, orElse: () => Messages());
    if (msg.mIsScheduled == '1') {
      return (true, msg);
    } else {
      return (false, msg);
    }
  }

  Messages? getMessageBeingEdited() {
    String? mId = editingMessageId;
    if (mId == null || mId.isEmpty) {
      if (messageSelectorMap.isEmpty) return null;
      mId = (messageSelectorMap.keys.toList()[0] ?? '').toString();
    }
    if (mId.isEmpty) return null;
    final idx = messages.indexWhere((e) => e.mId == mId);
    if (idx < 0) return null;
    return messages[idx];
  }

  bool get canEditSelectedMessage {
    if (messageSelectorMap.length != 1) return false;
    final mId = (messageSelectorMap.keys.toList()[0] ?? '').toString();
    if (mId.isEmpty || !youMessages.contains(mId)) return false;
    final idx = messages.indexWhere((e) => e.mId == mId);
    if (idx < 0) return false;
    return messages[idx].mMessageType == '0';
  }

  void editMessageFromChatScreen({Messages? message}) {
    final msg = message ?? getMessageBeingEdited();
    if (msg == null || msg.mId == null) {
      Utils.showGetSnackBar('This message can no longer be edited.');
      return;
    }
    textMessageController.text = msg.mMessage ?? '';
    editingMessageId = msg.mId;
    editingMessage = true;
    messageSelectorMap.value = {msg.mId!: true};
    if (msg.me == true && !youMessages.contains(msg.mId)) {
      youMessages.add(msg.mId!);
    }
    update();
  }

  void editMessageFromScheduleScreen(
      Messages currentMessage, String newMessage) {
    _safePopRoute();
    currentMessage.mMessage = newMessage;
    updateMessage(currentMessage, false, false, newMessage: newMessage);
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 1 - ADVANCED CHAT FEATURES
  // ══════════════════════════════════════════════════════════════════

  // --- Reply (enhanced) ---
  void replyToMessage(Messages message) {
    isReplyOnMessage.value = true;
    repliedMessage = message;
    repliedOnId = message.mId;
  }

  // --- Forward ---
  Future<void> forwardMessages(
      List<String> messageIds, List<String> roomIds) async {
    if (messageIds.isEmpty || roomIds.isEmpty) return;
    showLoading.value = true;
    try {
      final res = await MessageApi().forwardMessage(
        messageIds: messageIds,
        roomIds: roomIds,
      );
      if (res['status'] == true) {
        _recordRecentForwards(roomIds);
        Utils.showGetSnackBar('Messages forwarded successfully');
      } else {
        Utils.showGetSnackBar('Failed to forward messages');
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to forward messages');
    } finally {
      showLoading.value = false;
      messageSelectorMap.clear();
      isMultiSelectMode.value = false;
    }
  }

  /// Keeps a short recency-ordered list of rooms the user has forwarded to,
  /// used to rank the Quick-Forward suggestions. Stored in GetStorage.
  void _recordRecentForwards(List<String> roomIds) {
    try {
      final storage = GetStorage();
      final recent = List<String>.from(
          storage.read<List>('recent_forward_room_ids') ?? []);
      for (final roomId in roomIds) {
        recent.remove(roomId);
        recent.insert(0, roomId);
      }
      if (recent.length > 8) {
        recent.removeRange(8, recent.length);
      }
      storage.write('recent_forward_room_ids', recent);
    } catch (_) {}
  }

  // --- Edit (enhanced) ---
  void editMessage(Messages message, String newText) {
    if (newText.trim().isEmpty || newText == message.mMessage) return;
    updateMessage(message, false, false, newMessage: newText.trim());
    editingMessage = false;
    editingMessageId = null;
    textMessageController.clear();
  }

  // --- Emoji Reactions ---
  int _reactionRevision = 0;

  /// Mirrors the backend toggle locally: removes [userId] from every emoji
  /// list, then adds to [emoji] if the user wasn't already on it.
  String _toggleReactionsLocally(String? current, String emoji, String userId) {
    Map<String, dynamic> map = {};
    if (current != null && current.isNotEmpty) {
      try {
        final decoded = jsonDecode(current);
        if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    String? existing;
    final normalized = <String, dynamic>{};
    map.forEach((key, value) {
      final list = (value is List)
          ? List<String>.from(value.map((e) => e.toString()))
          : <String>[];
      final before = list.length;
      list.removeWhere((e) => e == userId);
      if (list.length != before) existing = key;
      if (list.isNotEmpty) normalized[key] = list;
    });
    if (existing != emoji) {
      final list = normalized[emoji] is List
          ? List<String>.from(normalized[emoji] as List)
          : <String>[];
      if (!list.contains(userId)) list.add(userId);
      normalized[emoji] = list;
    }
    return jsonEncode(normalized);
  }

  /// Per-message pulse counters that drive the Instagram-style floating
  /// reaction animation on the chat bubbles (bumped by socket events).
  final Map<String, RxInt> reactionPulses = {};

  /// Per-message burst counters for the big center pop played on double-tap.
  final Map<String, RxInt> reactionBursts = {};

  void _pulseReaction(String messageId) {
    final rx = reactionPulses.putIfAbsent(messageId, () => 0.obs);
    rx.value++;
  }

  void burstReaction(String messageId) {
    final rx = reactionBursts.putIfAbsent(messageId, () => 0.obs);
    rx.value++;
  }

  void _applyReactionsToMessage(String messageId, String? reactionsStr) {
    try {
      final idx = messages.indexWhere((m) => m.mId == messageId);
      if (idx < 0) return;
      if (reactionsStr == null) {
        messages.refresh();
        return;
      }
      final decoded = jsonDecode(reactionsStr);
      if (decoded is Map && decoded.isEmpty) {
        messages[idx].mReactions = null;
      } else if (decoded is Map || decoded is List) {
        messages[idx].mReactions = reactionsStr;
      } else {
        return;
      }
      LocalDatabase.saveMessage([messages[idx]]);
      // Refresh the RxList (not just update()) so the message-list Obx in
      // chat_screen.dart — which listens to `messages` — rebuilds instantly.
      messages.refresh();
    } catch (_) {}
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    final idx = messages.indexWhere((m) => m.mId == messageId);
    if (idx < 0) return;

    // Optimistic update: show the reaction instantly, sync in the background.
    final previous = messages[idx].mReactions;
    final optimistic =
        _toggleReactionsLocally(previous, emoji, userController.userId);
    _applyReactionsToMessage(messageId, optimistic);
    final revision = ++_reactionRevision;

    try {
      final res = await MessageApi().toggleReaction(messageId, emoji);
      if (revision != _reactionRevision)
        return; // a newer toggle owns the state
      if (res['status'] == true) {
        final updated = res['msg']['m_reactions']?.toString();
        _applyReactionsToMessage(messageId, updated);
        if (socket.connected) {
          socket.emit('message-reaction', {
            'm_id': messageId,
            'm_room_id': selectedRoom.value,
            'm_reactions': updated ?? '{}',
          });
        }
      } else {
        _applyReactionsToMessage(messageId, previous);
        Utils.showGetSnackBar(res['message']?.toString() ?? 'Failed to react');
      }
    } catch (e) {
      if (revision != _reactionRevision) return;
      _applyReactionsToMessage(messageId, previous);
      Utils.showGetSnackBar('Failed to react. Please try again.');
    }
  }

  // --- Pin / Unpin ---
  Future<void> pinMessage(Messages message) async {
    try {
      final res = await MessageApi().pinMessage(message.mId!);
      if (res['status'] == true) {
        message.mPinned = '1';
        message.mPinnedAt = DateTime.now().millisecondsSinceEpoch.toString();
        LocalDatabase.saveMessage([message]);
        if (!pinnedMessages.any((m) => m.mId == message.mId)) {
          pinnedMessages.insert(0, message);
        }
        showPinnedBar.value = pinnedMessages.isNotEmpty;
        update();
        if (socket.connected) {
          socket.emit('message-pin', {
            'm_id': message.mId,
            'm_room_id': selectedRoom.value,
            'pinned': '1',
          });
        }
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to pin message');
    }
  }

  Future<void> unpinMessage(String messageId) async {
    try {
      final res = await MessageApi().unpinMessage(messageId);
      if (res['status'] == true) {
        final idx = messages.indexWhere((m) => m.mId == messageId);
        if (idx >= 0) {
          messages[idx].mPinned = '0';
          messages[idx].mPinnedAt = null;
          LocalDatabase.saveMessage([messages[idx]]);
        }
        pinnedMessages.removeWhere((m) => m.mId == messageId);
        showPinnedBar.value = pinnedMessages.isNotEmpty;
        update();
        if (socket.connected) {
          socket.emit('message-pin', {
            'm_id': messageId,
            'm_room_id': selectedRoom.value,
            'pinned': '0',
          });
        }
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to unpin message');
    }
  }

  Future<void> loadPinnedMessages(String roomId) async {
    try {
      final res = await MessageApi().fetchPinnedMessages(roomId);
      if (res['status'] == true && res['data'] != null) {
        pinnedMessages.value =
            (res['data'] as List).map((e) => Messages.fromJson(e)).toList();
        showPinnedBar.value = pinnedMessages.isNotEmpty;
      }
    } catch (e) {
      // Silent
    }
  }

  // --- Star / Unstar ---
  Future<void> starMessage(String messageId) async {
    try {
      final res = await MessageApi().starMessage(messageId);
      if (res['status'] == true) {
        final idx = messages.indexWhere((m) => m.mId == messageId);
        if (idx >= 0) {
          messages[idx].mStarred = '1';
          LocalDatabase.saveMessage([messages[idx]]);
          starredMessages.add(messages[idx]);
          update();
        }
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to star message');
    }
  }

  Future<void> unstarMessage(String messageId) async {
    try {
      final res = await MessageApi().unstarMessage(messageId);
      if (res['status'] == true) {
        final idx = messages.indexWhere((m) => m.mId == messageId);
        if (idx >= 0) {
          messages[idx].mStarred = '0';
          LocalDatabase.saveMessage([messages[idx]]);
        }
        starredMessages.removeWhere((m) => m.mId == messageId);
        update();
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to unstar message');
    }
  }

  Future<void> loadStarredMessages() async {
    try {
      final res = await MessageApi().fetchStarredMessages();
      if (res['status'] == true && res['data'] != null) {
        starredMessages.value =
            (res['data'] as List).map((e) => Messages.fromJson(e)).toList();
      }
    } catch (e) {
      // Silent
    }
  }

  // --- Multi Select (enhanced) ---
  void toggleMultiSelectMode() {
    isMultiSelectMode.value = !isMultiSelectMode.value;
    if (!isMultiSelectMode.value) {
      messageSelectorMap.clear();
      youMessages = [];
    }
  }

  void deleteSelectedMessages(bool deleteForEveryone) {
    if (messageSelectorMap.isEmpty) return;
    final ids = messageSelectorMap.keys.cast<String>().toList();
    deleteMessage(ids, deleteForEveryone ? '1' : '0', false);
    isMultiSelectMode.value = false;
  }

  void forwardSelectedMessages() {
    if (messageSelectorMap.isEmpty) return;
    final ids = messageSelectorMap.keys.cast<String>().toList();
    Get.to(() => ForwardMessageScreen(messageIds: ids));
  }

  void starSelectedMessages() {
    if (messageSelectorMap.isEmpty) return;
    messageSelectorMap.keys.forEach((id) {
      starMessage(id.toString());
    });
    messageSelectorMap.clear();
    isMultiSelectMode.value = false;
  }

  void pinSelectedMessages() {
    if (messageSelectorMap.isEmpty) return;
    messageSelectorMap.keys.forEach((id) {
      final idx = messages.indexWhere((m) => m.mId == id);
      if (idx >= 0) pinMessage(messages[idx]);
    });
    messageSelectorMap.clear();
    isMultiSelectMode.value = false;
  }

  // --- Message Info ---
  Future<Map<String, dynamic>> getMessageInfo(String messageId) async {
    try {
      return await MessageApi().fetchMessageInfo(messageId);
    } catch (e) {
      return {'status': false, 'message': 'Failed to fetch message info'};
    }
  }

  // --- In-Chat Search ---
  void searchInChat(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    final lower = query.toLowerCase();
    searchResults.value = messages.where((m) {
      if (m.mMessageType == '0' &&
          (m.mMessage?.toLowerCase().contains(lower) ?? false)) {
        return true;
      }
      if (lower == 'photo' && m.mMessageType == '1') return true;
      if (lower == 'video' && m.mMessageType == '4') return true;
      if (lower == 'audio' && m.mMessageType == '3') return true;
      if (lower == 'document' && m.mMessageType == '2') return true;
      if (lower == 'link' &&
          m.mMessageType == '0' &&
          (m.mIsLink == '1' || LinkPreviewService.isLink(m.mMessage))) {
        return true;
      }
      return false;
    }).toList();
  }

  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
    searchController.clear();
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 4 - AI COMMUNICATION SUITE
  // ══════════════════════════════════════════════════════════════════

  // --- 1. AI Reply Suggestions ---
  RxList<String> aiReplySuggestions = <String>[].obs;

  Future<void> loadReplySuggestions(String message) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.aiReplySuggestions,
        data: {'message': message},
      );
      if (res['status'] == true && res['data'] != null) {
        aiReplySuggestions.value = List<String>.from(res['data']);
        return;
      }
    } catch (_) {}
    _localReplySuggestions(message);
  }

  void _localReplySuggestions(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      aiReplySuggestions.value = ['Hey! How are you?', 'Hello!', 'Hi there!'];
    } else if (lower.contains('how are you')) {
      aiReplySuggestions.value = [
        'I\'m good, thanks!',
        'Doing great!',
        'All good!'
      ];
    } else if (lower.contains('thank')) {
      aiReplySuggestions.value = [
        'You\'re welcome!',
        'Anytime!',
        'Glad to help!'
      ];
    } else if (lower.contains('bye') || lower.contains('goodbye')) {
      aiReplySuggestions.value = ['Goodbye!', 'See you later!', 'Take care!'];
    } else if (lower.contains('?')) {
      aiReplySuggestions.value = [
        'Sure!',
        'Let me check...',
        'Yes, definitely!'
      ];
    } else if (lower.contains('meeting') || lower.contains('meet')) {
      aiReplySuggestions.value = [
        'Sure, let\'s meet!',
        'When works for you?',
        'I\'ll be there!'
      ];
    } else if (lower.contains('sorry')) {
      aiReplySuggestions.value = [
        'No problem!',
        'It\'s okay!',
        'Don\'t worry about it!'
      ];
    } else {
      aiReplySuggestions.value = ['Okay!', 'Got it!', 'Sounds good!'];
    }
  }

  void clearReplySuggestions() {
    aiReplySuggestions.value = [];
  }

  // --- 2. Message Categorization ---
  RxMap<String, String> messageCategories = <String, String>{}.obs;

  Future<void> categorizeMessage(String message, {String? messageId}) async {
    final id = messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final res = await ApiService().post(
        path: Endpoints.aiCategorize,
        data: {'message': message},
      );
      if (res['status'] == true && res['data'] != null) {
        messageCategories[id] = res['data'].toString();
        return;
      }
    } catch (_) {}
    messageCategories[id] = _localCategorize(message);
  }

  String _localCategorize(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('hey')) return 'greeting';
    if (lower.contains('?') &&
        (lower.contains('what') ||
            lower.contains('where') ||
            lower.contains('when') ||
            lower.contains('why') ||
            lower.contains('how'))) return 'question';
    if (lower.contains('urgent') ||
        lower.contains('asap') ||
        lower.contains('emergency')) return 'urgent';
    if (lower.contains('thank')) return 'appreciation';
    if (lower.contains('meeting') ||
        lower.contains('meet') ||
        lower.contains('schedule')) return 'meeting';
    if (lower.contains('love') ||
        lower.contains('miss') ||
        lower.contains('dear')) return 'personal';
    if (lower.contains('promotion') ||
        lower.contains('offer') ||
        lower.contains('discount')) return 'promotional';
    if (lower.contains('photo') ||
        lower.contains('image') ||
        lower.contains('picture')) return 'media';
    return 'general';
  }

  String getMessageCategory(String messageId) {
    return messageCategories[messageId] ?? '';
  }

  // --- 3. Message Summaries ---
  RxString conversationSummary = ''.obs;
  RxBool isGeneratingSummary = false.obs;

  Future<void> generateSummary() async {
    if (messages.isEmpty) {
      conversationSummary.value = 'No messages to summarize.';
      return;
    }
    isGeneratingSummary.value = true;
    final conversationText = messages
        .where(
            (m) => m.mMessageType == '0' && (m.mMessage?.isNotEmpty ?? false))
        .take(50)
        .map((m) => m.mMessage)
        .join('\n');
    try {
      final res = await ApiService().post(
        path: Endpoints.aiSummarize,
        data: {'conversation': conversationText},
      );
      if (res['status'] == true && res['data'] != null) {
        conversationSummary.value = res['data'].toString();
        isGeneratingSummary.value = false;
        return;
      }
    } catch (_) {}
    conversationSummary.value = _localSummarize(conversationText);
    isGeneratingSummary.value = false;
  }

  String _localSummarize(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final totalMsg = lines.length;
    if (totalMsg <= 2) {
      return lines.isNotEmpty ? lines.first : 'Conversation has started.';
    }
    final topics = <String>[];
    final lower = text.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi'))
      topics.add('greetings');
    if (lower.contains('?')) topics.add('questions');
    if (lower.contains('meeting')) topics.add('meeting planning');
    if (lower.contains('thank')) topics.add('appreciation');
    if (lower.contains('urgent')) topics.add('urgent matters');
    if (topics.isEmpty) topics.add('general chat');
    return 'This conversation has $totalMsg messages covering ${topics.join(', ')}.';
  }

  // --- 4. Sentiment Analysis ---
  RxMap<String, String> messageSentiments = <String, String>{}.obs;

  Future<void> analyzeSentiment(String message, {String? messageId}) async {
    final id = messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final res = await ApiService().post(
        path: Endpoints.aiSentiment,
        data: {'message': message},
      );
      if (res['status'] == true && res['data'] != null) {
        messageSentiments[id] = res['data'].toString();
        return;
      }
    } catch (_) {}
    messageSentiments[id] = _localSentiment(message);
  }

  String _localSentiment(String message) {
    final lower = message.toLowerCase();
    final positiveWords = [
      'happy',
      'love',
      'great',
      'excellent',
      'amazing',
      'wonderful',
      'fantastic',
      'good',
      'nice',
      'thank',
      'awesome',
      'beautiful',
      'joy',
      'perfect',
      'best',
      'glad',
      'pleased'
    ];
    final negativeWords = [
      'sad',
      'angry',
      'upset',
      'bad',
      'terrible',
      'horrible',
      'awful',
      'hate',
      'sorry',
      'miss',
      'hurt',
      'pain',
      'cry',
      'worst',
      'ugly',
      'fail',
      'boring'
    ];
    int positiveScore = 0;
    int negativeScore = 0;
    for (final word in positiveWords) {
      if (lower.contains(word)) positiveScore++;
    }
    for (final word in negativeWords) {
      if (lower.contains(word)) negativeScore++;
    }
    if (positiveScore > negativeScore) return 'positive';
    if (negativeScore > positiveScore) return 'negative';
    final excitedWords = ['!', 'wow', 'omg', 'amazing', 'incredible'];
    for (final word in excitedWords) {
      if (lower.contains(word)) return 'exciting';
    }
    if (lower.contains('love') || lower.contains('heart')) return 'love';
    return 'neutral';
  }

  String getMessageSentiment(String messageId) {
    return messageSentiments[messageId] ?? '';
  }

  // --- 5. Translation ---
  RxMap<String, Map<String, String>> messageTranslations =
      <String, Map<String, String>>{}.obs;

  Future<void> translateMessage(String message, String targetLang,
      {String? messageId}) async {
    final id = messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final res = await ApiService().post(
        path: Endpoints.aiTranslate,
        data: {'message': message, 'target_lang': targetLang},
      );
      if (res['status'] == true && res['data'] != null) {
        final existing =
            Map<String, String>.from(messageTranslations[id] ?? {});
        existing[targetLang] = res['data'].toString();
        messageTranslations[id] = existing;
        return;
      }
    } catch (_) {}
  }

  // --- 6. Spam Detection ---
  RxMap<String, bool> spamMessages = <String, bool>{}.obs;

  Future<bool> checkSpam(String message, {String? messageId}) async {
    final id = messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final res = await ApiService().post(
        path: Endpoints.aiDetectSpam,
        data: {'message': message},
      );
      final isSpam = res['data'] == true || res['data'] == 'true';
      spamMessages[id] = isSpam;
      return isSpam;
    } catch (_) {
      final isSpam = _localCheckSpam(message);
      spamMessages[id] = isSpam;
      return isSpam;
    }
  }

  bool _localCheckSpam(String message) {
    final lower = message.toLowerCase();
    final spamKeywords = [
      'buy now',
      'click here',
      'free money',
      'win prize',
      'lottery',
      'congratulations you won',
      'act now',
      'limited offer',
      '100% free',
      'earn money',
      'cash reward',
      'urgent response',
      'verify account',
      'password reset',
      'bank details',
      'credit card'
    ];
    if (message.contains('http://') || message.contains('https://')) {
      if (RegExp(r'http[s]?://\S+').allMatches(message).length > 2) return true;
    }
    int spamScore = 0;
    for (final keyword in spamKeywords) {
      if (lower.contains(keyword)) spamScore++;
    }
    return spamScore >= 2;
  }

  bool isMessageSpam(String messageId) {
    return spamMessages[messageId] ?? false;
  }

  // --- 7. Sender Name Lookup (for AI features) ---
  String getSenderName(String? senderId) {
    return _senderDisplayName(senderId ?? '') ?? 'Unknown';
  }

  // --- 8. Chat Context (for summary button etc) ---
  int getMessageCount() => messages.length;
}

/// A lightweight picked-file record used only while assembling composer
/// slots — not a model, not persisted.
class _PickedFile {
  _PickedFile({
    required this.file,
    required this.type,
    required this.name,
  });

  final File file;
  final ComposerMediaType type;
  final String name;
}
