import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_animation.dart';

import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/chat_ui/chat_search_bar.dart';
import 'package:humming_bird/components/chat_ui/message_context_overlay.dart';
import 'package:humming_bird/components/chat_ui/message_info_sheet.dart';
import 'package:humming_bird/components/chat_ui/delete_message_dialog.dart';
import 'package:humming_bird/components/chat_ui/group_sender_name.dart';
import 'package:humming_bird/components/chat_ui/mention_suggestion_bar.dart';
import 'package:humming_bird/components/chat_ui/mention_rich_text.dart';

import 'package:humming_bird/components/chat_ui/message_reactions.dart';
import 'package:humming_bird/components/chat_ui/brand_bubble_artwork.dart';
import 'package:humming_bird/components/chat_ui/pinned_messages_bar.dart';
import 'package:humming_bird/components/chat_ui/replying_widget.dart';
import 'package:humming_bird/components/chat_ui/replied_on_container.dart';
import 'package:humming_bird/components/chat_ui/story_reference_container.dart';
import 'package:humming_bird/components/chat_ui/link_message_widget.dart';
import 'package:humming_bird/components/chat_ui/reaction_burst_host.dart';
import 'package:humming_bird/components/chat_ui/widgets/group_context_card.dart';
import 'package:humming_bird/components/chat_ui/widgets/group_system_message.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/connectivity/pulsing_dot.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/services/group_system_message_service.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:humming_bird/components/chat_ui/premium_chat_header.dart';
import 'package:humming_bird/components/chat_ui/ai_reply_suggestions.dart';
import 'package:humming_bird/components/schedule/schedule_bottom_sheet.dart';
import 'package:humming_bird/components/schedule/edit_schedule_dialog.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/chat_customization_controller.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/emoji_picker.dart';
import 'package:humming_bird/pages/chats/widgets/share_contact_bottom_sheet.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:lottie/lottie.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String userNumber;
  final String roomId;
  final String receiverId;
  final bool isGroup;
  final String userBio;
  final String userProfile;
  final bool isPending;
  final bool openScheduleSheet;

  const ChatScreen(
      {super.key,
      required this.name,
      this.userNumber = '',
      required this.roomId,
      this.receiverId = '',
      this.userProfile = '',
      this.userBio = '',
      this.isGroup = false,
      this.isPending = false,
      this.openScheduleSheet = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late ChatController chatController;
  late BirdController birdController;
  late HomeController homeController;
  late GroupController groupController;
  late ContactController contactController;
  late UserController userController;
  late ChatCustomizationController customizationController;
  late AnimationController _headerAnimCtrl;
  late Animation<double> _headerAnim;
  double _lastScrollPixels = 0;
  final GlobalKey _composerKey = GlobalKey();
  bool _pendingBannerDismissed = false;

  // ── Shake to Send ────────────────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _shakeArmedAt;

  /// True when a real shake event arrived (magnitude above the threshold).
  bool _isRealShake(AccelerometerEvent e) {
    final mag =
        (e.x * e.x + e.y * e.y + e.z * e.z) * (1.0 / 96.2361); // g² ≈ (9.81)²
    return mag > 4.84; // ≈ 2.2g
  }

  /// Mentions picked via "@" — id -> the exact "@token" inserted in the text.
  final List<({String id, String token})> _pendingMentions = [];

  List<String> _collectMentionIds(String finalText) {
    final lower = finalText.toLowerCase();
    return _pendingMentions
        .where((m) => lower.contains(m.token.toLowerCase()))
        .map((m) => m.id)
        .toList();
  }

  // late String name;
  // late String bio;
  // late String profile;
  // late bool isGroup;

  // void getData() {
  //   (String, String) roomData =
  //       contactController.getUserBioAndProfile(chatController.getUserId());
  //   widget.userBio = roomData.$1;
  //   widget.userProfile = roomData.$2;
  // }

  @override
  void initState() {
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _headerAnim = CurvedAnimation(
      parent: _headerAnimCtrl,
      curve: Curves.easeInOut,
    );
    _headerAnimCtrl.value = 1.0;

    chatController = Get.find();
    birdController = Get.find();
    userController = Get.find();
    homeController = Get.find();
    contactController = Get.find();
    customizationController = Get.find();
    userController.inHomeScreen = false;
    chatController.textMessageController = TextEditingController();
    chatController.openChatRoom(widget.roomId);
    chatController.showEmojiPicker.value = false;
    chatController.typingListener();
    chatController.fetchMessages(
        widget.roomId == '0' ? 'new' : widget.roomId, widget.receiverId);
    if (widget.isGroup) {
      groupController = Get.find();
      contactController = Get.find();
      groupController.fetchGroupInfo(widget.roomId);
    }

    // chatController.changeSelectedRoom(widget.roomId);
    chatController.joinRoom(widget.roomId);
    homeController.currentRoom = widget.roomId;
    chatController.currentRoom = widget.roomId;
    _setupLifecycleListener();
    _startShakeDetection();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        homeController.makeUnreadReadMessage(widget.roomId);
        if (Get.arguments != null && Get.arguments['isScroll'] != null) {
          _highlightMessageAfterLoad(Get.arguments['messageId'] as String?);
        }
        if (widget.openScheduleSheet) {
          _openScheduleSheet();
        }
      },
    );
    super.initState();
  }

  /// Waits for the message list to load (fetchMessages is async) and then
  /// scrolls to + briefly highlights the target message. Bounded retries so
  /// it gives up quietly if the message is not part of the thread (e.g. a
  /// scheduled message that has not been sent yet).
  Future<void> _highlightMessageAfterLoad(String? messageId) async {
    if (messageId == null || messageId.isEmpty) return;
    const maxAttempts = 15;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (chatController.messages.any((m) => m.mId == messageId)) {
        chatController.scrollToMessage(messageId);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  void _setupLifecycleListener() {
    AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.inactive) {
          chatController.removeTyping();
          chatController.showTyping.value = false;
        }
      },
    );
  }

  // ── Shake to Send ────────────────────────────────────────────────────────────

  void _startShakeDetection() {
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onAccelerometerEvent);
    } catch (_) {}
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!mounted) return;
    if (!customizationController.shakeToSend.value) return;
    if (!_isRealShake(event)) return;

    final now = DateTime.now();
    if (now.difference(_lastShakeAt).inMilliseconds < 250) return;
    _lastShakeAt = now;

    if (_shakeArmedAt != null &&
        now.difference(_shakeArmedAt!).inMilliseconds <= 2500) {
      _sendByShake();
      return;
    }

    if (_canShakeSend()) {
      _shakeArmedAt = now;
      HapticFeedback.mediumImpact();
      Utils.showGetSnackBar('Shake again to send');
    }
  }

  bool _canShakeSend() {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }
    try {
      if (Get.find<CallController>().callState.value != 'idle') return false;
    } catch (_) {}
    final text = chatController.textMessageController.text.trim();
    if (text.isEmpty) return false;
    if (chatController.generatingMessage.value) return false;
    if (chatController.isRecording.value) return false;
    if (chatController.uploadingFile.value) return false;
    if (chatController.editingMessage) return false;
    if (chatController.scheduleSheetVisible.value) return false;
    if (chatController.showEmojiPicker.value) return false;
    if (chatController.isMultiSelectMode.value) return false;
    if (chatController.showLoading.value) return false;
    if (chatController.messageSelectorMap.isNotEmpty) return false;
    return true;
  }

  void _sendByShake() {
    _shakeArmedAt = null;
    if (!_canShakeSend()) return;
    HapticFeedback.heavyImpact();
    final text = chatController.textMessageController.text.trim();
    chatController.sendMessage(
      mentionIds: _collectMentionIds(text),
    );
    _pendingMentions.clear();
    chatController.textMessageController.clear();
    Utils.showGetSnackBar('Sent by shake');
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _accelSub = null;
    _shakeArmedAt = null;
    _headerAnimCtrl.dispose();
    chatController.closeChatRoom(widget.roomId);
    chatController.leaveRoom(widget.roomId);
    chatController.textMessageController.clear();
    homeController.currentRoom = '';
    chatController.currentRoom = '';
    super.dispose();
  }

  void _closeChat() {
    userController.inHomeScreen = true;
    chatController.removeTyping();
    chatController.isScheduledMessage.value = '0';
    homeController.currentRoom = '';
    chatController.currentRoom = '';
    chatController.audioCurrentPosition.value = 0.0;
    chatController.audioCurrentPositionString.value = '0:0';
    chatController.messageSelectorMap.value = {};
    chatController.youMessages = [];
    chatController.isReplyOnMessage.value = false;
    chatController.receiverId = '';
    chatController.showTyping.value = false;
    chatController.showEmojiPicker.value = false;
    chatController.selectedInterval.value = 0;
    chatController.scheduleCount.value = 1;
    chatController.scheduleOn = false;
    Navigator.pop(context);
  }

  bool _dismissKeyboardIfOpen() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    final textFieldFocused = focusedWidget is EditableText;
    if (!keyboardOpen && !textFieldFocused) return false;

    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    return true;
  }

  void _handleBack() {
    if (chatController.scheduleSheetVisible.value) {
      chatController.closeScheduleSheet();
      return;
    }
    if (chatController.showEmojiPicker.value) {
      chatController.showEmojiPicker.value = false;
      return;
    }
    if (_dismissKeyboardIfOpen()) return;
    _closeChat();
  }

  void _openScheduleSheet() {
    chatController.scheduleOn = true;
    if (chatController.showEmojiPicker.value) {
      chatController.showEmojiPicker.value = false;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    chatController.scheduleSheetVisible.value = true;
  }

  void _openAttachmentGrid() {
    if (chatController.uploadingFile.value) return;
    _dismissKeyboardIfOpen();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      showDragHandle: true,
      backgroundColor: CustomColor.kWhite,
      barrierColor: CustomColor.kBlack.withValues(alpha: 0.35),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg.w, AppSpacing.sm.h,
                AppSpacing.lg.w, AppSpacing.xxxl.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSpacing.xs.r,
                      height: AppSpacing.xxxl.r,
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Text(
                      'Attachment',
                      style: AppTextStyles.headingMd
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      'Share files & more',
                      style: AppTextStyles.bodySm.copyWith(
                        color: CustomColor.kTextSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl.h),
                _AttachmentRow(
                  items: [
                    _AttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openCameraToComposer();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        chatController.pickGalleryMedia();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.description_rounded,
                      label: 'Document',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        chatController.pickDocuments();
                      },
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.h),
                _AttachmentRow(
                  items: [
                    _AttachmentOption(
                      icon: Icons.music_note_rounded,
                      label: 'Audio',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        chatController.pickFile(FileType.audio, 3);
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Contact',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openShareContactSheet();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.schedule_rounded,
                      label: 'Schedule',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openScheduleSheet();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCameraToComposer() {
    _dismissKeyboardIfOpen();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      showDragHandle: true,
      backgroundColor: CustomColor.kWhite,
      barrierColor: CustomColor.kBlack.withValues(alpha: 0.35),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg.w, AppSpacing.sm.h,
                AppSpacing.lg.w, AppSpacing.xxxl.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSpacing.xs.r,
                      height: AppSpacing.xxxl.r,
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Text(
                      'Take photo or video',
                      style: AppTextStyles.headingMd
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xl.h),
                _AttachmentRow(
                  items: [
                    _AttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Photo',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        chatController.pickCameraComposer();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        chatController.pickCameraVideoComposer();
                      },
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openShareContactSheet() {
    _dismissKeyboardIfOpen();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: CustomColor.kWhite,
      barrierColor: CustomColor.kBlack.withValues(alpha: 0.35),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return ShareContactBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          _handleBack();
        }
      },
      // onPopInvokedWithResult: (_, __) {
      //   userController.inHomeScreen = true;
      //   chatController.removeTyping();
      //   chatController.isScheduledMessage.value = '0';
      //   homeController.currentRoom = '';
      //   chatController.currentRoom = '';
      //   chatController.audioCurrentPosition.value = 0.0;
      //   chatController.audioCurrentPositionString.value = '0:0';
      //   chatController.messageSelectorMap.value = {};
      //   chatController.youMessages = [];
      //   chatController.isReplyOnMessage.value = false;
      //   chatController.receiverId = '';
      //   chatController.showTyping.value = false;
      //   chatController.selectedInterval.value = 0;
      //   chatController.scheduleCount.value = 0;
      // },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? CustomColor.kDarkBackground
            : CustomColor.kUltraLightPrimary,
        body: Column(
          children: [
            SizeTransition(
              sizeFactor: _headerAnim,
              alignment: const Alignment(-1.0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumChatHeader(
                    name: widget.isGroup && widget.name.trim().isEmpty
                        ? 'Group'
                        : widget.name,
                    userNumber: widget.userNumber,
                    roomId: widget.roomId,
                    receiverId: widget.receiverId,
                    isGroup: widget.isGroup,
                    userBio: widget.userBio,
                    userProfile: widget.userProfile,
                    onBack: _handleBack,
                    isPending: widget.isPending,
                  ),
                  if (widget.isPending && !_pendingBannerDismissed)
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16.r, color: CustomColor.kPrimaryColor),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Not using Humming Bird yet — messages will be delivered when they join.',
                            ),
                          ),
                          IconButton(
                            tooltip: 'Dismiss',
                            iconSize: 18.r,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.close,
                                size: 18.r, color: CustomColor.kPrimaryColor),
                            onPressed: () =>
                                setState(() => _pendingBannerDismissed = true),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Obx(() {
              final online = ConnectivityService.to.isOnline.value;
              // Global banner already owns the offline state — stay quiet here.
              if (!online) {
                return const SizedBox.shrink(key: ValueKey('offline'));
              }
              final socketState = chatController.socketConnectionState.value;
              final (label, color) = switch (socketState) {
                SocketConnectionState.connected => (
                    'Connected',
                    CustomColor.kPrimaryColor
                  ),
                SocketConnectionState.connecting => (
                    'Connecting to Humming Bird…',
                    CustomColor.kPrimaryMedium
                  ),
                SocketConnectionState.reconnecting => (
                    'Trying to reconnect…',
                    CustomColor.kGoldAccent
                  ),
                SocketConnectionState.disconnected => (
                    'Live connection unavailable',
                    CustomColor.kTextTertiary
                  ),
              };
              return AnimatedSwitcher(
                duration: AppAnimation.medium,
                switchInCurve: AppAnimation.easeOut,
                switchOutCurve: AppAnimation.easeIn,
                transitionBuilder: (child, anim) => SizeTransition(
                  sizeFactor: anim,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Container(
                  key: ValueKey(socketState.name),
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PulsingDot(
                        color: color,
                        size: 7.r,
                        animate:
                            socketState != SocketConnectionState.disconnected,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          label,
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Obx(
                    () => customizationController.buildWallpaperLayer(
                      context: context,
                      roomId: widget.roomId,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => chatController.isSearching.value
                            ? const ChatSearchBar()
                            : const SizedBox.shrink(),
                      ),
                      Expanded(
                        child: Obx(
                          () => chatController.loadingSingleChats.value
                              ? const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                )
                              : Obx(
                                  () {
                                    chatController.messages.length;
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        NotificationListener<
                                            ScrollNotification>(
                                          onNotification: (notification) {
                                            if (notification
                                                is ScrollUpdateNotification) {
                                              final pixels =
                                                  notification.metrics.pixels;
                                              if (pixels >
                                                  _lastScrollPixels + 4) {
                                                _headerAnimCtrl.forward();
                                              }
                                              _lastScrollPixels = pixels;
                                              if (notification.dragDetails !=
                                                  null) {
                                                chatController
                                                    .markManualScroll();
                                              }
                                              // Feeds pixel-accurate viewport
                                              // metrics; the near-bottom /
                                              // affordance decision is made by
                                              // the controller's positions
                                              // listener (single source).
                                              chatController.onScrollMetrics(
                                                  pixels: pixels,
                                                  viewportDimension:
                                                      notification.metrics
                                                          .viewportDimension);
                                            }
                                            return false;
                                          },
                                          child:
                                              ScrollablePositionedList.builder(
                                            itemScrollController: chatController
                                                .itemScrollController,
                                            itemPositionsListener:
                                                chatController
                                                    .itemPositionsListener,
                                            itemCount:
                                                chatController.messages.length,
                                            reverse: true,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 14.h),
                                            itemBuilder: (context, index) {
                                              final Messages message =
                                                  chatController.messages[
                                                      index == -1
                                                          ? index + 1
                                                          : index];
                                              (bool, Widget) timestamp =
                                                  chatController.showTimestamp(
                                                      index == -1
                                                          ? index + 1
                                                          : index);
                                              final bool isMe = chatController
                                                      .userController
                                                      .user
                                                      ?.userId ==
                                                  message.mSenderId;
                                              return RepaintBoundary(
                                                child: TweenAnimationBuilder(
                                                  tween: Tween(
                                                      begin: 0.0, end: 1.0),
                                                  duration: isMe
                                                      ? const Duration(
                                                          milliseconds: 200)
                                                      : const Duration(
                                                          milliseconds: 250),
                                                  curve: isMe
                                                      ? Curves.easeOutBack
                                                      : Curves.easeOutCubic,
                                                  builder:
                                                      (context, value, child) {
                                                    // Settled bubbles render
                                                    // bare — no Opacity /
                                                    // Transform layers, so the
                                                    // per-item RepaintBoundary
                                                    // above has nothing extra
                                                    // to composite while
                                                    // scrolling.
                                                    if (value >= 1.0) {
                                                      return child!;
                                                    }
                                                    return Opacity(
                                                      opacity:
                                                          value.clamp(0.0, 1.0),
                                                      child: isMe
                                                          ? Transform.scale(
                                                              scale:
                                                                  value.clamp(
                                                                      0.0, 1.0),
                                                              child: child,
                                                            )
                                                          : Transform.translate(
                                                              offset: Offset(
                                                                  12 *
                                                                      (1 -
                                                                          value),
                                                                  0),
                                                              child: child,
                                                            ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      top: index > 0 &&
                                                              chatController
                                                                  .compareMessagesDates(
                                                                      index)
                                                          ? 20.h
                                                          : 4.h,
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        timestamp.$1
                                                            ? chatController.messages
                                                                            .length -
                                                                        1 ==
                                                                    index
                                                                ? timestamp.$2
                                                                : const SizedBox
                                                                    .shrink()
                                                            : timestamp.$2,
                                                        if (GroupSystemMessageService
                                                            .isSystem(message))
                                                          GroupSystemMessage(
                                                              message: message)
                                                        else if (isMe)
                                                          _buildSentBubble(
                                                              context, message)
                                                        else
                                                          _buildReceivedBubble(
                                                              context, message),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          right: 12.w,
                                          bottom: 10.h,
                                          child: Obx(
                                            () {
                                              final show = chatController
                                                  .showScrollToBottom.value;
                                              final unread = chatController
                                                  .scrollToBottomUnreadCount
                                                  .value;
                                              return IgnorePointer(
                                                ignoring: !show,
                                                child: AnimatedOpacity(
                                                  opacity: show ? 1.0 : 0.0,
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  curve: Curves.easeOut,
                                                  child: AnimatedScale(
                                                    scale: show ? 1.0 : 0.4,
                                                    duration: const Duration(
                                                        milliseconds: 220),
                                                    curve: Curves.easeOutBack,
                                                    child: Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        PressScale(
                                                          child: Material(
                                                            color: CustomColor
                                                                .kCardBackground,
                                                            shape:
                                                                const CircleBorder(),
                                                            elevation: 3,
                                                            shadowColor: Colors
                                                                .black
                                                                .withValues(
                                                                    alpha:
                                                                        0.25),
                                                            child: InkWell(
                                                              customBorder:
                                                                  const CircleBorder(),
                                                              onTap: () {
                                                                chatController
                                                                    .scrollToBottom();
                                                                _lastScrollPixels =
                                                                    0;
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                        AppSpacing
                                                                            .sm
                                                                            .r),
                                                                child: Icon(
                                                                  Icons
                                                                      .keyboard_arrow_down_rounded,
                                                                  size: AppIcons
                                                                      .lg.r,
                                                                  color: CustomColor
                                                                      .kPrimaryColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        if (unread > 0)
                                                          Positioned(
                                                            right: 0,
                                                            top: 0,
                                                            child: Container(
                                                              constraints:
                                                                  const BoxConstraints(
                                                                      minWidth:
                                                                          16),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          4,
                                                                      vertical:
                                                                          1.5),
                                                              decoration:
                                                                  const BoxDecoration(
                                                                color: CustomColor
                                                                    .kDangerRed,
                                                                borderRadius: BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            9)),
                                                              ),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                unread > 99
                                                                    ? '99+'
                                                                    : '$unread',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      11.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  height: 1.2,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ),

                      if (widget.isGroup)
                        Obx(
                          () => chatController.messages.isEmpty
                              ? GroupContextCard(roomId: widget.roomId)
                              : const SizedBox.shrink(),
                        ),
                      const PinnedMessagesBar(),
                      Obx(
                        () => chatController.showTyping.value
                            ? Padding(
                                padding: EdgeInsets.only(left: 15.w, top: 10.h),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: CustomColor.kWhite,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.xxl.r),
                                    boxShadow: AppShadow.cardLight,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg.w,
                                      vertical: AppSpacing.sm.h),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding:
                                            EdgeInsets.all(AppSpacing.xxs.r),
                                        decoration: const BoxDecoration(
                                          gradient: CustomColor.primaryGradient,
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircleAvatar(
                                          radius: AppRadius.xxl.r,
                                          backgroundImage: widget.isGroup
                                              ? groupController
                                                  .getGroupImage(widget.roomId)
                                              : widget.userProfile.isNotEmpty
                                                  ? CachedNetworkImageProvider(
                                                      '${Endpoints.mediaBaseUrl}${widget.userProfile}')
                                                  : const AssetImage(AppAssets
                                                          .defaultProfilePic)
                                                      as ImageProvider,
                                          onBackgroundImageError: (_, __) {},
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.md.w),
                                      LottieBuilder.asset(
                                        AppAssets.typingAnim,
                                        width: 75.w,
                                        height: 60.h,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      ///START AI REPLY SUGGESTIONS (Disabled)
                      const SizedBox.shrink(),

                      ///START MULTI-SELECT ACTION BAR
                      Obx(
                        () => chatController.messageSelectorMap.isNotEmpty
                            ? Container(
                                decoration: BoxDecoration(
                                  color: CustomColor.kWhite,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CustomColor.kPrimaryColor
                                          .withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm.h,
                                    horizontal: AppSpacing.lg.w),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (chatController.canEditSelectedMessage)
                                      Flexible(
                                        child: _MultiSelectAction(
                                          icon: Icons.edit_rounded,
                                          label: 'Edit',
                                          onTap: () {
                                            chatController
                                                .editMessageFromChatScreen();
                                          },
                                        ),
                                      ),
                                    Flexible(
                                        child: _MultiSelectAction(
                                      icon: Icons.forward_rounded,
                                      label: 'Forward',
                                      onTap: () {
                                        chatController
                                            .forwardSelectedMessages();
                                      },
                                    )),
                                    Flexible(
                                        child: _MultiSelectAction(
                                      icon: Icons.star_outline_rounded,
                                      label: 'Star',
                                      onTap: () {
                                        chatController.starSelectedMessages();
                                      },
                                    )),
                                    Flexible(
                                        child: _MultiSelectAction(
                                      icon: Icons.push_pin_outlined,
                                      label: 'Pin',
                                      onTap: () {
                                        chatController.pinSelectedMessages();
                                      },
                                    )),
                                    Flexible(
                                        child: _MultiSelectAction(
                                      icon: Icons.content_copy_rounded,
                                      label: 'Copy',
                                      onTap: () async {
                                        final ids = chatController
                                            .messageSelectorMap.keys
                                            .cast<String>()
                                            .toList();
                                        final texts = ids
                                            .map((id) {
                                              final idx = chatController
                                                  .messages
                                                  .indexWhere(
                                                      (m) => m.mId == id);
                                              if (idx >= 0 &&
                                                  chatController.messages[idx]
                                                          .mMessageType ==
                                                      '0') {
                                                return chatController
                                                        .messages[idx]
                                                        .mMessage ??
                                                    '';
                                              }
                                              return '';
                                            })
                                            .where((t) => t.isNotEmpty)
                                            .join('\n');
                                        if (texts.isNotEmpty) {
                                          await Clipboard.setData(
                                              ClipboardData(text: texts));
                                          Utils.showGetSnackBar(
                                              'Copied to clipboard');
                                        }
                                        chatController
                                            .messageSelectorMap.value = {};
                                        chatController.youMessages.clear();
                                      },
                                    )),
                                    Flexible(
                                        child: _MultiSelectAction(
                                      icon: Icons.delete_outline_rounded,
                                      label: 'Delete',
                                      isDestructive: true,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              const DeleteMessageDialog(),
                                        );
                                      },
                                    )),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      ///START MESSAGE BAR & ICONS BUTTONS
                      Obx(
                        () {
                          // Group members who were removed can no longer send
                          // messages (mirrors WhatsApp). Keeps the room open
                          // for history, swaps the composer for a notice.
                          if (widget.isGroup) {
                            groupController.groupMembers.value;
                            if (!groupController
                                .isCurrentUserMember(widget.roomId)) {
                              return const _NonMemberBanner();
                            }
                          }
                          return chatController.scheduleSheetVisible.value
                              ? const SizedBox.shrink()
                              : Column(
                                  key: _composerKey,
                                  children: [
                                    const ReplyingMessageContainer(),
                                    if (widget.isGroup)
                                      GetBuilder<GroupController>(
                                        builder: (_) {
                                          final members = groupController
                                                  .groupData?.members ??
                                              const <User>[];
                                          return MentionSuggestionBar(
                                            controller: chatController
                                                .textMessageController,
                                            members: members,
                                            onMentionSelected: (id, token) {
                                              _pendingMentions.removeWhere(
                                                  (m) => m.id == id);
                                              _pendingMentions
                                                  .add((id: id, token: token));
                                            },
                                          );
                                        },
                                      ),
                                    Obx(
                                      () => Container(
                                        decoration: BoxDecoration(
                                          color: CustomColor.kWhite,
                                          border: Border(
                                            top: BorderSide(
                                                color: CustomColor.kPrimaryColor
                                                    .withValues(alpha: 0.08)),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: CustomColor.kPrimaryColor
                                                  .withValues(alpha: 0.07),
                                              blurRadius: 30,
                                              offset: const Offset(0, -8),
                                            ),
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, -3),
                                            ),
                                          ],
                                          borderRadius: BorderRadius.only(
                                              topRight: Radius.circular(
                                                  chatController
                                                          .isReplyOnMessage
                                                          .value
                                                      ? 0
                                                      : AppRadius.rounded),
                                              topLeft: Radius.circular(
                                                  chatController
                                                          .isReplyOnMessage
                                                          .value
                                                      ? 0
                                                      : AppRadius.rounded)),
                                        ),
                                        child: Column(
                                          children: [
                                            const AiReplySuggestions(
                                                autoSend: true),
                                            Obx(
                                              () => chatController
                                                      .isRecording.value
                                                  ? _RecordingBar(
                                                      chatController:
                                                          chatController)
                                                  : const SizedBox.shrink(),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  AppSpacing.lg.w,
                                                  AppSpacing.lg.h,
                                                  AppSpacing.lg.w,
                                                  chatController
                                                          .showEmojiPicker.value
                                                      ? 0
                                                      : AppSpacing.xl.h +
                                                          MediaQuery.of(context)
                                                              .padding
                                                              .bottom),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                        bottom: 1.h),
                                                    child: _ComposerRoundButton(
                                                      icon: Icons.add_rounded,
                                                      onTap: () {
                                                        chatController
                                                            .showEmojiPicker
                                                            .value = false;
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                        SystemChannels.textInput
                                                            .invokeMethod(
                                                                'TextInput.hide');
                                                        _openAttachmentGrid();
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width: AppSpacing.md.w),

                                                  ///START MESSAGE INPUT TEXT DECORATION
                                                  Flexible(
                                                    child: TextField(
                                                      onTap: () {
                                                        if (chatController
                                                            .showEmojiPicker
                                                            .value) {
                                                          chatController
                                                              .showEmojiPicker
                                                              .value = false;
                                                        }
                                                      },
                                                      cursorColor: CustomColor
                                                          .kPrimaryMedium,
                                                      controller: chatController
                                                          .textMessageController,
                                                      keyboardType:
                                                          TextInputType
                                                              .multiline,
                                                      minLines: 1,
                                                      maxLines: 3,
                                                      textAlignVertical:
                                                          TextAlignVertical
                                                              .center,
                                                      decoration:
                                                          InputDecoration(
                                                        filled: true,
                                                        fillColor: CustomColor
                                                            .kUltraLightBg,
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        3.w,
                                                                    vertical:
                                                                        11.h),
                                                        hintText:
                                                            'Type a message...',
                                                        hintStyle: AppTextStyles
                                                            .bodyMd
                                                            .copyWith(
                                                                fontSize: 13.sp,
                                                                color: CustomColor
                                                                    .kTextTertiary),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .transparent,
                                                                  width: 1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      AppRadius
                                                                          .xxl
                                                                          .r),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: CustomColor
                                                                  .kPrimaryMedium
                                                                  .withValues(
                                                                      alpha:
                                                                          0.6),
                                                              width: 1.4),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      AppRadius
                                                                          .xxl
                                                                          .r),
                                                        ),
                                                        prefixIconConstraints:
                                                            const BoxConstraints
                                                                .tightFor(
                                                                width: 40),
                                                        prefixIcon: InkWell(
                                                          onTap: () {
                                                            final shouldOpen =
                                                                !chatController
                                                                    .showEmojiPicker
                                                                    .value;
                                                            if (shouldOpen) {
                                                              FocusManager
                                                                  .instance
                                                                  .primaryFocus
                                                                  ?.unfocus();
                                                              SystemChannels
                                                                  .textInput
                                                                  .invokeMethod(
                                                                      'TextInput.hide');
                                                            }
                                                            chatController
                                                                .showEmojiPicker
                                                                .value = shouldOpen;
                                                          },
                                                          child: Icon(
                                                            Icons
                                                                .emoji_emotions_outlined,
                                                            size: 22.sp,
                                                            color: CustomColor
                                                                .kTextSecondary,
                                                          ),
                                                        ),
                                                        suffixIconConstraints:
                                                            const BoxConstraints(
                                                                minWidth: 56),
                                                        suffixIcon: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            InkWell(
                                                              onTap:
                                                                  _openScheduleSheet,
                                                              child:
                                                                  Obx(
                                                                      () =>
                                                                          Icon(
                                                                            Icons.schedule_outlined,
                                                                            size:
                                                                                22.sp,
                                                                            color: chatController.isScheduledMessage.value == '0'
                                                                                ? CustomColor.kTextSecondary
                                                                                : CustomColor.kSuccess,
                                                                          )),
                                                            ),
                                                            SizedBox(
                                                                width: 4.w),
                                                            InkWell(
                                                              onTap: () {
                                                                chatController
                                                                    .showEmojiPicker
                                                                    .value = false;
                                                                _openCameraToComposer();
                                                              },
                                                              child: Icon(
                                                                Icons
                                                                    .camera_alt_outlined,
                                                                size: 22.sp,
                                                                color: CustomColor
                                                                    .kTextSecondary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  ///END MESSAGE INPUT TEXT DECORATION
                                                  SizedBox(
                                                      width: AppSpacing.md.w),
                                                  _buildComposerSendAction(),
                                                ],
                                              ),
                                            ),
                                            Obx(
                                              () => chatController
                                                      .showEmojiPicker.value
                                                  ? const EmojiPickerSheet()
                                                  : const SizedBox.shrink(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                      //END MESSAGE BAR & ICONS BUTTONS
                    ],
                  ),
                  Obx(
                    () => chatController.scheduleSheetVisible.value
                        ? ScheduleSheetOverlay(bottomInset: 0)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposerSendAction() {
    return Obx(() {
      final showMic = !chatController.generatingMessage.value &&
          !chatController.scheduleSheetVisible.value &&
          !chatController.toggleSendButton.value;
      return InkWell(
        onTap: chatController.generatingMessage.value
            ? null
            : () {
                if (chatController.isRecording.value) {
                  chatController.saveAudio();
                  return;
                }
                if (showMic) {
                  chatController.recordAudio();
                  return;
                }
                if (chatController.scheduleSheetVisible.value) {
                  chatController.setDateAndTime();
                  return;
                }
                if (chatController.editingMessage) {
                  final editMsg = chatController.getMessageBeingEdited();
                  if (editMsg != null) {
                    chatController.updateMessage(
                      editMsg,
                      false,
                      false,
                      newMessage:
                          chatController.textMessageController.text.trim(),
                    );
                  }
                } else {
                  chatController.sendMessage(
                    mentionIds: _collectMentionIds(
                        chatController.textMessageController.text.trim()),
                  );
                  _pendingMentions.clear();
                }
                chatController.dateController.clear();
                chatController.timeController.clear();
                chatController.isScheduledMessage.value = '0';
              },
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42.r,
          height: 42.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: chatController.generatingMessage.value
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CustomColor.kPrimaryColor,
                      CustomColor.kPrimaryMedium
                    ],
                  ),
            color: chatController.generatingMessage.value
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.5)
                : null,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            boxShadow: AppShadow.buttonLight,
          ),
          child: chatController.generatingMessage.value
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(CustomColor.kTextOnDark),
                  ),
                )
              : Icon(
                  chatController.isRecording.value
                      ? Icons.stop_rounded
                      : (showMic ? Icons.mic_rounded : Icons.send_rounded),
                  size: 22.sp,
                  color: CustomColor.kTextOnDark,
                ),
        ),
      );
    });
  }

  Widget _buildReceivedBubble(BuildContext context, Messages message) {
    final isDeletedMessage = message.mIsDeleted == '1';
    return VisibilityDetector(
      key: ValueKey('bubble-visibility-${message.mId}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction * 100 >= 10 && message.mReadStatus != '3') {
          message.mReadStatus = '3';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            chatController.updateMessage(message, true, widget.isGroup);
          });
        }
      },
      child: _SwipeableMessageBubble(
        onReply: () {
          if (isDeletedMessage) return;
          chatController.replyToMessage(message);
        },
        onInfo: () => _showMessageInfo(message),
        child: InkWell(
          onTap: () {
            if (message.isScheduledMessage &&
                !chatController.isMultiSelectMode.value) {
              _showScheduledMessageMenu(message, isMe: false);
              return;
            }
            chatController.manageMessageSelector(message.mId!,
                isYouMessage: true);
          },
          onDoubleTap: () {
            if (chatController.isMultiSelectMode.value) return;
            if (isDeletedMessage) return;
            chatController.burstReaction(message.mId!);
            chatController.toggleReaction(message.mId!, '❤️');
          },
          onLongPress: () {
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              MessageContextOverlay.show(
                context: context,
                message: message,
                isMe: false,
                roomId: widget.roomId,
                receiverId: widget.receiverId,
                roomUsers: widget.receiverId,
                name: widget.name,
                userNumber: widget.userNumber,
                userBio: widget.userBio,
                userProfile: widget.userProfile,
                isGroup: widget.isGroup,
                messageGlobalPosition: box.localToGlobal(Offset.zero),
                messageSize: box.size,
              );
            }
          },
          child: Obx(() {
            final isSelected =
                chatController.messageSelectorMap[message.mId] == true;
            final matrix = isSelected
                ? (Matrix4.diagonal3Values(0.97, 0.97, 1))
                : Matrix4.identity();
            return AnimatedContainer(
              duration: AppAnimation.fast,
              transform: matrix,
              transformAlignment: Alignment.center,
              padding: EdgeInsets.only(
                left: AppSpacing.lg.w,
                right: 50.w,
                top: (isSelected ? AppSpacing.md.h : AppSpacing.sm.h) *
                    customizationController.densityFactor,
                bottom: (isSelected ? AppSpacing.md.h : AppSpacing.sm.h) *
                    customizationController.densityFactor,
              ),
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.mRepliedOn != null && !isDeletedMessage)
                    Padding(
                      padding: EdgeInsets.only(left: 15.w, bottom: 4.h),
                      child: RepliedOnContainer(
                        messageId: message.mRepliedOn!,
                        replyColor: customizationController.replyTint,
                        textSize: customizationController.replySize.value,
                      ),
                    ),
                  if (message.mStoryRef != null && !isDeletedMessage)
                    Padding(
                      padding: EdgeInsets.only(left: 15.w, bottom: 4.h),
                      child: StoryReferenceContainer(message: message),
                    ),
                  ReactionBurstHost(
                    messageId: message.mId!,
                    reactionsJson: message.mReactions,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 12.w),
                          constraints: BoxConstraints(
                            maxWidth: customizationController.maxWidthFactor.sw,
                            minWidth: 0,
                          ),
                          decoration: customizationController.bubbleDecoration(
                            isMe: false,
                            isSelected: isSelected,
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                            isMedia: !isDeletedMessage &&
                                message.mMessageType != '0',
                          ),
                          child: Padding(
                            padding: customizationController.bubblePadding(
                              isMe: false,
                              isMedia: !isDeletedMessage &&
                                  message.mMessageType != '0',
                            ),
                            child: IntrinsicWidth(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (customizationController
                                              .timestampPlacement.value ==
                                          'inside' &&
                                      customizationController
                                              .timestampPosition.value ==
                                          'top')
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: _buildTimestampRow(
                                          message, false, context),
                                    ),
                                  AnimatedSwitcher(
                                    duration: AppAnimation.normal,
                                    switchInCurve: AppAnimation.easeOut,
                                    switchOutCurve: AppAnimation.easeIn,
                                    child: isDeletedMessage
                                        ? _buildDeletedPlaceholder(
                                            context,
                                            isMe: false,
                                          )
                                        : Column(
                                            key: const ValueKey('content'),
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (widget.isGroup)
                                                SenderNameContainer(
                                                  senderId: message.mSenderId!,
                                                  avatarSize:
                                                      customizationController
                                                          .avatarSize.value,
                                                  nameColor:
                                                      customizationController
                                                          .mention,
                                                ),
                                              if (message.mForwarded == '1')
                                                _buildForwardedBadge(),
                                              if (message.mMessageType == '0')
                                                _buildMessageBody(
                                                    context, message,
                                                    isMe: false)
                                              else
                                                AppHelper.checkFileType(
                                                  mediaId: message.mId!,
                                                  roomId: message.mRoomId!,
                                                  mediaUrl:
                                                      '${Endpoints.mediaBaseUrl}${message.mMedia}',
                                                  fileType:
                                                      message.mMessageType!,
                                                  msg: message.mMessage
                                                      .toString(),
                                                  messageId: message.mId,
                                                ),
                                              if (message.mIsEdited == '1')
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 2.h),
                                                  child: Text(
                                                    'Edited',
                                                    style: AppTextStyles
                                                        .chatTime
                                                        .copyWith(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontSize: 10.sp,
                                                    ),
                                                  ),
                                                ),
                                              if (message.isScheduledMessage)
                                                Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 2.h),
                                                  child: _buildScheduleLabel(
                                                      message, false),
                                                ),
                                            ],
                                          ),
                                  ),
                                  if (customizationController
                                              .timestampPlacement.value ==
                                          'inside' &&
                                      customizationController
                                              .timestampPosition.value ==
                                          'bottom')
                                    Padding(
                                      padding: EdgeInsets.only(top: 2.h),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: _buildTimestampRow(
                                            message, false, context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (customizationController.isPremiumStyle &&
                            message.mMessageType == '0')
                          _premiumGlossOverlay(isMe: false),
                        if (customizationController.isPremiumStyle &&
                            message.mMessageType == '0')
                          _bubbleTail(
                            isMe: false,
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                        if (chatController.isMultiSelectMode.value)
                          Positioned(
                            right: -22.r,
                            top: 0,
                            child: _buildSelectionCheck(isSelected),
                          ),
                        if (isSelected)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: customizationController
                                    .bubbleRadius(isMe: false),
                                child: Container(
                                  color: customizationController.selection
                                      .withValues(alpha: 0.18),
                                ),
                              ),
                            ),
                          ),
                        if (!isDeletedMessage &&
                            message.mReactions != null &&
                            message.mReactions!.isNotEmpty)
                          Positioned(
                            bottom: -10.h,
                            right: 10.w,
                            child: MessageReactions(
                              messageId: message.mId!,
                              reactionsJson: message.mReactions,
                              isMe: false,
                              emojiSize:
                                  customizationController.emojiSize.value,
                              accentColor: customizationController.reaction,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (customizationController.timestampPlacement.value ==
                      'outside')
                    Padding(
                      padding: EdgeInsets.only(left: 12.w, top: 3.h),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildTimestampRow(message, false, context),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSentBubble(BuildContext context, Messages message) {
    final isDeletedMessage = message.mIsDeleted == '1';
    return _SwipeableMessageBubble(
      onReply: () {
        if (isDeletedMessage) return;
        chatController.replyToMessage(message);
      },
      onInfo: () => _showMessageInfo(message),
      child: InkWell(
        onTap: () {
          if (message.isScheduledMessage &&
              !chatController.isMultiSelectMode.value) {
            _showScheduledMessageMenu(message);
            return;
          }
          chatController.manageMessageSelector(message.mId!);
        },
        onDoubleTap: () {
          if (chatController.isMultiSelectMode.value) return;
          if (isDeletedMessage) return;
          chatController.burstReaction(message.mId!);
          chatController.toggleReaction(message.mId!, '❤️');
        },
        onLongPress: () {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            MessageContextOverlay.show(
              context: context,
              message: message,
              isMe: true,
              roomId: widget.roomId,
              receiverId: widget.receiverId,
              roomUsers: widget.receiverId,
              name: widget.name,
              userNumber: widget.userNumber,
              userBio: widget.userBio,
              userProfile: widget.userProfile,
              isGroup: widget.isGroup,
              messageGlobalPosition: box.localToGlobal(Offset.zero),
              messageSize: box.size,
            );
          }
        },
        child: Obx(() {
          final isSelected =
              chatController.messageSelectorMap[message.mId] == true;
          final matrix = isSelected
              ? (Matrix4.diagonal3Values(0.97, 0.97, 1))
              : Matrix4.identity();
          return AnimatedContainer(
            duration: AppAnimation.fast,
            transform: matrix,
            transformAlignment: Alignment.center,
            padding: EdgeInsets.only(
              left: AppSpacing.huge.r,
              right: AppSpacing.xl.r,
              top: (isSelected ? AppSpacing.md.r : AppSpacing.sm.r) *
                  customizationController.densityFactor,
              bottom: (isSelected ? AppSpacing.md.r : AppSpacing.sm.r) *
                  customizationController.densityFactor,
            ),
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.mRepliedOn != null && !isDeletedMessage)
                  Padding(
                    padding: EdgeInsets.only(right: 16.w, bottom: 4.h),
                    child: RepliedOnContainer(
                      messageId: message.mRepliedOn!,
                      replyColor: customizationController.replyTint,
                      textSize: customizationController.replySize.value,
                    ),
                  ),
                if (message.mStoryRef != null && !isDeletedMessage)
                  Padding(
                    padding: EdgeInsets.only(right: 16.w, bottom: 4.h),
                    child: StoryReferenceContainer(message: message),
                  ),
                ReactionBurstHost(
                  messageId: message.mId!,
                  reactionsJson: message.mReactions,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 16.w),
                        constraints: BoxConstraints(
                          maxWidth: customizationController.maxWidthFactor.sw,
                          minWidth: 0,
                        ),
                        decoration: customizationController.bubbleDecoration(
                          isMe: true,
                          isSelected: isSelected,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                          isMedia:
                              !isDeletedMessage && message.mMessageType != '0',
                        ),
                        child: Padding(
                          padding: customizationController.bubblePadding(
                            isMe: true,
                            isMedia: !isDeletedMessage &&
                                message.mMessageType != '0',
                          ),
                          child: IntrinsicWidth(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (customizationController
                                            .timestampPlacement.value ==
                                        'inside' &&
                                    customizationController
                                            .timestampPosition.value ==
                                        'top')
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _buildTimestampRow(
                                        message, true, context),
                                  ),
                                AnimatedSwitcher(
                                  duration: AppAnimation.normal,
                                  switchInCurve: AppAnimation.easeOut,
                                  switchOutCurve: AppAnimation.easeIn,
                                  child: isDeletedMessage
                                      ? _buildDeletedPlaceholder(
                                          context,
                                          isMe: true,
                                        )
                                      : Column(
                                          key: const ValueKey('content'),
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (message.mForwarded == '1')
                                              _buildForwardedBadge(),
                                            if (message.mMessageType == '0')
                                              _buildMessageBody(
                                                  context, message,
                                                  isMe: true)
                                            else
                                              AppHelper.checkFileType(
                                                mediaId: message.mId.toString(),
                                                roomId: message.mRoomId!,
                                                mediaUrl:
                                                    '${Endpoints.mediaBaseUrl}${message.mMedia}',
                                                fileType: message.mMessageType!,
                                                msg:
                                                    message.mMessage.toString(),
                                                messageId: message.mId,
                                              ),
                                            if (message.mIsEdited == '1')
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 2.h),
                                                child: Text(
                                                  'Edited',
                                                  style: AppTextStyles.chatTime
                                                      .copyWith(
                                                    color: CustomColor
                                                        .kTextTertiary,
                                                    fontStyle: FontStyle.italic,
                                                    fontSize: 10.sp,
                                                  ),
                                                ),
                                              ),
                                            if (message.isScheduledMessage)
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 2.h),
                                                child: _buildScheduleLabel(
                                                    message, true),
                                              ),
                                          ],
                                        ),
                                ),
                                if (customizationController
                                            .timestampPlacement.value ==
                                        'inside' &&
                                    customizationController
                                            .timestampPosition.value ==
                                        'bottom')
                                  Padding(
                                    padding: EdgeInsets.only(top: 2.h),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: _buildTimestampRow(
                                          message, true, context),
                                    ),
                                  ),
                                if (widget.isGroup &&
                                    !isDeletedMessage &&
                                    message.mSeenBy != null &&
                                    message.mSeenBy!.isNotEmpty &&
                                    message.mSeenBy != '[]')
                                  Padding(
                                    padding: EdgeInsets.only(top: 3.h),
                                    child: Text(
                                      'Read by ${_readByCount(message.mSeenBy!)}',
                                      style: AppTextStyles.chatTime.copyWith(
                                        color: CustomColor.kTextTertiary,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (customizationController.isPremiumStyle &&
                          message.mMessageType == '0')
                        Positioned.fill(
                          child: BrandBubbleArtwork(
                            radius: customizationController.bubbleRadius(
                                isMe: true),
                          ),
                        ),
                      if (customizationController.isPremiumStyle &&
                          message.mMessageType == '0')
                        _bubbleTail(
                          isMe: true,
                          isDark:
                              Theme.of(context).brightness == Brightness.dark,
                        ),
                      if (chatController.isMultiSelectMode.value)
                        Positioned(
                          left: -22.r,
                          top: 0,
                          child: _buildSelectionCheck(isSelected),
                        ),
                      if (isSelected)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ClipRRect(
                              borderRadius: customizationController
                                  .bubbleRadius(isMe: true),
                              child: Container(
                                color: customizationController.selection
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                        ),
                      if (!isDeletedMessage &&
                          message.mReactions != null &&
                          message.mReactions!.isNotEmpty)
                        Positioned(
                          bottom: -10.h,
                          right: 10.w,
                          child: MessageReactions(
                            messageId: message.mId!,
                            reactionsJson: message.mReactions,
                            isMe: true,
                            emojiSize: customizationController.emojiSize.value,
                            accentColor: customizationController.reaction,
                          ),
                        ),
                    ],
                  ),
                ),
                if (customizationController.timestampPlacement.value ==
                    'outside')
                  Padding(
                    padding: EdgeInsets.only(right: 16.w, top: 3.h),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildTimestampRow(message, true, context),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeletedPlaceholder(BuildContext context, {required bool isMe}) {
    final Color foreground = isMe
        ? (customizationController.isSentBubbleLight
            ? CustomColor.kTextSecondary
            : CustomColor.kTextOnDark.withValues(alpha: 0.85))
        : CustomColor.kTextTertiary;
    return Row(
      key: const ValueKey('deleted-message'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.block_rounded,
          size: 14.r,
          color: foreground.withValues(alpha: 0.9),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            isMe ? 'You deleted this message' : 'This message was deleted',
            style: AppTextStyles.bodyMd.copyWith(
              color: foreground,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
    );
  }

  /// Text bubble content. For a plain text message this returns the exact
  /// existing text rendering; when the message contains a URL it renders the
  /// typed text (if any) plus the tappable link preview card. The bubble
  /// chrome — alignment, colors, timestamp, status, reply, delete, reactions,
  /// selection — is untouched.
  Widget _buildMessageBody(
    BuildContext context,
    Messages message, {
    required bool isMe,
  }) {
    final textStyle = customizationController.messageTextStyle(
      isMe: isMe,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final Widget body = ConstrainedBox(
      constraints: BoxConstraints(minWidth: 60.w),
      child: (message.mMentions != null && message.mMentions!.isNotEmpty)
          ? MentionRichText(
              text: message.mMessage!,
              mentionIds: message.mMentions!,
              members: widget.isGroup
                  ? (groupController.groupData?.members ?? const <User>[])
                  : const <User>[],
              style: textStyle,
              highlightColor: isMe
                  ? CustomColor.kPrimaryColor.withValues(alpha: 0.20)
                  : customizationController.mention,
            )
          : Text(
              message.mMessage!,
              style: textStyle,
              softWrap: true,
            ),
    );

    final linkInfo = LinkPreviewService.extractLink(message.mMessage);
    if (linkInfo == null) return body;
    final isPlain =
        LinkPreviewService.isPlainUrlOnly(message.mMessage, linkInfo);
    final hasMentions =
        message.mMentions != null && message.mMentions!.isNotEmpty;
    final Widget? linkifiedBody = isPlain
        ? null
        : hasMentions
            ? body
            : ConstrainedBox(
                constraints: BoxConstraints(minWidth: 60.w),
                child: LinkifyBody(
                  text: message.mMessage!,
                  primary: linkInfo,
                  style: textStyle,
                  linkColor: isMe
                      ? CustomColor.kTextOnDark.withValues(alpha: 0.92)
                      : CustomColor.kPrimaryColor,
                ),
              );
    return LinkMessageContent(url: linkInfo.url, body: linkifiedBody);
  }

  void _showMessageInfo(Messages message) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      builder: (_) => MessageInfoSheet(messageId: message.mId!),
    );
  }

  bool _isPendingSchedule(Messages message) {
    final status = message.mStatus?.toString();
    return status == null ||
        status.isEmpty ||
        status == 'pending' ||
        status == '0';
  }

  String _scheduleStatusText(Messages message) {
    final status = message.mStatus?.toString();
    if (status == 'cancelled') return 'Cancelled';
    if (status == 'sent') return 'Sent';
    if (status == 'failed') return 'Failed';
    return 'Pending';
  }

  void _showScheduledMessageMenu(Messages message, {bool isMe = true}) {
    final isPending = _isPendingSchedule(message);
    final canManage = isPending && isMe;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9.r),
                    decoration: BoxDecoration(
                      gradient: CustomColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    ),
                    child: Icon(
                      Icons.schedule_send_rounded,
                      color: CustomColor.kTextOnDark,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Scheduled Message',
                      style: AppTextStyles.headingSm,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isPending
                          ? CustomColor.kPrimaryColor.withValues(alpha: 0.1)
                          : CustomColor.kTextTertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                    ),
                    child: Text(
                      _scheduleStatusText(message),
                      style: AppTextStyles.labelSm.copyWith(
                        color: isPending
                            ? CustomColor.kPrimaryColor
                            : CustomColor.kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: CustomColor.kUltraLightPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  border: Border.all(color: CustomColor.kLightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.mMessageType != '0'
                          ? AppHelper.getMediaName(
                              fileType: message.mMessageType ?? '')
                          : (message.mMessage?.trim().isNotEmpty ?? false)
                              ? message.mMessage!
                              : '(no message text)',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13.r,
                          color: CustomColor.kTextTertiary,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          AppHelper.formatDateTimeFromEpoch(
                            message.mScheduledAt ?? '0',
                            'EEE, MMM d, yyyy · h:mm a',
                          ),
                          style: AppTextStyles.labelSm
                              .copyWith(color: CustomColor.kTextTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              if (canManage) ...[
                _menuAction(
                  icon: Icons.edit_calendar_rounded,
                  label: 'Edit Schedule',
                  onTap: () => _editScheduledFromMenu(message),
                ),
                _menuAction(
                  icon: Icons.cancel_rounded,
                  label: 'Cancel Schedule',
                  color: CustomColor.kDangerRed,
                  onTap: () => _cancelScheduledFromMenu(message),
                ),
              ],
              _menuAction(
                icon: Icons.info_outline_rounded,
                label: 'Message Info',
                onTap: () {
                  Get.back();
                  _showMessageInfo(message);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final fg = color ?? CustomColor.kTextPrimary;
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: fg.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20.r, color: fg),
              SizedBox(width: 12.w),
              Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editScheduledFromMenu(Messages message) async {
    Get.back();
    await showAdaptiveDialog(
      context: context,
      builder: (_) => EditScheduleDialog(message: message),
    );
    if (!mounted) return;
    chatController.syncScheduledMessageFromList(message);
  }

  Future<void> _cancelScheduledFromMenu(Messages message) async {
    Get.back();
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        ),
        title: Text('Cancel schedule?', style: AppTextStyles.headingSm),
        content: Text(
          'This scheduled message will be cancelled. This can\'t be undone.',
          style:
              AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Keep it',
                style: AppTextStyles.bodyMd.copyWith(
                    color: CustomColor.kTextTertiary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Cancel schedule',
                style: AppTextStyles.bodyMd.copyWith(
                    color: CustomColor.kDangerRed,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    chatController.cancelScheduledMessageFromChat(message);
  }

  int _readByCount(String seenBy) {
    try {
      final list = jsonDecode(seenBy) as List<dynamic>? ?? [];
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildForwardedBadge() {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.double_arrow_rounded,
            size: 11.r,
            color: CustomColor.kTextTertiary,
          ),
          SizedBox(width: 3.w),
          Text(
            'Forwarded',
            style: AppTextStyles.labelSm.copyWith(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: CustomColor.kTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleLabel(Messages message, bool isMe) {
    final cancelled = message.mStatus?.toString() == 'cancelled';
    final fg = CustomColor.kTextTertiary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cancelled ? Icons.cancel_rounded : Icons.schedule_rounded,
            size: 10.r,
            color: fg,
          ),
          SizedBox(width: 3.w),
          Text(
            cancelled
                ? 'Scheduled · Cancelled'
                : 'Scheduled ${AppHelper.formatDateTimeFromEpoch(message.mScheduledAt!, 'dd MMM, h:mm a')}',
            style: AppTextStyles.labelSm.copyWith(
              color: fg,
              fontSize: 9.sp,
              decoration: cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(Messages message, bool isMe, BuildContext context) {
    final style = customizationController.timestampStyle(
      isMe: isMe,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.isScheduledMessage
              ? AppHelper.formatDateTimeFromEpoch(
                  message.mScheduledAt ?? '0',
                  isMe ? 'dd MMM h:mm a' : 'yyyy-MM-dd HH:mm:ss',
                )
              : AppHelper.formatSentTime(message),
          style: style,
        ),
        if (isMe) ...[
          SizedBox(width: AppSpacing.xs.w),
          _buildStatusTicks(
            message.mReadStatus.toString(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusTicks(String status) {
    // Ticks render slightly larger than the timestamp text for visibility.
    final size = (customizationController.timestampSize.value * 1.35).r;
    // The sent bubble is light by default — use a dark grey tick so it stays
    // visible; on custom dark bubbles fall back to a light grey.
    final bubbleLight = customizationController.isSentBubbleLight;
    final grey =
        bubbleLight ? CustomColor.kTextSecondary : CustomColor.kOverlay70;
    if (status == '0') {
      return Icon(
        Icons.schedule,
        size: size,
        color: bubbleLight
            ? CustomColor.kTextSecondary
            : CustomColor.kTextOnDark.withValues(alpha: 0.6),
      );
    }
    switch (status) {
      case '1':
        return Icon(Icons.check, size: size, color: grey);
      case '2':
        return Icon(Icons.done_all, size: size, color: grey);
      case '3':
        if (!customizationController.showReadReceipts.value) {
          return Icon(Icons.done_all, size: size, color: grey);
        }
        return Icon(
          Icons.done_all,
          size: size,
          color: customizationController.tick,
        );
      default:
        return Icon(Icons.check, size: size, color: grey);
    }
  }

  Widget _buildSelectionCheck(bool isSelected) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        width: 22.r,
        height: 22.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? CustomColor.kPrimaryColor
              : CustomColor.kTextOnDark.withValues(alpha: 0.95),
          border: Border.all(
            color: isSelected
                ? CustomColor.kPrimaryColor
                : CustomColor.kTextTertiary.withValues(alpha: 0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kScrim20,
              blurRadius: 4.r,
            ),
          ],
        ),
        child: isSelected
            ? Icon(Icons.check_rounded,
                size: 15.r, color: CustomColor.kTextOnDark)
            : null,
      ),
    );
  }

  Widget _premiumGlossOverlay({required bool isMe}) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: customizationController.bubbleRadius(isMe: isMe),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomColor.kTextOnDark.withValues(alpha: isMe ? 0.22 : 0.38),
                  CustomColor.kTextOnDark.withValues(alpha: isMe ? 0.06 : 0.12),
                  Colors.transparent,
                  CustomColor.kTextOnDark.withValues(alpha: isMe ? 0.10 : 0.18),
                ],
                stops: const [0.0, 0.28, 0.62, 0.86],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubbleTail({required bool isMe, required bool isDark}) {
    final color = isMe
        ? customizationController.sentTailColor
        : Color.lerp(
              customizationController.receivedBubbleColor(isDark),
              CustomColor.kTextOnDark,
              0.55,
            ) ??
            CustomColor.kTextOnDark;
    return Positioned(
      // WhatsApp-style: the tail connects to the bubble corner — its top
      // edge tucks under the bubble (same color, seamless) and the tip
      // points down at the corner.
      bottom: -6,
      left: isMe ? null : 6,
      right: isMe ? 6 : null,
      child: CustomPaint(
        size: Size(16.r, 11.r),
        painter: _WingTailPainter(color: color, isMe: isMe),
      ),
    );
  }
}

class _WingTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  _WingTailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    if (isMe) {
      // Sent tail — tucked under the bottom-right corner, rounded triangle
      // tip pointing down at the corner (WhatsApp-style).
      path.moveTo(0, 0);
      path.lineTo(w * 0.60, 0);
      path.quadraticBezierTo(w * 0.98, h * 0.25, w * 0.74, h * 0.90);
      path.quadraticBezierTo(w * 0.58, h * 1.04, w * 0.34, h * 0.88);
      path.quadraticBezierTo(w * 0.10, h * 0.55, w * 0.16, h * 0.08);
      path.quadraticBezierTo(w * 0.22, h * 0.02, 0, 0);
    } else {
      // Received tail — mirror, tucked under the bottom-left corner.
      path.moveTo(w * 0.40, 0);
      path.lineTo(w, 0);
      path.quadraticBezierTo(w * 0.02, h * 0.25, w * 0.26, h * 0.90);
      path.quadraticBezierTo(w * 0.42, h * 1.04, w * 0.66, h * 0.88);
      path.quadraticBezierTo(w * 0.90, h * 0.55, w * 0.84, h * 0.08);
      path.quadraticBezierTo(w * 0.78, h * 0.02, w * 0.40, 0);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WingTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isMe != isMe;
  }
}

class _ComposerRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ComposerRoundButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42.r,
        height: 42.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CustomColor.kUltraLightPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kScrim20,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 22.sp,
          color: CustomColor.kPrimaryColor,
        ),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.95,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
          splashColor: CustomColor.kPrimaryColor.withValues(alpha: 0.10),
          highlightColor: CustomColor.kPrimaryLight.withValues(alpha: 0.40),
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs.w, vertical: AppSpacing.lg.h),
            decoration: BoxDecoration(
              color: CustomColor.kUltraLightPrimaryColor,
              borderRadius: BorderRadius.circular(AppRadius.rounded.r),
              border: Border.all(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppIcons.huge.r,
                  height: AppIcons.huge.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: CustomColor.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon,
                      color: CustomColor.kWhite, size: AppIcons.xl.r),
                ),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: CustomColor.kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final List<_AttachmentOption> items;

  const _AttachmentRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Entrance(
              duration: AppAnimation.medium,
              delayFactor: i * 0.08,
              scale: true,
              child: items[i],
            ),
          ),
        ],
      ],
    );
  }
}

class _MultiSelectAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MultiSelectAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md.w, vertical: AppSpacing.sm.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? CustomColor.kDangerRed
                  : CustomColor.kPrimaryColor,
              size: AppIcons.lg.r,
            ),
            SizedBox(height: AppSpacing.xxs.h),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: isDestructive
                    ? CustomColor.kDangerRed
                    : CustomColor.kTextSecondary,
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final ChatController chatController;
  const _RecordingBar({required this.chatController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: AppShadow.elevatedLight,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => chatController.cancelRecording(),
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: CustomColor.kDangerRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.close_rounded,
                  size: AppIcons.lg.sp, color: CustomColor.kDangerRed),
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Obx(
            () => InkWell(
              onTap: () {
                if (chatController.isRecordingPaused.value) {
                  chatController.resumeRecording();
                } else {
                  chatController.pauseRecording();
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
              child: Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  border: Border.all(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  chatController.isRecordingPaused.value
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  size: AppIcons.lg.sp,
                  color: CustomColor.kPrimaryColor,
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: const BoxDecoration(
                    color: CustomColor.kDangerRed,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Obx(() => Text(
                      _formatDuration(chatController.recordingDuration.value),
                      style: AppTextStyles.headingSm,
                    )),
              ],
            ),
          ),
          InkWell(
            onTap: () => chatController.saveAudio(),
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                gradient: CustomColor.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.send_rounded,
                  size: 18.sp, color: CustomColor.kTextOnDark),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// WhatsApp-style swipeable message bubble.
/// Swipe right -> Reply composer. Swipe left -> Message info sheet.
class _SwipeableMessageBubble extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final VoidCallback onInfo;

  const _SwipeableMessageBubble({
    required this.child,
    required this.onReply,
    required this.onInfo,
  });

  @override
  State<_SwipeableMessageBubble> createState() =>
      _SwipeableMessageBubbleState();
}

class _SwipeableMessageBubbleState extends State<_SwipeableMessageBubble>
    with SingleTickerProviderStateMixin {
  static const double _maxSwipe = 90;
  static const double _triggerThreshold = 60;

  late final AnimationController _controller;
  late final Animation<double> _slide;
  double _dragOffset = 0;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 320),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_direction > 0) {
            widget.onReply();
          } else {
            widget.onInfo();
          }
          Future.delayed(const Duration(milliseconds: 160), _reset);
        }
      });
    _slide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final next = (_dragOffset + details.delta.dx).clamp(-_maxSwipe, _maxSwipe);
    if (next != _dragOffset) {
      setState(() => _dragOffset = next);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _triggerThreshold) {
      _direction = _dragOffset > 0 ? 1 : -1;
      _controller
        ..value = _dragOffset.abs() / _maxSwipe
        ..forward();
    } else {
      _controller
        ..value = _dragOffset.abs() / _maxSwipe
        ..reverse();
    }
  }

  void _reset() {
    if (!mounted) return;
    setState(() => _dragOffset = 0);
    _controller.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) {
          final dx = _dragOffset != 0
              ? _dragOffset
              : (_slide.value * _maxSwipe * _direction);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// Shown in place of the composer when the signed-in user is no longer a
/// member of the group. History stays readable; new messages are blocked.
class _NonMemberBanner extends StatelessWidget {
  const _NonMemberBanner();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18.r,
            color: dark
                ? CustomColor.kTextOnDarkMuted
                : CustomColor.kTextSecondary,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              'You can no longer send messages to this group.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: dark
                    ? CustomColor.kTextOnDarkMuted
                    : CustomColor.kTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
