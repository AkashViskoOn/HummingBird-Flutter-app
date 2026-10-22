import 'dart:async';
import 'dart:io';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/components/chat_ui/record_audio_anim.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/Models/composer_media_item.dart';
import 'package:humming_bird/components/schedule/schedule_recipient_sheet.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/media_image_editor_screen.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/emoji_picker.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';

/// Create Schedule — premium light composer for scheduling message + media
/// into an existing conversation.
///
/// Everything connects to the existing [ChatController] schedule pipeline
/// (`pickedDate`/`pickedTime` → `setDateAndTime(fromScheduleScreen: true)` →
/// `sendMessage` → `MessageApi` → backend). Picked media is staged into
/// `composerItems` and sent through `sendComposerMedia(isScheduled: true)`.
/// No parallel systems.
class ScheduleScreen extends StatefulWidget {
  final String name;
  final String roomId;
  final String receiverId;
  final String roomUsers;
  final bool forGroup;
  final String? messageContext;
  const ScheduleScreen(
      {super.key,
      required this.name,
      required this.roomId,
      required this.receiverId,
      required this.roomUsers,
      this.forGroup = false,
      this.messageContext});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  late ChatController chatController;
  late GroupController groupController;

  final _scrollController = ScrollController();
  final _messageFocus = FocusNode();
  final _msgKey = GlobalKey();
  final _dtKey = GlobalKey();
  final _repeatKey = GlobalKey();
  StreamSubscription<List<ComposerMediaItem>>? _composerSub;

  bool _advancedExpanded = false;
  String? _msgError;
  String? _dateError;
  String? _timeError;

  /// Recipients this schedule will be delivered to. Single by default; the
  /// "To" card opens [ScheduleRecipientSheet] in multi-select mode so the
  /// user can pick several people and the screen keeps its typed content.
  late List<ScheduleRecipient> _recipients;

  // ── Theme-aware palette ── light stays as-is; dark maps to the app's
  // dark surfaces/text. All screens use the same constants (see app_theme.dart).
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg =>
      _isDark ? CustomColor.kDarkBackground : CustomColor.kBackground;
  Color get _cardBg =>
      _isDark ? CustomColor.kDarkSurface : CustomColor.kCardBackground;
  Color get _surface2 =>
      _isDark ? CustomColor.kDarkSurface2 : CustomColor.kLightSurface2;
  Color get _inputFill =>
      _isDark ? CustomColor.kDarkInputFill : CustomColor.kUltraLightBg;
  Color get _border =>
      _isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
  Color get _text1 =>
      _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
  Color get _text2 =>
      _isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
  Color get _text3 =>
      _isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

  static const _intervalLabels = {
    0: 'Once',
    1: 'Daily',
    2: 'Weekly',
    3: 'Monthly',
    4: 'Yearly',
  };

  String get _dateValue => chatController.dateController.text.trim();
  String get _timeValue => chatController.timeController.text.trim();
  bool get _hasScheduleDateTime =>
      _dateValue.isNotEmpty && _timeValue.isNotEmpty;

