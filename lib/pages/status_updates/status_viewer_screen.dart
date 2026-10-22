import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as Dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/apis/message_api.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/status_v2/status_seen_sheet.dart';
import 'package:humming_bird/pages/status_v2/status_reactions_sheet.dart';
import 'package:humming_bird/pages/status_v2/status_replies_sheet.dart';
import 'package:humming_bird/pages/status_v2/status_share_sheet.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class StatusViewerScreen extends StatefulWidget {
  final List<FriendUpdate> updates;
  final int initialIndex;
  final List<StatusModel>? myStatuses;
  final Map<String, dynamic>? myUser;

  /// All story groups (one per author) so navigation can flow from the last
  /// story of one contact to the first story of the next contact.
  final List<List<FriendUpdate>> allGroups;
  final int initialGroupIndex;

  const StatusViewerScreen({
    super.key,
    required this.updates,
    this.initialIndex = 0,
    this.myStatuses,
    this.myUser,
    this.allGroups = const [],
    this.initialGroupIndex = 0,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _ViewerItem {
  final StatusModel status;
  final Map<String, dynamic>? author;
  final bool isMine;

  /// Current user's reaction on this status as reported by the feed
  /// (`my_reaction`), used to seed the ❤️ like button highlight.
  final String? myReaction;
  _ViewerItem({
    required this.status,
    this.author,
    required this.isMine,
    this.myReaction,
  });
}

class _StatusViewerScreenState extends State<StatusViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  final List<AnimationController> _progressControllers = [];
  Timer? _progressTimer;
  bool _isPaused = false;
  static const _statusDuration = Duration(seconds: 5);

  late StatusController _statusController;
  late ChatController _chatController;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _showReplyInput = false;
  bool _showReactions = false;

  static const _emojis = ['❤️', '😂', '😍', '😮', '😢', '🔥', '👍'];

  late final List<_ViewerItem> _items;
  VideoPlayerController? _videoController;
  bool _videoBuffering = false;
  String? _videoStatusId;
  bool _isClosing = false;
  int _groupIndex = 0;

  String? get _myId {
    try {
      final uid = Get.find<UserController>().user?.userId?.toString();
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}
    return _statusController.myUserId;
  }

  _ViewerItem? get _currentItem =>
      _items.isEmpty ? null : _items[_currentIndex];

  /// True while a page animation is in flight — guards the progress timer
  /// against double-advancing and skipping stories.
  bool _pageAnimating = false;

  /// True while the reply input or the reactions row is open. Auto-advance is
  /// paused then, so a reply/reaction always targets the story the user was
  /// viewing when they opened the input.
  bool _interactionOpen = false;

  /// Exact story index captured when the reply input / reactions row opened.
  int? _replyTargetIndex;
  int? _reactionTargetIndex;
  bool _sendingReply = false;
  bool _pickingMediaReply = false;
  bool _recordingVoice = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
  AudioRecorder? _voiceRecorder;

  /// Live reaction state keyed by status id — updated from the react() response
  /// so the ❤️ like button highlights/unhighlights instantly (feed seeding via
  /// `_ViewerItem.myReaction`).
  final Map<String, String> _liveReactions = {};

  /// The current user's reaction for [item]: feed value until the user reacts
  /// in this session, then the live value from the last response.
  String? _myReactionFor(_ViewerItem item) {
    final statusId = item.status.suId;
    if (statusId != null) {
      final live = _liveReactions[statusId];
      if (live != null) return live;
    }
    return item.myReaction;
  }

  @override
  void initState() {
    super.initState();
    _statusController = Get.find();
    _chatController = Get.find();
    _buildItems();
    _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _initProgress();
    _recordView();
    _setupVideo();
  }

  void _buildItems() {
    if (widget.myStatuses != null && widget.myStatuses!.isNotEmpty) {
      _items = widget.myStatuses!
          .where((s) => !s.isExpired)
          .map((s) => _ViewerItem(
                status: s,
                author: widget.myUser,
                isMine: true,
              ))
          .toList();
    } else if (widget.allGroups.isNotEmpty) {
      _groupIndex =
          widget.initialGroupIndex.clamp(0, widget.allGroups.length - 1);
      _items = widget.allGroups[_groupIndex]
          .where((u) => u.update?.isExpired != true)
          .map((u) => _ViewerItem(
                status: u.update!,
                author: u.author,
                isMine: false,
                myReaction: u.myReaction,
              ))
          .toList();
    } else {
      _items = widget.updates
          .where((u) => u.update?.isExpired != true)
          .map((u) => _ViewerItem(
                status: u.update!,
                author: u.author,
                isMine: false,
                myReaction: u.myReaction,
              ))
          .toList();
    }
    if (_items.isEmpty)
      _items.add(_ViewerItem(status: StatusModel(suContent: ''), isMine: true));
  }

  /// Rebuilds the viewer around another contact's story group (used when the
  /// user navigates past the first/last story of the current contact).
  void _switchGroup(int newGroup, int pageIndex) {
    if (_isClosing || !mounted) return;
    _groupIndex = newGroup;
    for (final c in _progressControllers) {
      c.dispose();
    }
    _progressControllers.clear();
    _items
      ..clear()
      ..addAll(widget.allGroups[newGroup].map((u) => _ViewerItem(
            status: u.update!,
            author: u.author,
            isMine: false,
            myReaction: u.myReaction,
          )));
    if (_items.isEmpty) {
      _closeViewer();
      return;
    }
    for (final _ in _items) {
      _progressControllers.add(AnimationController(
        vsync: this,
        duration: _statusDuration,
      ));
    }
    _disposeVideo();
    setState(() {
      _showReplyInput = false;
      _showReactions = false;
      _interactionOpen = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isClosing) return;
      _currentIndex = pageIndex.clamp(0, _items.length - 1);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
      // jumpToPage fires onPageChanged, which restarts the progress timer,
      // records the view and sets up the video for the new current story.
    });
  }

  void _initProgress() {
    for (final _ in _items) {
      _progressControllers.add(AnimationController(
        vsync: this,
        duration: _statusDuration,
      ));
    }
    if (_progressControllers.isNotEmpty) {
      _progressControllers[_currentIndex].forward();
      _startProgressTimer();
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted &&
          !_isClosing &&
          !_isPaused &&
          !_interactionOpen &&
          !_pageAnimating &&
          _progressControllers[_currentIndex].isCompleted) {
        _goNext();
      }
    });
  }

  /// Pops the viewer exactly once. Guards against the progress timer firing
  /// again during the pop animation and popping the route below (which made
  /// the screen go blank and the next back press close the app).
  void _closeViewer() {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    _progressTimer?.cancel();
    Navigator.of(context).maybePop();
  }

  void _animateTo(int index) {
    if (_pageAnimating || !_pageController.hasClients) return;
    _pageAnimating = true;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goNext() {
    if (_isClosing || _interactionOpen || _pageAnimating) return;
    if (_currentIndex < _items.length - 1) {
      _animateTo(_currentIndex + 1);
    } else if (widget.allGroups.isNotEmpty &&
        _groupIndex < widget.allGroups.length - 1) {
      // Last story of this contact → advance to the next contact's stories.
      _switchGroup(_groupIndex + 1, 0);
    } else {
      _closeViewer();
    }
  }

  void _goPrev() {
    if (_isClosing || _interactionOpen || _pageAnimating) return;
    if (_currentIndex > 0) {
      _animateTo(_currentIndex - 1);
    } else if (widget.allGroups.isNotEmpty && _groupIndex > 0) {
      // First story of this contact → jump back to the previous contact's last story.
      final prevGroup = widget.allGroups[_groupIndex - 1];
      if (prevGroup.isEmpty) {
        _closeViewer();
      } else {
        _switchGroup(_groupIndex - 1, prevGroup.length - 1);
      }
    } else {
      _closeViewer();
    }
  }

  Future<void> _setupVideo() async {
    final item = _items[_currentIndex];
    final mediaType = item.status.suMediaType;
    final url = item.status.suMediaUrl;
    if (mediaType != 'video' || url == null || url.isEmpty) return;
    if (_videoStatusId == item.status.suId) return;

    _videoStatusId = item.status.suId;
    final old = _videoController;
    _videoController = null;
    if (mounted) setState(() {});
    await old?.dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse('${Endpoints.mediaBaseUrl}$url'),
    );
    _videoController = controller;
    try {
      await controller.initialize();
      controller.addListener(_onVideoUpdate);
      await controller.play();
      if (mounted && !_isPaused) {
        setState(() {});
        _progressControllers[_currentIndex]
          ..duration = controller.value.duration
          ..value = 0
          ..forward();
      }
    } catch (_) {
      _videoController = null;
    }
    if (mounted) setState(() {});
  }

  void _onVideoUpdate() {
    final v = _videoController?.value;
    if (v == null) return;
    final buffering = v.isBuffering;
    if (buffering != _videoBuffering && mounted) {
      setState(() => _videoBuffering = buffering);
    }
    if (buffering && !_isPaused) {
      _progressControllers[_currentIndex].stop();
    } else if (!buffering &&
        !_isPaused &&
        !_progressControllers[_currentIndex].isAnimating) {
      if (!_progressControllers[_currentIndex].isCompleted) {
        _progressControllers[_currentIndex].forward();
      }
    }
  }

  void _disposeVideo() {
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();
    _videoController = null;
    _videoStatusId = null;
    _videoBuffering = false;
  }

  void _recordView() {
    final status = _items[_currentIndex].status;
    if (status.suId != null && !_items[_currentIndex].isMine) {
      _statusController.viewUpdate(status.suId!);
    }
  }

  void _onPageChanged(int index) {
    _pageAnimating = false;
    _progressControllers[_currentIndex].reset();
    _currentIndex = index;
    _progressControllers[_currentIndex]
      ..duration = _statusDuration
      ..forward();
    _disposeVideo();
    _recordView();
    _setupVideo();
    if (_showReplyInput || _showReactions) {
      // The user swiped away from the story while the reply input or the
      // reactions row was open — close it and resume auto-advance.
      _replyTargetIndex = null;
      _reactionTargetIndex = null;
      setState(() {
        _showReplyInput = false;
        _showReactions = false;
        _interactionOpen = false;
      });
    } else {
      setState(() {});
    }
  }

  void _togglePause() {
    if (_interactionOpen) return;
    if (_isPaused) {
      _progressControllers[_currentIndex].forward();
      _videoController?.play();
    } else {
      _progressControllers[_currentIndex].stop();
      _videoController?.pause();
    }
    setState(() => _isPaused = !_isPaused);
  }

  // ── Reply / reaction interaction locking ───────────────────────────────
  // The target story is captured when the input opens and auto-advance is
  // paused, so a reply/reaction always lands on the exact story the user was
  // viewing — not on whichever story happens to be current at send time.

  void _openReplyInput() {
    if (_isClosing) return;
    _replyTargetIndex = _currentIndex;
    setState(() {
      _showReplyInput = true;
      _interactionOpen = true;
    });
    _progressControllers[_currentIndex].stop();
    _videoController?.pause();
  }

  void _closeReplyInput({bool resume = true}) {
    setState(() {
      _showReplyInput = false;
      _interactionOpen = false;
    });
    _replyTargetIndex = null;
    if (resume && !_isPaused && !_isClosing) {
      _progressControllers[_currentIndex].forward();
      _videoController?.play();
    }
  }

  void _openReactionsRow() {
    if (_isClosing) return;
    _reactionTargetIndex = _currentIndex;
    setState(() {
      _showReactions = true;
      _interactionOpen = true;
    });
    _progressControllers[_currentIndex].stop();
    _videoController?.pause();
  }

  void _closeReactionsRow({bool resume = true}) {
    setState(() {
      _showReactions = false;
      _interactionOpen = false;
    });
    _reactionTargetIndex = null;
    if (resume && !_isPaused && !_isClosing) {
      _progressControllers[_currentIndex].forward();
      _videoController?.play();
    }
  }

  void _toggleReactions() {
    if (_showReactions) {
      _closeReactionsRow();
    } else {
      _openReactionsRow();
    }
  }

  // Quick reply → status reply + real chat message to the author (if a 1:1 room exists)
  Future<void> _sendReply() async {
    if (_sendingReply) return; // double-tap / double-submit guard
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final targetIndex = _replyTargetIndex ?? _currentIndex;
    final item = _items[targetIndex];
    if (item.status.suId == null) return;
    _sendingReply = true;
    try {
      if (!item.isMine) {
        await _statusController.replyToStatus(item.status.suId!, text);
        _sendAsChatMessage(item, text);
      }
      _replyController.clear();
      _replyFocus.unfocus();
      _closeReplyInput();
    } finally {
      _sendingReply = false;
    }
  }

  /// Finds the 1:1 room with [authorId]. When it doesn't exist yet (status
  /// replies must land in a chat even without a prior conversation), creates
  /// a pending room via the author's phone number and refreshes the chat list.
  Future<dynamic> _resolveOrCreateRoom(String authorId) async {
    final homeController = Get.find<HomeController>();
    dynamic findRoom() {
      final rooms = homeController.singleChatsList;
      for (final room in rooms) {
        List ids = [];
        try {
          ids = jsonDecode(room.rUsers ?? '[]') as List;
        } catch (_) {}
        if (ids.map((e) => e.toString()).contains(_myId) &&
            ids.map((e) => e.toString()).contains(authorId)) {
          return room;
        }
      }
      return null;
    }

    final existing = findRoom();
    if (existing != null) return existing;

    try {
      final author = _currentItem?.author;
      final phone = author?['user_mobile_num']?.toString();
      if (phone == null || phone.isEmpty) return null;
      final room = await RoomApi().createPendingRoom(phone);
      if (room == null) return null;
      try {
        // async fire-and-forget — void-returning on purpose
        // ignore: unawaited_futures
        homeController.fetchSingleChats();
      } catch (_) {}
      return findRoom();
    } catch (_) {
      return null;
    }
  }

  /// Sends a story-reply chat message to the story owner's conversation.
  /// The message carries `m_story_ref` (exact storyId + owner + preview data)
  /// so the receiver's chat renders the WhatsApp-style story preview and the
  /// reply/reaction is never confused with any other story.
  Future<void> _sendAsChatMessage(_ViewerItem item, String text,
      {String replyType = 'reply', String? reaction}) async {
    try {
      final myId = _myId;
      final authorId = item.author?['user_id']?.toString();
      if (myId == null || authorId == null) return;

      final matchingRoom = await _resolveOrCreateRoom(authorId);
      if (matchingRoom == null) return;

      final messageData = <String, dynamic>{
        'm_room_id': matchingRoom.rId,
        'm_message_type': '0',
        'm_message': EncryptionHelper().encryptMessage(text),
        'm_sender_id': myId,
        'm_is_scheduled': '0',
        'm_scheduled_at': '0',
        'm_replied_on': '',
        'me': true,
        'receiver_id': authorId,
        'm_read_status': '0',
        'm_interval': '0',
        'm_count': 1,
      };
      final status = item.status;
      if (status.suId != null && status.suId!.isNotEmpty) {
        messageData['m_story_ref'] = jsonEncode(_buildStoryRef(item, text,
            replyType: replyType, reaction: reaction));
      }
      final res = await MessageApi().sendMessage(messageData);
      final model = res?.msg;
      if (res?.status == true && model != null) {
        if (kDebugMode) {
          debugPrint('STATUS-REPLY-TRACE → sent chat message '
              'storyRef=${model.mStoryRef}');
        }
        _chatController.socket.emit('message', model.toJson());
        _chatController.addSentMessage(model);
      }
    } catch (_) {}
  }

  /// Builds the plain-JSON story reference attached to story-reply chat
  /// messages: exact story id + owner + preview data (media, caption, colors).
  Map<String, dynamic> _buildStoryRef(_ViewerItem item, String text,
      {String replyType = 'reply', String? reaction}) {
    final status = item.status;
    return {
      'story_id': status.suId ?? '',
      'story_owner_id': item.author?['user_id']?.toString() ?? '',
      'story_owner_name': _authorName(item),
      'reply_type': replyType,
      'message': text,
      'reaction': reaction ?? '',
      'media_url': status.suMediaUrl ?? '',
      'media_type': status.suMediaType ?? 'text',
      'content': status.suContent ?? '',
      'caption': status.suCaption ?? '',
      'bg_color': status.suBgColor ?? '',
      'text_color': status.suTextColor ?? '',
      'created_at': status.suCreatedAt ?? '',
    };
  }

  Future<void> _sendReaction(String emoji, {int? targetIndex}) async {
    final target = targetIndex ?? _reactionTargetIndex ?? _currentIndex;
    final item = _items[target];
    if (item.status.suId == null || item.isMine) return;
    final statusId = item.status.suId!;
    final res = await _statusController.reactToStatus(statusId, emoji);
    if (res != null && res['status'] == true) {
      final removed = res['removed'] == true;
      if (mounted) {
        setState(() {
          if (removed) {
            _liveReactions.remove(statusId);
          } else {
            _liveReactions[statusId] = emoji;
          }
        });
      }
      if (!removed) {
        // WhatsApp-style: the reaction also lands in the owner's chat as a
        // story-reply message pinned to this exact story.
        _sendAsChatMessage(item, emoji, replyType: 'reaction', reaction: emoji);
      }
    }
  }

  /// Quick ❤️/emoji tap from the bottom bar — targets the story currently on
  /// screen (captured at tap time), no interaction pause needed.
  void _quickReact(String emoji) {
    if (_isClosing) return;
    _sendReaction(emoji, targetIndex: _currentIndex);
  }

  void _openSeenSheet() {
    final status = _items[_currentIndex].status;
    if (status.suId == null || _isClosing) return;
    final wasPaused = _isPaused;
    _isPaused = true;
    _progressControllers[_currentIndex].stop();
    Get.bottomSheet(
      StatusSeenSheet(status: status),
      backgroundColor: CustomColor.kTextOnDark,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
    ).whenComplete(() {
      if (mounted && !wasPaused && !_isClosing) {
        _isPaused = false;
        _progressControllers[_currentIndex].forward();
      }
    });
  }

  Future<void> _deleteOwnStatus() async {
    final status = _items[_currentIndex].status;
    if (status.suId == null) return;
    final wasPaused = _isPaused;
    // Pause story auto-advance while the dialog is open so the progress
    // timer can't pop the dialog (or the viewer) mid-confirmation.
    _isPaused = true;
    _progressControllers[_currentIndex].stop();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete Status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Delete this status?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child:
                Text('Delete', style: TextStyle(color: CustomColor.kDangerRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      if (!wasPaused && mounted && !_isClosing) {
        _isPaused = false;
        _progressControllers[_currentIndex].forward();
      }
      return;
    }
    final ok = await _statusController.deleteUpdate(status.suId!);
    if (!ok) {
      if (!wasPaused && mounted && !_isClosing) {
        _isPaused = false;
        _progressControllers[_currentIndex].forward();
      }
      return;
    }
    if (!mounted) return;
    final removedIndex = _currentIndex;
    if (removedIndex < _items.length) {
      _items.removeAt(removedIndex);
      try {
        _progressControllers[removedIndex].dispose();
      } catch (_) {}
      _progressControllers.removeAt(removedIndex);
    }
    if (_items.isEmpty) {
      _closeViewer();
      return;
    }
    final nextIndex = removedIndex.clamp(0, _items.length - 1);
    _currentIndex = nextIndex;
    _isPaused = wasPaused;
    if (!wasPaused) {
      _progressControllers[nextIndex]
        ..reset()
        ..forward();
    }
    _disposeVideo();
    setState(() {});
    _recordView();
    _setupVideo();
  }

  Future<void> _reportStatus() async {
    final status = _items[_currentIndex].status;
    if (status.suId == null) return;
    final reasonCtrl = TextEditingController();
    final reason = await Get.dialog<String>(
      AlertDialog(
        title: Text('Report Status',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Reason for reporting...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: null),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: reasonCtrl.text.trim()),
            child:
                Text('Report', style: TextStyle(color: CustomColor.kDangerRed)),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (reason == null || reason.isEmpty) return;
    final ok = await _statusController.reportStatus(status.suId!, reason);
    CustomSnackbar.success(
        title: ok ? 'Reported' : 'Failed',
        message: ok
            ? 'Thanks — we will review this status'
            : 'Could not submit report');
  }

  Future<void> _muteUser() async {
    final item = _items[_currentIndex];
    final authorId = item.author?['user_id']?.toString();
    if (authorId == null) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Mute User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Mute status updates from this user?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Mute'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _statusController.muteUser(authorId);
      CustomSnackbar.success(
          title: 'Muted', message: 'Status updates from this user are muted');
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _voiceTimer?.cancel();
    final recorder = _voiceRecorder;
    _voiceRecorder = null;
    if (recorder != null) {
      try {
        recorder.stop();
      } catch (_) {}
      try {
        recorder.dispose();
      } catch (_) {}
    }
    _pageController.dispose();
    for (final c in _progressControllers) {
      c.dispose();
    }
    _disposeVideo();
    _replyController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTapZone,
        onLongPress: _togglePause,
        onLongPressUp: () {
          if (_isPaused) _togglePause();
        },
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity;
          if (v == null) return;
          if (v > 500) {
            _closeViewer();
          } else if (v < -500 &&
              _items[_currentIndex].isMine &&
              !_interactionOpen) {
            _openSeenSheet();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _items.length,
              itemBuilder: (ctx, i) => _buildStatusContent(i),
            ),
            if (_videoBuffering)
              const Center(
                child:
                    CircularProgressIndicator(color: CustomColor.kTextOnDark),
              ),
            Positioned(
              top: 0.h,
              left: 0.w,
              right: 0.w,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                      child: Row(
                        children: List.generate(_items.length, (i) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.w),
                              child: AnimatedBuilder(
                                animation: _progressControllers[i],
                                builder: (ctx, _) => ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs.r),
                                  child: LinearProgressIndicator(
                                    value: _progressControllers[i].value,
                                    backgroundColor: CustomColor.kOverlay24,
                                    valueColor: const AlwaysStoppedAnimation(
                                        CustomColor.kTextOnDark),
                                    minHeight: 3.h,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _recordingVoice
                          ? Row(
                              children: [
                                IconButton(
                                  tooltip: 'Cancel voice reply',
                                  icon: const Icon(Icons.close,
                                      color: CustomColor.kOverlay54),
                                  onPressed: _cancelVoiceReply,
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10.r,
                                        height: 10.r,
                                        decoration: BoxDecoration(
                                          color: CustomColor.kDangerRed,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Recording ${_formatVoiceTime()}',
                                        style: AppTextStyles.bodyMd.copyWith(
                                            color: CustomColor.kTextOnDark),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.stop_rounded,
                                      color: CustomColor.kDangerRed,
                                      size: 26.r),
                                  tooltip: 'Stop & send',
                                  onPressed: _stopVoiceReply,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                CircleAvatar(
                                  radius: 18.r,
                                  backgroundImage: _buildAvatar(
                                      _items[_currentIndex].author),
                                  onBackgroundImageError: _buildAvatar(
                                              _items[_currentIndex].author) !=
                                          null
                                      ? (_, __) {}
                                      : null,
                                  child: Icon(Icons.person,
                                      size: 18.r,
                                      color: CustomColor.kOverlay54),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _authorName(_items[_currentIndex]),
                                        style: AppTextStyles.titleSm.copyWith(
                                            color: CustomColor.kTextOnDark),
                                      ),
                                      Text(
                                        _formatTime(_items[_currentIndex]
                                            .status
                                            .suCreatedAt),
                                        style: AppTextStyles.caption.copyWith(
                                            color: CustomColor.kOverlay60),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_items[_currentIndex].isMine &&
                                    _items[_currentIndex].status.viewCount !=
                                        null)
                                  GestureDetector(
                                    onTap: _openSeenSheet,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 8.w),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: CustomColor.kTextOnDark
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.xxxl.r),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.visibility_rounded,
                                                size: 12.r,
                                                color: CustomColor.kTextOnDark),
                                            SizedBox(width: 4.w),
                                            Text(
                                              '${_items[_currentIndex].status.viewCount}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      color: CustomColor
                                                          .kTextOnDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_items[_currentIndex].isMine &&
                                    _items[_currentIndex]
                                            .status
                                            .reactionCount !=
                                        null)
                                  GestureDetector(
                                    onTap: () => Get.to(() =>
                                        StatusReactionsSheet(
                                            statusId: _items[_currentIndex]
                                                .status
                                                .suId!)),
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 8.w),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: CustomColor.kTextOnDark
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.xxxl.r),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.emoji_emotions_outlined,
                                                size: 12.r,
                                                color: CustomColor.kTextOnDark),
                                            SizedBox(width: 4.w),
                                            Text(
                                              '${_items[_currentIndex].status.reactionCount}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      color: CustomColor
                                                          .kTextOnDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_items[_currentIndex].isMine)
                                  GestureDetector(
                                    onTap: () => Get.to(() =>
                                        StatusRepliesSheet(
                                            statusId: _items[_currentIndex]
                                                .status
                                                .suId!)),
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 8.w),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: (_items[_currentIndex]
                                                          .status
                                                          .replyCount ??
                                                      0) >
                                                  0
                                              ? CustomColor.kDangerRed
                                                  .withValues(alpha: 0.85)
                                              : CustomColor.kTextOnDark
                                                  .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.xxxl.r),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.reply_rounded,
                                                size: 12.r,
                                                color: CustomColor.kTextOnDark),
                                            SizedBox(width: 4.w),
                                            Text(
                                              '${_items[_currentIndex].status.replyCount ?? 0}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      color: CustomColor
                                                          .kTextOnDark),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  tooltip: 'Close',
                                  icon: const Icon(Icons.close,
                                      color: CustomColor.kTextOnDark),
                                  onPressed: _closeViewer,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0.h,
              left: 0.w,
              right: 0.w,
              child: SafeArea(
                child: _showReplyInput
                    ? _buildReplyInput()
                    : _buildBottomActions(),
              ),
            ),
            if (_showReactions)
              Positioned(
                bottom: 80.h,
                left: 0.w,
                right: 0.w,
                child: _buildReactionsRow(),
              ),
          ],
        ),
      ),
    );
  }

  void _handleTapZone(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;
    if (dx < width * 0.33) {
      _goPrev();
    } else if (dx > width * 0.66) {
      _goNext();
    } else {
      _togglePause();
    }
  }

  String _authorName(_ViewerItem item) {
    if (item.isMine) return 'My Status';
    final a = item.author;
    final name = a != null
        ? '${a['user_first_name'] ?? ''} ${a['user_last_name'] ?? ''}'.trim()
        : '';
    return name.isNotEmpty ? name : (a?['user_name']?.toString() ?? 'User');
  }

  Widget _buildStatusContent(int index) {
    final item = _items[index];
    final update = item.status;
    final mediaType = update.suMediaType;

    if (mediaType == 'video') {
      return _buildVideoContent(update);
    }
    if (mediaType == 'image' && (update.suMediaUrl?.isNotEmpty ?? false)) {
      return _buildImageContent(update);
    }
    return _buildTextContent(update);
  }

  Widget _buildImageContent(StatusModel update) {
    return InteractiveViewer(
      child: SizedBox.expand(
        child: CachedNetworkImage(
          imageUrl: '${Endpoints.mediaBaseUrl}${update.suMediaUrl}',
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: CustomColor.kTextOnDark),
          ),
          errorWidget: (_, __, ___) => _buildTextContent(update),
        ),
      ),
    );
  }

  Widget _buildVideoContent(StatusModel update) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: CustomColor.kTextOnDark),
      );
    }
    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Color _parseHexColor(String? hex, {Color fallback = Colors.black}) {
    if (hex == null || hex.isEmpty) return fallback;
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  TextStyle _textStyleFor(StatusModel update) {
    final baseColor =
        _parseHexColor(update.suTextColor, fallback: CustomColor.kTextOnDark);
    final base =
        AppTextStyles.headingXl.copyWith(color: baseColor, height: 1.5);
    switch (update.suFontStyle) {
      case 'lora':
        return GoogleFonts.lora(
          fontSize: 22.sp,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.5,
        );
      case 'dancing':
        return GoogleFonts.dancingScript(
          fontSize: 26.sp,
          fontWeight: FontWeight.w500,
          color: baseColor,
          height: 1.4,
        );
      case 'pacifico':
        return GoogleFonts.pacifico(
          fontSize: 22.sp,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.5,
        );
      case 'space':
        return GoogleFonts.spaceGrotesk(
          fontSize: 22.sp,
          fontWeight: FontWeight.w500,
          color: baseColor,
          height: 1.5,
        );
      case 'poppins_bold':
        return base.copyWith(fontWeight: FontWeight.w700);
      default:
        return base;
    }
  }

  Widget _buildTextContent(StatusModel update) {
    final bgColor = _parseHexColor(update.suBgColor, fallback: Colors.black);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor,
      padding: EdgeInsets.all(32.w),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            update.suContent ?? '',
            style: _textStyleFor(update),
            textAlign: TextAlign.center,
          ),
          if ((update.suLocation?.isNotEmpty ?? false) ||
              (update.suLink?.isNotEmpty ?? false)) ...[
            SizedBox(height: 24.h),
            if (update.suLocation?.isNotEmpty ?? false)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 14.r, color: CustomColor.kOverlay70),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        update.suLocation!,
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kOverlay70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (update.suLink?.isNotEmpty ?? false)
              GestureDetector(
                onTap: () async {
                  final uri = Uri.tryParse(update.suLink!);
                  if (uri != null && uri.hasScheme) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  update.suLink!,
                  style: AppTextStyles.bodySm
                      .copyWith(color: Colors.lightBlueAccent),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final item = _items[_currentIndex];
    if (item.isMine) {
      return _buildOwnStatusActions(item);
    }
    final liked = _myReactionFor(item) == '❤️';
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openReplyInput,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                ),
                child: Text(
                  'Reply to ${_authorName(item)}...',
                  style: AppTextStyles.subtitle
                      .copyWith(color: CustomColor.kOverlay60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Fixed ❤️ like button — toggles like/unlike for THIS story only.
          GestureDetector(
            onTap: () => _quickReact('❤️'),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: liked
                    ? CustomColor.kOverlay30
                    : CustomColor.kTextOnDark.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                '❤️',
                style: TextStyle(
                  fontSize: 20.sp,
                  color: liked
                      ? null
                      : CustomColor.kTextOnDark.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Quick reactions — same as ❤️ but one-shot emoji taps.
          GestureDetector(
            onTap: () => _quickReact('😮'),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text('😮', style: TextStyle(fontSize: 20.sp)),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => _quickReact('😂'),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text('😂', style: TextStyle(fontSize: 20.sp)),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _toggleReactions,
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_emotions_outlined,
                  color: CustomColor.kTextOnDark, size: 22.r),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => Get.dialog(_buildMoreMenu(item)),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.more_horiz_rounded,
                  color: CustomColor.kTextOnDark, size: 22.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnStatusActions(_ViewerItem item) {
    final status = item.status;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (status.viewCount != null)
            _OwnActionChip(
              icon: Icons.visibility_rounded,
              label: 'Views',
              onTap: _openSeenSheet,
            ),
          if (status.reactionCount != null)
            _OwnActionChip(
              icon: Icons.emoji_emotions_rounded,
              label: 'Reactions',
              onTap: () => Get.bottomSheet(
                StatusReactionsSheet(statusId: status.suId!),
                backgroundColor: CustomColor.kTextOnDark,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => _showOwnStatusMenu(item),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.more_vert_rounded,
                  color: CustomColor.kTextOnDark, size: 22.r),
            ),
          ),
        ],
      ),
    );
  }

  void _showOwnStatusMenu(_ViewerItem item) {
    final status = item.status;
    showModalBottomSheet(
      context: context,
      backgroundColor: CustomColor.kInk900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status.replyCount != null)
              ListTile(
                leading: const Icon(Icons.reply_rounded,
                    color: CustomColor.kTextOnDark),
                title: Text('${status.replyCount} replies',
                    style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.bottomSheet(
                    StatusRepliesSheet(statusId: status.suId!),
                    backgroundColor: CustomColor.kTextOnDark,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                  );
                },
              ),
            if (status.suId != null)
              ListTile(
                leading: const Icon(Icons.share_rounded,
                    color: CustomColor.kTextOnDark),
                title: Text('Share',
                    style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _statusController.shareStatus(status.suId!);
                  Get.bottomSheet(
                    StatusShareSheet(status: status),
                    backgroundColor: CustomColor.kTextOnDark,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.archive_rounded,
                  color: CustomColor.kTextOnDark),
              title: Text('Archive',
                  style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
              onTap: () async {
                Navigator.pop(ctx);
                if (status.suId != null) {
                  await _statusController.archiveUpdate(status.suId!, true);
                }
                if (!mounted) return;
                final removedIndex = _currentIndex;
                if (removedIndex < _items.length) {
                  _items.removeAt(removedIndex);
                  try {
                    _progressControllers[removedIndex].dispose();
                  } catch (_) {}
                  _progressControllers.removeAt(removedIndex);
                }
                if (_items.isEmpty) {
                  _closeViewer();
                  return;
                }
                final nextIndex = removedIndex.clamp(0, _items.length - 1);
                _currentIndex = nextIndex;
                _isPaused = false;
                _progressControllers[nextIndex]
                  ..reset()
                  ..forward();
                _disposeVideo();
                setState(() {});
                _recordView();
                _setupVideo();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_rounded, color: CustomColor.kDangerRed),
              title: Text('Delete',
                  style: GoogleFonts.poppins(
                      color: CustomColor.dangerTextFor(Get.isDarkMode))),
              onTap: () {
                Navigator.pop(ctx);
                _deleteOwnStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreMenu(_ViewerItem item) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r)),
      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.report_rounded, color: CustomColor.kDangerRed),
            title: Text('Report',
                style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
            onTap: () {
              Get.back();
              _reportStatus();
            },
          ),
          ListTile(
            leading:
                Icon(Icons.volume_off_rounded, color: CustomColor.kOverlay70),
            title: Text('Mute',
                style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
            onTap: () {
              Get.back();
              _muteUser();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close, color: CustomColor.kOverlay54),
            onPressed: _closeReplyInput,
          ),
          Expanded(
            child: TextField(
              controller: _replyController,
              focusNode: _replyFocus,
              autofocus: true,
              style:
                  AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextOnDark),
              decoration: InputDecoration(
                hintText: 'Reply...',
                hintStyle: GoogleFonts.poppins(
                    color: CustomColor.kTextOnDarkSecondary),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendReply(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined,
                color: CustomColor.kTextOnDark),
            tooltip: 'Camera',
            onPressed: () => _pickMediaReply(ImageSource.camera),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined,
                color: CustomColor.kTextOnDark),
            tooltip: 'Gallery',
            onPressed: () => _pickMediaReply(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: CustomColor.kTextOnDark),
            tooltip: 'More',
            onPressed: _openMediaMoreSheet,
          ),
          IconButton(
            tooltip: 'Send reply',
            icon:
                const Icon(Icons.send_rounded, color: CustomColor.kTextOnDark),
            onPressed: _sendReply,
          ),
        ],
      ),
    );
  }

  /// Extended reply options: video, document, voice note.
  void _openMediaMoreSheet() {
    if (_pickingMediaReply || _recordingVoice) return;
    final targetIndex = _replyTargetIndex ?? _currentIndex;
    final item = _items[targetIndex];
    if (item.status.suId == null || item.isMine) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: CustomColor.kInk900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library_outlined,
                  color: CustomColor.kTextOnDark),
              title: Text('Video',
                  style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideoReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined,
                  color: CustomColor.kTextOnDark),
              title: Text('Document',
                  style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocumentReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic_none_rounded,
                  color: CustomColor.kTextOnDark),
              title: Text('Voice note',
                  style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
              onTap: () {
                Navigator.pop(ctx);
                _startVoiceReply(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideoReply() async {
    if (_pickingMediaReply) return;
    final targetIndex = _replyTargetIndex ?? _currentIndex;
    final item = _items[targetIndex];
    if (item.status.suId == null || item.isMine) return;
    _pickingMediaReply = true;
    try {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked == null) return;
      await _sendMediaChatMessage(item, picked.path,
          caption: _replyController.text.trim(),
          messageType: 4,
          fallback: '📹');
      _replyController.clear();
      _replyFocus.unfocus();
      _closeReplyInput();
    } catch (_) {
    } finally {
      _pickingMediaReply = false;
    }
  }

  Future<void> _pickDocumentReply() async {
    if (_pickingMediaReply) return;
    final targetIndex = _replyTargetIndex ?? _currentIndex;
    final item = _items[targetIndex];
    if (item.status.suId == null || item.isMine) return;
    _pickingMediaReply = true;
    try {
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      await _sendMediaChatMessage(item, path,
          caption: _replyController.text.trim(),
          messageType: 2,
          fallback: '📄');
      _replyController.clear();
      _replyFocus.unfocus();
      _closeReplyInput();
    } catch (_) {
    } finally {
      _pickingMediaReply = false;
    }
  }

  Future<void> _startVoiceReply(_ViewerItem item) async {
    if (_recordingVoice) return;
    try {
      if (!await Permission.microphone.request().isGranted) {
        Utils.showGetSnackBar('Microphone permission required');
        return;
      }
      final recorder = AudioRecorder();
      _voiceRecorder = recorder;
      _voiceSeconds = 0;
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/humming-bird-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
      final stale = File(path);
      if (stale.existsSync()) {
        try {
          stale.deleteSync();
        } catch (_) {}
      }
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path,
      );
      _voiceTimer?.cancel();
      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _voiceSeconds++;
        if (mounted) setState(() {});
      });
      if (mounted) setState(() => _recordingVoice = true);
    } catch (_) {
      Utils.showGetSnackBar('Could not start recording. Please try again.');
    }
  }

  Future<void> _stopVoiceReply() async {
    if (!_recordingVoice) return;
    _voiceTimer?.cancel();
    final recorder = _voiceRecorder;
    _voiceRecorder = null;
    if (mounted) setState(() => _recordingVoice = false);
    String? audioPath;
    if (recorder != null) {
      try {
        audioPath = await recorder.stop();
      } catch (_) {}
      try {
        await recorder.dispose();
      } catch (_) {}
    }
    if (audioPath == null || !File(audioPath).existsSync()) return;
    final targetIndex = _replyTargetIndex ?? _currentIndex;
    final item = _items[targetIndex];
    if (item.status.suId == null || item.isMine) return;
    await _sendMediaChatMessage(item, audioPath,
        caption: _replyController.text.trim(), messageType: 3, fallback: '🎤');
    _replyController.clear();
    _replyFocus.unfocus();
    _closeReplyInput();
  }

  void _cancelVoiceReply() {
    _voiceTimer?.cancel();
    final recorder = _voiceRecorder;
    _voiceRecorder = null;
    try {
      recorder?.stop();
    } catch (_) {}
    try {
      recorder?.dispose();
    } catch (_) {}
    if (mounted) setState(() => _recordingVoice = false);
  }

  String _formatVoiceTime() {
    final m = (_voiceSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_voiceSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Media reply: picks an image (camera/gallery) and sends it as a chat
  /// message to the story owner WITH the story reference — the receiver sees
  /// the WhatsApp-style story preview above the image. A status-reply record
  /// (exact status id) is also created so the owner's Replies sheet shows it.
  Future<void> _pickMediaReply(ImageSource source) async {
    if (_pickingMediaReply) return;
    final targetIndex = _replyTargetIndex ?? _currentIndex;
    final item = _items[targetIndex];
    if (item.status.suId == null || item.isMine) return;
    _pickingMediaReply = true;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _sendMediaChatMessage(item, picked.path,
          caption: _replyController.text.trim());
      _replyController.clear();
      _replyFocus.unfocus();
      _closeReplyInput();
    } catch (_) {
    } finally {
      _pickingMediaReply = false;
    }
  }

  Future<void> _sendMediaChatMessage(_ViewerItem item, String filePath,
      {String? caption, int messageType = 1, String fallback = '📷'}) async {
    try {
      final myId = _myId;
      final authorId = item.author?['user_id']?.toString();
      if (myId == null || authorId == null) return;

      final matchingRoom = await _resolveOrCreateRoom(authorId);
      if (matchingRoom == null) return;

      final status = item.status;
      if (status.suId == null || status.suId!.isEmpty) return;
      final replyText = (caption != null && caption.trim().isNotEmpty)
          ? caption.trim()
          : fallback;

      // Status-side reply record pinned to this exact story.
      try {
        await _statusController.replyToStatus(status.suId!, replyText);
      } catch (_) {}

      final formData = Dio.FormData.fromMap({
        'message': replyText,
        'room_id': matchingRoom.rId,
        'message_type': messageType.toString(),
        // 1=image, 2=document, 3=audio, 4=video — same types the chat uses
        'is_scheduled': '0',
        'scheduled_at': '0',
        'me': true,
        'receiver_id': authorId,
        'm_interval': '0',
        'm_count': '0',
        'm_replied_on': '',
        'm_story_ref': jsonEncode(_buildStoryRef(item, replyText)),
        'media_file': await Dio.MultipartFile.fromFile(filePath,
            filename: filePath.split('/').last),
      });
      final res = await MessageApi().sendFormData(formData: formData);
      final model = res?.msg;
      if (res?.status == true && model != null) {
        if (kDebugMode) {
          debugPrint('STATUS-REPLY-TRACE → sent media chat message '
              'storyRef=${model.mStoryRef}');
        }
        _chatController.socket.emit('message', model.toJson());
        _chatController.addSentMessage(model);
      }
    } catch (_) {}
  }

  Widget _buildReactionsRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _emojis
            .map((e) => GestureDetector(
                  onTap: () {
                    _sendReaction(e);
                    _closeReactionsRow();
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: CustomColor.kTextOnDark.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(e, style: TextStyle(fontSize: 22.sp)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  ImageProvider? _buildAvatar(Map<String, dynamic>? author) {
    final img = author?['user_image']?.toString();
    if (img != null && img.isNotEmpty) {
      return NetworkImage('${Endpoints.mediaBaseUrl}$img');
    }
    return null;
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    final dt = AppHelper.parseServerUtc(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _OwnActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OwnActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CustomColor.kTextOnDark, size: 16.r),
            SizedBox(width: 6.w),
            Text(
              label,
              style:
                  AppTextStyles.bodySm.copyWith(color: CustomColor.kTextOnDark),
            ),
          ],
        ),
      ),
    );
  }
}