  DateTime? _resolvedScheduledAt() {
    final d = chatController.pickedDate;
    final t = chatController.pickedTime;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool get _isFutureSchedule =>
      (_resolvedScheduledAt()?.isAfter(DateTime.now()) ?? false);

  @override
  void initState() {
    chatController = Get.find();
    groupController = Get.find();
    chatController.textMessageController = TextEditingController();
    chatController.scheduleOn = true;
    chatController.scheduleMessageContext = widget.messageContext;
    chatController.selectedContactId.value = widget.receiverId;
    _recipients = [
      ScheduleRecipient(
        roomId: widget.roomId,
        receiverId: widget.receiverId,
        roomUsers: widget.roomUsers,
        name: widget.name,
        subtitle: widget.forGroup ? 'Group chat' : 'Direct message',
        imagePath: widget.forGroup
            ? null
            : (widget.roomUsers.isNotEmpty ? widget.roomUsers : null),
        isGroup: widget.forGroup,
        recency: 0,
      ),
    ];
    chatController.dateController.addListener(_onScheduleFieldChanged);
    chatController.timeController.addListener(_onScheduleFieldChanged);
    chatController.textMessageController.addListener(_onTextChanged);
    _composerSub =
        chatController.composerItems.listen((_) => _onComposerChanged());
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    if (MediaQuery.of(context).viewInsets.bottom > 0 &&
        chatController.showEmojiPicker.value) {
      chatController.showEmojiPicker.value = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    chatController.dateController.removeListener(_onScheduleFieldChanged);
    chatController.timeController.removeListener(_onScheduleFieldChanged);
    chatController.textMessageController.removeListener(_onTextChanged);
    _composerSub?.cancel();
    chatController.textMessageController.clear();
    _scrollController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _onComposerChanged() {
    if (!mounted) return;
    if (_msgError != null && chatController.composerItems.isNotEmpty) {
      setState(() => _msgError = null);
    }
  }

  void _onTextChanged() {
    if (_msgError != null &&
        chatController.textMessageController.text.trim().isNotEmpty) {
      setState(() => _msgError = null);
    }
  }

  void _onScheduleFieldChanged() {
    if (!mounted) return;
    setState(() {
      if (_dateValue.isNotEmpty) _dateError = null;
      if (_timeValue.isNotEmpty) _timeError = null;
    });
  }

  void _resetScheduleState() {
    chatController.scheduleOn = false;
    chatController.isScheduledMessage.value = '0';
    chatController.selectedContactId.value = '0';
    chatController.selectedInterval.value = 0;
    chatController.scheduleCount.value = 0;
    chatController.dateController.clear();
    chatController.timeController.clear();
    chatController.clearComposer();
  }

  void _closeEmojiIfOpen() {
    if (chatController.showEmojiPicker.value) {
      chatController.showEmojiPicker.value = false;
    }
  }

  // ───────────────────────────────────────────────────────── Semantic keys

  void _scrollToField(String field) {
    final key = field == 'message' ? _msgKey : _dtKey;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // ────────────────────────────────────────────────────── Date / time pick

  Future<void> _pickDate() async {
    _closeEmojiIfOpen();
    final now = DateTime.now();
    final initial = (chatController.pickedDate?.isAfter(now) ?? false)
        ? chatController.pickedDate!
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(2100),
      barrierDismissible: false,
      helpText: 'Select scheduling date',
    );
    if (picked == null || !mounted) return;
    chatController.pickedDate = picked;
    chatController.dateController.text =
        DateFormat('EEE, d MMM yyyy').format(picked);
  }

  Future<void> _pickTime() async {
    _closeEmojiIfOpen();
    final picked = await showTimePicker(
      context: context,
      initialTime: chatController.pickedTime ?? TimeOfDay.now(),
      helpText: 'Select scheduling time',
    );
    if (picked == null || !mounted) return;
    chatController.pickedTime = picked;
    chatController.timeController.text = picked.format(context);
    if (mounted && !_isFutureSchedule) {
      setState(() => _timeError = 'Please select a future time');
    }
  }

  // ───────────────────────────────────────────────────────────── Repeat

  static const _repeatOptions = [
    (0, 'Once', 'Send this message a single time'),
    (1, 'Daily', 'Repeat every day'),
    (2, 'Weekly', 'Repeat every week'),
    (3, 'Monthly', 'Repeat every month'),
    (4, 'Yearly', 'Repeat every year'),
  ];

  Future<void> _openRepeatSheet() async {
    _closeEmojiIfOpen();
    FocusManager.instance.primaryFocus?.unfocus();
    final sel = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) =>
          _RepeatSheet(initial: chatController.selectedInterval.value),
    );
    if (sel != null && mounted) {
      chatController.selectScheduleInterval(sel);
      setState(() {});
    }
  }

  // ─────────────────────────────────────────────────── Media / Audio

  void _openMediaSheet() {
    if (!_hasScheduleDateTime) {
      Utils.showGetSnackBar('Please pick scheduling date and time first');
      return;
    }
    _closeEmojiIfOpen();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: 22.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add media to your schedule',
                  style: TextStyle(
                    color: _text1,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              _mediaTile(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  chatController.pickCamera(fromScheduleScreen: true);
                },
              ),
              _mediaTile(
                icon: Icons.photo_outlined,
                label: 'Photo',
                onTap: () {
                  Navigator.pop(context);
                  chatController.pickFile(FileType.image, 1,
                      fromScheduleScreen: true);
                },
              ),
              _mediaTile(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: () {
                  Navigator.pop(context);
                  chatController.pickFile(FileType.video, 4,
                      fromScheduleScreen: true);
                },
              ),
              _mediaTile(
                icon: Icons.description_outlined,
                label: 'Document',
                onTap: () {
                  Navigator.pop(context);
                  chatController.pickFile(FileType.any, 2,
                      fromScheduleScreen: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaTile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                border: Border.all(color: _border),
              ),
              child: Icon(icon, color: CustomColor.kPrimaryColor, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                color: _text2,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: _text3, size: 20.r),
          ],
        ),
      ),
    );
  }

  void _onAudioTap() {
    if (!_hasScheduleDateTime) {
      Utils.showGetSnackBar('Please pick scheduling date and time first');
      return;
    }
    _closeEmojiIfOpen();
    chatController.recordAudio();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecordAudioAnim(),
    );
  }

  // ─────────────────────────────────────────────────────────── Submit

  void _schedule() {
    if (!ConnectivityService.to.isOnline.value) {
      Utils.showGetSnackBar(
          "You're offline. Scheduling will work once you're back online.");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    _closeEmojiIfOpen();

    final hasText = chatController.textMessageController.text.trim().isNotEmpty;
    final hasMedia = chatController.composerItems.isNotEmpty;
    final scheduledAt = _resolvedScheduledAt();

    setState(() {
      _msgError =
          (!hasText && !hasMedia) ? 'Enter a message or add media' : null;
      _dateError = _dateValue.isEmpty ? 'Please select a date' : null;
      if (_timeValue.isEmpty) {
        _timeError = 'Please select a time';
      } else if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
        _timeError = 'Please select a future time';
      } else {
        _timeError = null;
      }
    });

    String? firstError;
    if (_msgError != null) {
      firstError = 'message';
    } else if (_dateError != null) {
      firstError = 'date';
    } else if (_timeError != null) {
      firstError = 'time';
    }
    if (firstError != null) {
      _scrollToField(firstError);
      return;
    }

    if (scheduledAt == null || !scheduledAt.isAfter(DateTime.now())) {
      setState(() => _timeError = 'Please select a future time');
      _scrollToField('time');
      return;
    }

    final when = scheduledAt;

    final recipients = List<ScheduleRecipient>.from(_recipients);
    if (recipients.isEmpty) {
      Utils.showGetSnackBar('Please select a recipient');
      return;
    }

    final text = chatController.textMessageController.text;
    final media = List<ComposerMediaItem>.from(chatController.composerItems);

    // Re-arm the shared ChatController schedule state for one recipient.
    // Per-recipient sends clear these afterwards, so each iteration restores
    // them from the single (date, time) pair picked on this screen.
    void armSchedule() {
      chatController.pickedDate = DateTime(when.year, when.month, when.day);
      chatController.pickedTime =
          TimeOfDay(hour: when.hour, minute: when.minute);
      chatController.scheduledMessageDateTime = when;
      chatController.isScheduledMessage.value = '1';
    }

    Future<void> dispatch() async {
      try {
        for (var i = 0; i < recipients.length; i++) {
          final r = recipients[i];
          chatController.selectedRoom.value = r.roomId;
          chatController.selectedContactId.value = r.receiverId;

          if (hasText) {
            armSchedule();
            // sendMessage clears the composer field after reading it, so
            // restore the text before every recipient's send.
            chatController.textMessageController.text = text;
            await chatController.sendMessage(fromScheduledScreen: true);
          }
          if (hasMedia) {
            armSchedule();
            // sendComposerMedia consumes composerItems, so re-stage them for
            // every recipient after the first one.
            if (i > 0) chatController.composerItems.addAll(media);
            await chatController.sendComposerMedia(isScheduled: true);
          }
        }
      } finally {
        if (mounted) {
          _resetScheduleState();
          Get.back();
        }
      }
    }

    unawaited(dispatch());
  }

  // ──────────────────────────────────────────────────── Small builders

  String _initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.length >= 2 ? s.substring(0, 2) : s).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _avatar() {
    final primary = _recipients.isNotEmpty ? _recipients.first : null;
    ImageProvider? image;
    if (primary != null) {
      if (primary.isGroup) {
        image = groupController.getGroupImage(primary.roomId);
      } else if (primary.imagePath?.isNotEmpty ?? false) {
        image = CachedNetworkImageProvider(
            '${Endpoints.mediaBaseUrl}${primary.imagePath}');
      }
    }
    return Container(
      width: 46.r,
      height: 46.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? [CustomColor.kDarkSurface2, CustomColor.kDarkSurface3]
              : [CustomColor.kUltraLightBg, CustomColor.kLightSurface2],
        ),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Text(
              _initialsOf(primary?.name ?? '?'),
              style: TextStyle(
                color: _text2,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (image != null)
            Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardStyle() => BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        border: Border.all(color: _border),
      );

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _sectionHeader(String title,
      {String? trailing, Widget? trailingWidget}) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 9.h),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 14.h,
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xxs.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: _text2,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          trailingWidget ??
              (trailing != null
                  ? Text(
                      trailing,
                      style: TextStyle(
                        color: _text3,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _fieldError(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: 6.h, left: 4.w),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 13.r, color: CustomColor.kDangerRed),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              error,
              style: TextStyle(
                color: CustomColor.kDangerRed,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────── Header

  Widget _buildHeader() {
    return Entrance(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.section.w,
          AppSpacing.xl.h,
          AppSpacing.section.w,
          AppSpacing.xl.h,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CustomColor.kPrimaryColor,
              CustomColor.kPrimaryMedium,
            ],
          ),
        ),
        child: Row(
          children: [
            const AppBackButton(color: CustomColor.kTextOnDark),
            SizedBox(width: AppSpacing.xl.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Schedule',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CustomColor.kTextOnDark,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    'Send your message at the perfect time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CustomColor.kTextOnDark.withValues(alpha: 0.78),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm.w),
            PressScale(
              child: Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: CustomColor.kTextOnDark.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  border: Border.all(
                    color: CustomColor.kTextOnDark.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: CustomColor.kTextOnDark,
                  size: 21.r,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────── Connection status

  Widget _buildConnectionBar() {
    return Obx(() {
      final online = ConnectivityService.to.isOnline.value;
      final sock = chatController.socketConnectionState.value;

      final Color accent;
      final IconData icon;
      final String title;
      final String subtitle;
      if (!online) {
        accent = CustomColor.kWarning;
        icon = Icons.wifi_off_rounded;
        title = "You're offline";
        subtitle = "Scheduling resumes when you're back online";
      } else {
        switch (sock) {
          case SocketConnectionState.connected:
            accent = CustomColor.kSuccess;
            icon = Icons.bolt_rounded;
            title = 'Connected';
            subtitle = 'Live connection active';
          case SocketConnectionState.reconnecting:
            accent = CustomColor.kWarning;
            icon = Icons.sync_rounded;
            title = 'Reconnecting...';
            subtitle = "We're getting you back online";
          case SocketConnectionState.disconnected:
            accent = CustomColor.kWarning;
            icon = Icons.wifi_off_rounded;
            title = 'Disconnected';
            subtitle = 'Scheduling resumes when reconnected';
          default:
            accent = CustomColor.kInfo;
            icon = Icons.sync_rounded;
            title = 'Connecting...';
            subtitle = '';
        }
      }

      return Entrance(
        delayFactor: 0.05,
        child: Container(
          margin: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _surface2,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Icon(icon, color: accent, size: 17.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _text1,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 1.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _text3,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────── Recipient card

  Widget _buildRecipientCard() {
    return Entrance(
      delayFactor: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'To',
            trailing: _recipients.length > 1
                ? '${_recipients.length} recipients'
                : null,
          ),
          PressScale(
            child: InkWell(
              onTap: () async {
                _closeEmojiIfOpen();
                FocusManager.instance.primaryFocus?.unfocus();
                final picked = await ScheduleRecipientSheet.show(
                  context,
                  initial: _recipients,
                  selectMode: true,
                );
                if (picked != null && picked.isNotEmpty && mounted) {
                  setState(() => _recipients = picked);
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: _cardStyle(),
                child: Row(
                  children: [
                    _avatar(),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _recipients.isNotEmpty
                                ? _recipients.first.name
                                : 'No recipient',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _text1,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Builder(builder: (context) {
                            if (_recipients.length > 1) {
                              return Text(
                                'Will be scheduled to ${_recipients.length} people',
                                style: TextStyle(
                                  color: CustomColor.kPrimaryMedium,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            final primary = _recipients.isNotEmpty
                                ? _recipients.first
                                : null;
                            final members = (primary?.isGroup ?? false)
                                ? groupController.groupData?.members?.length
                                : null;
                            final subtitle = (primary?.isGroup ?? false)
                                ? ((members ?? 0) > 0
                                    ? '$members members'
                                    : 'Group chat')
                                : 'Direct message';
                            return Text(
                              subtitle,
                              style: TextStyle(
                                color: _text3,
                                fontSize: 12.sp,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                        border: Border.all(
                            color: CustomColor.kPrimaryColor
                                .withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_outlined,
                              size: 14.r, color: CustomColor.kPrimaryMedium),
                          if (_recipients.length > 1) ...[
                            SizedBox(width: 4.w),
                            Text(
                              '${_recipients.length}',
                              style: TextStyle(
                                color: CustomColor.kPrimaryMedium,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.chevron_right,
                      color: _text3,
                      size: 20.r,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────── Message composer

  Widget _buildMessageComposer() {
    return Entrance(
      delayFactor: 0.15,
      child: Column(
        key: _msgKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: chatController.textMessageController,
            builder: (_, value, __) => _sectionHeader(
              'Message',
              trailing: '${value.text.length}/1000',
            ),
          ),
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: _cardStyle()
                .copyWith(border: Border.all(color: kFieldBorderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: chatController.textMessageController,
                  focusNode: _messageFocus,
                  onTap: _closeEmojiIfOpen,
                  keyboardType: TextInputType.multiline,
                  maxLength: 1000,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          required maxLength}) =>
                      null,
                  minLines: 3,
                  maxLines: 6,
                  style: TextStyle(
                    color: _text1,
                    fontSize: 14.sp,
                    height: 1.45,
                  ),
                  cursorColor: CustomColor.kPrimaryColor,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: _text3,
                      fontSize: 14.sp,
                    ),
                    filled: true,
                    fillColor: _inputFill,
                    isDense: true,
                    contentPadding: EdgeInsets.all(14.r),
                    border: _fieldBorder(Colors.transparent),
                    enabledBorder: _fieldBorder(
                      _msgError != null
                          ? CustomColor.kDangerRed.withValues(alpha: 0.6)
                          : _border,
                    ),
                    focusedBorder: _fieldBorder(
                      CustomColor.kPrimaryColor.withValues(alpha: 0.8),
                      width: 1.4,
                    ),
                  ),
                ),
                _fieldError(_msgError),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BorderSide get kFieldBorderSide => BorderSide(color: _border);
  Color get kFieldBorderColor => _border;

  // ──────────────────────────────────────────────── Date & Time card

  Widget _buildDateTimeCard() {
    return Entrance(
      delayFactor: 0.2,
      child: Column(
        key: _dtKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Schedule Date & Time'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _pickTile(
                  isDate: true,
                  icon: Icons.calendar_month,
                  value: _dateValue,
                  placeholder: 'Select date',
                  onTap: _pickDate,
                  error: _dateError,
                ),
              ),
              SizedBox(width: AppSpacing.lg.w),
              Expanded(
                child: _pickTile(
                  isDate: false,
                  icon: Icons.access_time_rounded,
                  value: _timeValue,
                  placeholder: 'Select time',
                  onTap: _pickTime,
                  error: _timeError,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickTile({
    required bool isDate,
    required IconData icon,
    required String value,
    required String placeholder,
    required VoidCallback onTap,
    String? error,
  }) {
    final filled = value.isNotEmpty;
    final borderColor = error != null
        ? CustomColor.kDangerRed.withValues(alpha: 0.6)
        : filled
            ? CustomColor.kPrimaryColor.withValues(alpha: 0.45)
            : _border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PressScale(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            child: Container(
              height: 66.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _inputFill,
                borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      gradient: CustomColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.lg.r),
                    ),
                    child:
                        Icon(icon, color: CustomColor.kTextOnDark, size: 17.r),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: Text(
                      value.isEmpty ? placeholder : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: value.isEmpty ? _text3 : _text1,
                        fontSize: 13.sp,
                        fontWeight:
                            value.isEmpty ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(Icons.chevron_right, color: _text3, size: 18.r),
                ],
              ),
            ),
          ),
        ),
        _fieldError(error),
      ],
    );
  }

  // ─────────────────────────────────────────────────── Repeat card

  Widget _buildRepeatCard() {
    return Entrance(
      delayFactor: 0.25,
      child: Column(
        key: _repeatKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Repeat'),
          PressScale(
            child: InkWell(
              onTap: _openRepeatSheet,
              borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                decoration: _cardStyle(),
                child: Row(
                  children: [
                    Icon(Icons.repeat_rounded,
                        color: CustomColor.kPrimaryColor, size: 20.r),
                    SizedBox(width: 12.w),
                    Text(
                      'How often?',
                      style: TextStyle(
                        color: _text2,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Obx(() {
                      final label = _intervalLabels[
                              chatController.selectedInterval.value] ??
                          'Once';
                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: CustomColor.kPrimaryColor
                                  .withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xxxl.r),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                color: CustomColor.kPrimaryMedium,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Icon(Icons.chevron_right, color: _text3, size: 19.r),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────── Advanced options

  Widget _buildAdvancedOptions() {
    return Entrance(
      delayFactor: 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Advanced Options'),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: _cardStyle(),
            child: Column(
              children: [
                PressScale(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _advancedExpanded = !_advancedExpanded),
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              color: CustomColor.kPrimaryColor, size: 19.r),
                          SizedBox(width: 12.w),
                          Text(
                            'Repeat message',
                            style: TextStyle(
                              color: _text1,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' (Optional)',
                            style: TextStyle(
                              color: _text3,
                              fontSize: 12.sp,
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _advancedExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Icon(Icons.expand_more,
                                color: _text3, size: 22.r),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _advancedExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 1.h,
                        color: _border,
                        thickness: 0.6,
                      ),
                      SizedBox(height: 14.h),
                      Obx(() {
                        final forever = chatController.scheduleCount.value == 0;
                        final repeatActive =
                            chatController.selectedInterval.value != 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How many times should the message repeat?',
                              style: TextStyle(
                                color: _text2,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                PressScale(
                                  child: InkWell(
                                    onTap: repeatActive
                                        ? () => chatController
                                            .scheduleCount.value = 0
                                        : null,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.fourteen.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.fourteen.r),
                                        border: Border.all(
                                          color: forever
                                              ? CustomColor.kPrimaryColor
                                                  .withValues(alpha: 0.6)
                                              : _border,
                                        ),
                                        color: forever
                                            ? CustomColor.kPrimaryColor
                                                .withValues(alpha: 0.16)
                                            : Colors.transparent,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            forever
                                                ? Icons.check_circle_rounded
                                                : Icons.circle_outlined,
                                            size: 18.r,
                                            color: forever
                                                ? CustomColor.kPrimaryColor
                                                : _text3,
                                          ),
                                          SizedBox(width: 7.w),
                                          Text(
                                            'Forever',
                                            style: TextStyle(
                                              color: forever ? _text1 : _text3,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _stepperButton(
                                  icon: Icons.remove,
                                  enabled: repeatActive && !forever,
                                  onTap: () {
                                    final current =
                                        chatController.scheduleCount.value;
                                    chatController.scheduleCount.value =
                                        current <= 1 ? 0 : current - 1;
                                  },
                                ),
                                SizedBox(width: 10.w),
                                SizedBox(
                                  width: 38.w,
                                  child: Obx(() => AnimatedFlipCounter(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        value:
                                            chatController.scheduleCount.value,
                                        textStyle: TextStyle(
                                          color: _text1,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )),
                                ),
                                SizedBox(width: 10.w),
                                _stepperButton(
                                  icon: Icons.add,
                                  enabled: repeatActive,
                                  onTap: () {
                                    final current =
                                        chatController.scheduleCount.value;
                                    chatController.scheduleCount.value =
                                        current == 0 ? 1 : current + 1;
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSummary() {
    if (!_hasScheduleDateTime) return const SizedBox.shrink();

    final scheduledAt = _resolvedScheduledAt();
    if (scheduledAt == null) return const SizedBox.shrink();

    final label = DateFormat('EEE, d MMM • h:mm a').format(scheduledAt);

    return Entrance(
      delayFactor: 0.22,
      child: Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              CustomColor.kPrimaryColor.withValues(alpha: 0.12),
              CustomColor.kPrimaryMedium.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
          border: Border.all(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                gradient: CustomColor.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: CustomColor.kTextOnDark,
                size: 18.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled delivery',
                    style: TextStyle(
                      color: _text2,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    label,
                    style: TextStyle(
                      color: _text1,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return PressScale(
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? _surface2 : _surface2.withValues(alpha: 0.4),
            border: Border.all(
              color: enabled ? _border : _border.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            icon,
            size: 17.r,
            color: enabled ? _text2 : _text3.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────── Attachment action bar

  // ─────────────────────────────────────────── Staged media preview

  Widget _buildMediaPreview() {
    return Obx(() {
      final items = chatController.composerItems;
      if (items.isEmpty) return const SizedBox.shrink();
      return Entrance(
        delayFactor: 0.3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Attachments (${items.length})',
              trailingWidget: PressScale(
                child: InkWell(
                  onTap: chatController.clearComposer,
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline,
                            size: 14.r, color: CustomColor.kDangerRed),
                        SizedBox(width: 4.w),
                        Text(
                          'Clear all',
                          style: TextStyle(
                            color: CustomColor.kDangerRed,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [for (final item in items) _buildMediaThumb(item)],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMediaThumb(ComposerMediaItem item) {
    const thumb = 74.0;
    return PressScale(
      pressedScale: 0.95,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: thumb.r,
            height: thumb.r,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _inputFill,
              borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              border: Border.all(color: _border),
            ),
            child: item.isImage
                ? Image.file(
                    item.file,
                    width: thumb.r,
                    height: thumb.r,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: item.isVideo
                        ? Icon(Icons.videocam_rounded,
                            size: 26.r, color: CustomColor.kPrimaryColor)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 24.r,
                                  color: CustomColor.kPrimaryMedium),
                              SizedBox(height: 4.h),
                              Text(
                                item.file.path.split('.').last.toUpperCase(),
                                style: TextStyle(
                                  color: _text3,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
          Positioned(
            top: -6.r,
            right: -6.r,
            child: InkWell(
              onTap: () => chatController.removeComposerItem(item.id),
              borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
              child: Container(
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  color: _isDark ? CustomColor.kDarkSurface3 : _text1,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: CustomColor.kTextOnDark, width: 1.5),
                ),
                child: Icon(Icons.close_rounded,
                    size: 13.r, color: CustomColor.kTextOnDark),
              ),
            ),
          ),
          if (item.isImage)
            Positioned(
              bottom: -6.r,
              right: -6.r,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                onTap: () async {
                  final File? edited = await Get.to<File?>(
                    () => MediaImageEditorScreen(item: item),
                  );
                  if (edited != null) {
                    item.file = edited;
                    chatController.composerItems.refresh();
                  }
                },
                child: Container(
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryColor,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: CustomColor.kTextOnDark, width: 1.5),
                  ),
                  child: Icon(Icons.edit_rounded,
                      size: 13.r, color: CustomColor.kTextOnDark),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentBar() {
    return Entrance(
      delayFactor: 0.35,
      child: Row(
        children: [
          Expanded(
            child: _attachmentTile(
              icon: Icons.image_outlined,
              label: 'Media',
              onTap: _openMediaSheet,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: _attachmentTile(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: () {
                if (!_hasScheduleDateTime) {
                  Utils.showGetSnackBar(
                      'Please pick scheduling date and time first');
                  return;
                }
                _closeEmojiIfOpen();
                chatController.pickCamera(fromScheduleScreen: true);
              },
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: _attachmentTile(
              icon: Icons.mic_none_rounded,
              label: 'Audio',
              onTap: _onAudioTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attachmentTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            color: active
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.12)
                : _surface2,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(
              color: active
                  ? CustomColor.kPrimaryColor.withValues(alpha: 0.45)
                  : _border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: active
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kPrimaryMedium,
                  size: 20.r),
              SizedBox(height: 5.h),
              Text(
                label,
                style: TextStyle(
                  color: active ? CustomColor.kPrimaryColor : _text1,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────── Footer / CTA

  Widget _buildFooter() {
    final mq = MediaQuery.of(context);
    final bottomPad =
        mq.viewInsets.bottom > 0 ? mq.viewInsets.bottom : mq.padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.section.w,
        AppSpacing.lg.h,
        AppSpacing.section.w,
        bottomPad + AppSpacing.xl.h,
      ),
      decoration: BoxDecoration(
        color: _surface2,
        border: Border(
          top: BorderSide(color: _border.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chatController.showEmojiPicker.value)
              const EmojiPickerSheet()
            else
              Obx(() {
                final online = ConnectivityService.to.isOnline.value;
                return PressScale(
                  pressedScale: 0.98,
                  child: InkWell(
                    onTap: online ? _schedule : null,
                    borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
                    child: Semantics(
                      button: true,
                      enabled: online,
                      label: 'Schedule Message',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        height: 52.h,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: online ? CustomColor.primaryGradient : null,
                          color: online ? null : _cardBg,
                          borderRadius:
                              BorderRadius.circular(AppRadius.eighteen.r),
                          boxShadow: online
                              ? [
                                  BoxShadow(
                                    color: CustomColor.kPrimaryGlow,
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!online) ...[
                              Icon(Icons.cloud_off_rounded,
                                  color: _text3, size: 18.r),
                              SizedBox(width: 8.w),
                            ],
                            Text(
                              online ? 'Schedule Message' : "You're offline",
                              style: TextStyle(
                                color:
                                    online ? CustomColor.kTextOnDark : _text3,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────── build

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !chatController.showEmojiPicker.value,
        onPopInvokedWithResult: (didPop, _) {
          if (chatController.showEmojiPicker.value) {
            chatController.showEmojiPicker.value = false;
            return;
          }
          if (didPop) _resetScheduleState();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: _bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                _buildConnectionBar(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 28.h),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        _buildRecipientCard(),
                        SizedBox(height: 20.h),
                        _buildDateTimeCard(),
                        _buildScheduleSummary(),
                        SizedBox(height: 20.h),
                        _buildMessageComposer(),
                        SizedBox(height: 20.h),
                        _buildRepeatCard(),
                        SizedBox(height: 20.h),
                        _buildAdvancedOptions(),
                        SizedBox(height: 22.h),
                        _buildMediaPreview(),
                        if (chatController.composerItems.isNotEmpty)
                          SizedBox(height: 22.h),
                        _buildAttachmentBar(),
                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Repeat selection bottom sheet — reuses the existing ChatController
// interval enum (0=Once,1=Daily,2=Weekly,3=Monthly,4=Yearly) via
// `selectScheduleInterval`.
// ────────────────────────────────────────────────────────────────────────

class _RepeatSheet extends StatefulWidget {
  final int initial;
  const _RepeatSheet({required this.initial});

  @override
  State<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends State<_RepeatSheet> {
  late int _selected = widget.initial;

  // Same dark/light palette as _ScheduleScreenState.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface2 =>
      _isDark ? CustomColor.kDarkSurface2 : CustomColor.kLightSurface2;
  Color get _border =>
      _isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
  Color get _text1 =>
      _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
  Color get _text3 =>
      _isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, bottomPad + 20.h),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'Repeat',
              style: TextStyle(
                color: _text1,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Choose how often this message is sent.',
              style: TextStyle(
                color: _text3,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 16.h),
            for (final option in _ScheduleScreenState._repeatOptions)
              _optionTile(option.$1, option.$2, option.$3),
            SizedBox(height: 18.h),
            PressScale(
              pressedScale: 0.98,
              child: InkWell(
                onTap: () => Navigator.pop(context, _selected),
                borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
                child: Container(
                  height: 50.h,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: CustomColor.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
                    boxShadow: [
                      BoxShadow(
                        color: CustomColor.kPrimaryGlow,
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'Apply',
                    style: TextStyle(
                      color: CustomColor.kTextOnDark,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(int value, String label, String subtitle) {
    final sel = _selected == value;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        onTap: () => setState(() => _selected = value),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: sel
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(
              color: sel
                  ? CustomColor.kPrimaryColor.withValues(alpha: 0.55)
                  : _border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: sel ? CustomColor.kPrimaryColor : _text3,
                size: 22.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: _text1,
                        fontSize: 14.sp,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _text3,
                        fontSize: 11.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
