import 'package:flutter/material.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/schedule/ai_schedule_parser.dart';
import 'package:humming_bird/components/schedule/animated_schedule_card.dart';
import 'package:humming_bird/components/schedule/edit_schedule_dialog.dart';
import 'package:humming_bird/components/schedule/reschedule_dialog.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_templates_page.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ScheduleDashboard extends StatefulWidget {
  const ScheduleDashboard({super.key});

  @override
  State<ScheduleDashboard> createState() => _ScheduleDashboardState();
}

class _ScheduleDashboardState extends State<ScheduleDashboard>
    with TickerProviderStateMixin {
  late BirdController _birdController;
  late ContactController _contactController;
  late AnimationController _countAnimController;
  late Animation<double> _countScaleAnimation;
  late AnimationController _pulseController;

  List<String> _pinnedSchedules() =>
      List<String>.from(GetStorage().read<List>('pinned_schedules') ?? []);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg =>
      _isDark ? CustomColor.kDarkBackground : CustomColor.kUltraLightPrimary;
  Color get _cardBg =>
      _isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
  Color get _surface2 =>
      _isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
  Color get _border =>
      _isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
  Color get _text2 =>
      _isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
  Color get _text3 =>
      _isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

  bool _isPinned(String id) => _pinnedSchedules().contains(id);

  void _togglePin(String id) {
    final pinned = _pinnedSchedules();
    if (pinned.contains(id)) {
      pinned.remove(id);
    } else {
      pinned.add(id);
    }
    GetStorage().write('pinned_schedules', pinned);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _birdController = Get.find();
    _contactController = Get.find();
    _countAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _countAnimController, curve: Curves.elasticOut),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _birdController.getScheduledMessages(),
      _birdController.loadUpcomingSchedules(),
      _birdController.loadDrafts(),
      _birdController.loadTemplates(),
      _birdController.loadScheduleCategories(),
    ]);
    _countAnimController.forward();
  }

  @override
  void dispose() {
    _countAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  int get _totalScheduledCount {
    int count = 0;
    for (final list in _birdController.scheduledMessagesMap.values) {
      count += list.length;
    }
    return count;
  }

  String _receiverName(dynamic message) {
    if (message is Map) {
      final name = message['m_receiver_name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
      final receiverId = message['m_receiver_id']?.toString() ?? '';
      if (receiverId.isEmpty) return 'Group chat';
      final contactName = _contactController.getUserNameById(receiverId);
      return contactName.trim().isEmpty ? 'Unknown' : contactName;
    }
    final fromApi = message.mReceiver?.trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;
    final receiverId = message.mReceiverId?.trim() ?? '';
    if (receiverId.isEmpty) return 'Group chat';
    final name = _contactController.getUserNameById(receiverId);
    return name.trim().isEmpty ? 'Unknown contact' : name;
  }

  String _messagePreview(dynamic message) {
    String? msg;
    String? msgType;
    if (message is Map) {
      msg = message['m_message']?.toString();
      msgType = message['m_message_type']?.toString();
    } else {
      msg = message.mMessage;
      msgType = message.mMessageType;
    }
    if (msgType == '0') {
      try {
        final decrypted = EncryptionHelper().decryptMessage(msg ?? '');
        return decrypted.trim().isNotEmpty ? decrypted : msg ?? '';
      } catch (_) {
        return msg ?? '';
      }
    }
    return AppHelper.getMediaName(fileType: msgType ?? '');
  }

  String _timeFromEpoch(String? epoch) {
    return AppHelper.formatDateTimeFromEpoch(epoch ?? '0', 'h:mm a');
  }

  void _openMessage(dynamic message) {
    String roomId;
    String receiverId;
    String name;
    if (message is Map) {
      roomId = message['m_room_id']?.toString() ?? '';
      receiverId = message['m_receiver_id']?.toString() ?? '';
      name = _receiverName(message);
    } else {
      roomId = message.mRoomId ?? '';
      receiverId = message.mReceiverId ?? '';
      name = _receiverName(message);
    }
    Get.to(
        () => ChatScreen(
              name: name,
              userNumber: '',
              roomId: roomId,
              receiverId: receiverId,
              isGroup: receiverId.isEmpty,
              userProfile: _contactController.getUserProfilePic(receiverId),
            ),
        arguments: {
          'isScroll': true,
          'messageId': message is Map
              ? (message['m_id']?.toString() ?? '')
              : (message.mId ?? ''),
        });
  }

  void _shareSchedule(dynamic message) {
    final name = _receiverName(message);
    String scheduledAt;
    String msgText;
    if (message is Map) {
      scheduledAt = message['m_scheduled_at']?.toString() ?? '0';
      msgText = message['m_message']?.toString() ?? '(no text)';
    } else {
      scheduledAt = message.mScheduledAt ?? '0';
      msgText = message.mMessage ?? '(no text)';
    }
    final scheduleInfo =
        '📅 Scheduled: ${AppHelper.formatDateTimeFromEpoch(scheduledAt, 'dd MMM yyyy, h:mm a')}\n'
        'To: $name\n'
        'Message: $msgText';
    Clipboard.setData(ClipboardData(text: scheduleInfo));
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 48.r, color: CustomColor.kSuccess),
              SizedBox(height: 12.h),
              Text('Schedule copied to clipboard!',
                  style: AppTextStyles.headingSm),
              SizedBox(height: 8.h),
              Text('Share this info with anyone via chat.',
                  style: AppTextStyles.subtitle.copyWith(color: _text3)),
              SizedBox(height: 20.h),
              AppButton(
                text: 'Open Chat',
                onTap: () {
                  Get.back();
                  _openMessage(message);
                },
                backgroundColor: CustomColor.kPrimaryFill,
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Close', style: GoogleFonts.poppins(color: _text3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiParserSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (_) => AiScheduleParserSheet(
        onConfirm: (data) {
          Get.back();
          Utils.showGetSnackBar('Schedule parsed successfully');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Obx(
        () => _birdController.showLoading.value && _totalScheduledCount == 0
            ? const CustomLoading()
            : RefreshIndicator(
                color: CustomColor.kPrimaryColor,
                onRefresh: _loadData,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 96.h),
                  children: [
                    _buildHeader(),
                    SizedBox(height: 16.h),
                    _buildFilterChips(),
                    SizedBox(height: 16.h),
                    _buildFilterTabs(),
                    SizedBox(height: 12.h),
                    _buildContent(),
                  ],
                ),
              ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'ai_parser',
            onPressed: _showAiParserSheet,
            backgroundColor: CustomColor.kPrimaryMedium,
            foregroundColor: CustomColor.kTextOnDark,
            child: const Icon(Icons.auto_awesome_rounded),
          ),
          SizedBox(height: 12.h),
          FloatingActionButton(
            heroTag: 'create_schedule',
            onPressed: () {
              Get.to(() => const ScheduleTemplatesPage());
            },
            backgroundColor: CustomColor.kPrimaryColor,
            foregroundColor: CustomColor.kTextOnDark,
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final count = _totalScheduledCount;
    final failed = _birdController.failedSchedules.length;
    final upcoming = _birdController.upcomingSchedules.length;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: CustomColor.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.twentyTwo.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CustomColor.kTextOnDark.withValues(alpha: 0.18),
                      CustomColor.kOverlay6,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                ),
                child: Icon(Icons.dashboard_rounded,
                    color: CustomColor.kTextOnDark, size: 24.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule Dashboard',
                      style: AppTextStyles.headingLg
                          .copyWith(color: CustomColor.kTextOnDark),
                    ),
                    Text(
                      '$count total scheduled',
                      style: AppTextStyles.bodySm.copyWith(
                          color:
                              CustomColor.kTextOnDark.withValues(alpha: 0.74)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _StatBadge(
                label: 'Upcoming',
                value: upcoming.toString(),
                color: CustomColor.kTextOnDark,
                bgColor: CustomColor.kOverlay12,
                scaleAnimation: _countScaleAnimation,
              ),
              SizedBox(width: 10.w),
              _StatBadge(
                label: 'Failed',
                value: failed.toString(),
                color: CustomColor.kDangerRed,
                bgColor: CustomColor.kOverlay12,
                scaleAnimation: _countScaleAnimation,
              ),
              SizedBox(width: 10.w),
              _StatBadge(
                label: 'Drafts',
                value: _birdController.draftSchedules.length.toString(),
                color: CustomColor.kGoldAccent,
                bgColor: CustomColor.kOverlay12,
                scaleAnimation: _countScaleAnimation,
              ),
              SizedBox(width: 10.w),
              _StatBadge(
                label: 'Templates',
                value: _birdController.scheduleTemplates.length.toString(),
                color: CustomColor.kOnlineGreen,
                bgColor: CustomColor.kOverlay12,
                scaleAnimation: _countScaleAnimation,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = _birdController.scheduleCategories;
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _birdController.selectedCategory.value == cat;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(
                cat.toString().capitalizeFirst ?? cat,
                style: AppTextStyles.bodySm.copyWith(
                    color: isSelected ? CustomColor.kTextOnDark : _text2),
              ),
              selected: isSelected,
              selectedColor: CustomColor.kPrimaryFill,
              backgroundColor: _surface2,
              onSelected: (_) {
                _birdController.filterByCategory(cat);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                side: BorderSide(
                  color: isSelected ? CustomColor.kPrimaryColor : _border,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['all', 'upcoming', 'drafts', 'failed', 'templates'];
    return SizedBox(
      height: 36.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected =
              _birdController.activeScheduleFilter.value == filter;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => _birdController.setScheduleFilter(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: isSelected ? CustomColor.primaryGradient : null,
                  color: isSelected ? null : _surface2,
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  border: Border.all(
                    color: isSelected ? CustomColor.kPrimaryColor : _border,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: CustomColor.kPrimaryColor
                                .withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filter.capitalizeFirst ?? filter,
                  style: AppTextStyles.bodySm.copyWith(
                      color: isSelected ? CustomColor.kTextOnDark : _text2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    final filter = _birdController.activeScheduleFilter.value;

    switch (filter) {
      case 'upcoming':
        return _buildUpcomingSection();
      case 'drafts':
        return _buildDraftsSection();
      case 'failed':
        return _buildFailedSection();
      case 'templates':
        return _buildTemplatesSection();
      default:
        return _buildAllTimeline();
    }
  }

  Widget _buildAllTimeline() {
    if (_birdController.scheduledDates.isEmpty) {
      return AppEmptyState(
        icon: Icons.schedule_send_outlined,
        title: 'No scheduled messages',
        message: 'Messages you schedule will appear here.',
        actionLabel: 'Refresh',
        onAction: _loadData,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _birdController.scheduledDates.map((dateKey) {
        final messages = _birdController.scheduledMessagesMap[dateKey] ?? [];
        if (messages.isEmpty) return const SizedBox.shrink();
        final parsed = DateTime.tryParse(dateKey);
        final label = parsed == null
            ? dateKey
            : DateFormat('MMM dd, yyyy').format(parsed);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: AppTextStyles.subtitle.copyWith(color: _text2),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Divider(color: _border, thickness: 0.8),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '${messages.length}',
                    style: AppTextStyles.caption.copyWith(color: _text3),
                  ),
                ],
              ),
            ),
            ...messages.asMap().entries.map((entry) {
              final index = entry.key;
              final message = entry.value;
              final isFailed = message.mStatus?.toString() == 'failed';
              return AnimatedScheduleCard(
                message: message,
                receiverName: _receiverName(message),
                preview: _messagePreview(message),
                status: isFailed ? 'failed' : 'pending',
                category: '',
                index: index,
                isPinned: _isPinned(message.mId ?? ''),
                onPin: () => _togglePin(message.mId ?? ''),
                onTap: () => _openMessage(message),
                onOpenChat: () => _openMessage(message),
                onShare: () => _shareSchedule(message),
                onEdit: message.mMessageType == '0'
                    ? () => showAdaptiveDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => EditScheduleDialog(message: message),
                        )
                    : null,
                onReschedule: () => showAdaptiveDialog(
                  context: context,
                  builder: (_) => RescheduleDialog(message: message),
                ),
                onDuplicate: () => _birdController.duplicateMessage(message),
                onMarkComplete: isFailed
                    ? null
                    : () => _birdController.markComplete(message),
                onCancel: () =>
                    _birdController.cancelScheduledMessage(message, index),
                onRetry: isFailed
                    ? () =>
                        _birdController.retryFailedSchedule(message.mId ?? '')
                    : null,
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingSection() {
    if (_birdController.upcomingSchedules.isEmpty) {
      return AppEmptyState(
        icon: Icons.event_available_rounded,
        title: 'No upcoming schedules',
        message: 'All your schedules are completed.',
        actionLabel: 'Refresh',
        onAction: _loadData,
      );
    }

    return Column(
      children: _birdController.upcomingSchedules.asMap().entries.map((entry) {
        final schedule = entry.value;
        final name = _receiverName(schedule);
        final preview = _messagePreview(schedule);
        final time = _timeFromEpoch(schedule['m_scheduled_at']?.toString());
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: CustomColor.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                ),
                child: Icon(Icons.schedule_send_rounded,
                    color: CustomColor.kTextOnDark, size: 21.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.chatBadge),
                    Text('To $name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(color: _text2)),
                    Text(time,
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kPrimaryColor)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDraftsSection() {
    if (_birdController.draftSchedules.isEmpty) {
      return AppEmptyState(
        icon: Icons.drafts_rounded,
        title: 'No drafts',
        message: 'Save your schedule ideas as drafts.',
        actionLabel: 'Refresh',
        onAction: _loadData,
      );
    }

    return Column(
      children: _birdController.draftSchedules.asMap().entries.map((entry) {
        final draft = entry.value;
        return Dismissible(
          key: Key(draft['id']?.toString() ?? ''),
          direction: DismissDirection.endToStart,
          onDismissed: (_) =>
              _birdController.deleteDraft(draft['id']?.toString() ?? ''),
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.w),
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: CustomColor.kDangerRed,
              borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            ),
            child: Icon(Icons.delete_rounded,
                color: CustomColor.kTextOnDark, size: 24.r),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(AppRadius.xxl.r),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CustomColor.kGoldLight,
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  ),
                  child: Icon(Icons.drafts_rounded,
                      color: CustomColor.kGoldAccent, size: 21.r),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft['m_message']?.toString() ?? 'Draft',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.chatBadge,
                      ),
                      if (draft['scheduled_at'] != null)
                        Text(
                          _timeFromEpoch(draft['scheduled_at'].toString()),
                          style: AppTextStyles.bodySm.copyWith(color: _text2),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Resume draft',
                  icon: Icon(Icons.play_arrow_rounded,
                      color: CustomColor.kPrimaryColor),
                  onPressed: () {
                    Utils.showGetSnackBar('Resume draft');
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFailedSection() {
    if (_birdController.failedSchedules.isEmpty) {
      return AppEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'No failed schedules',
        message: 'All your schedules are running smoothly.',
        actionLabel: 'Refresh',
        onAction: _loadData,
      );
    }

    return Column(
      children: _birdController.failedSchedules.asMap().entries.map((entry) {
        final schedule = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(
              color: CustomColor.kDangerRed.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CustomColor.kLightDangerColor,
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                ),
                child: Icon(Icons.error_rounded,
                    color: CustomColor.kDangerRed, size: 21.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _messagePreview(schedule),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.chatBadge,
                    ),
                    Text(
                      'Failed to send',
                      style: AppTextStyles.bodySm
                          .copyWith(color: CustomColor.kDangerRed),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                icon: Icon(Icons.refresh_rounded,
                    color: CustomColor.kPrimaryColor),
                onPressed: () => _birdController
                    .retryFailedSchedule(schedule['m_id']?.toString() ?? ''),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplatesSection() {
    if (_birdController.scheduleTemplates.isEmpty) {
      return AppEmptyState(
        icon: Icons.bookmark_outline_rounded,
        title: 'No templates',
        message: 'Create templates for quick scheduling.',
        actionLabel: 'Refresh',
        onAction: _loadData,
      );
    }

    return Column(
      children: [
        ..._birdController.scheduleTemplates.map((template) {
          return ListTile(
            leading: Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: CustomColor.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              ),
              child: Icon(Icons.bookmark_rounded,
                  color: CustomColor.kTextOnDark, size: 21.r),
            ),
            title: Text(
              template['template_name']?.toString() ?? '',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              template['message']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm,
            ),
            trailing: Text(
              template['category']?.toString() ?? '',
              style: AppTextStyles.caption
                  .copyWith(color: CustomColor.kPrimaryColor),
            ),
          );
        }),
        SizedBox(height: 12.h),
        Center(
          child: TextButton.icon(
            onPressed: () => Get.to(() => const ScheduleTemplatesPage()),
            icon: Icon(Icons.open_in_new_rounded, size: 16.r),
            label: Text('Manage Templates',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final Animation<double> scaleAnimation;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppTextStyles.headingMd.copyWith(color: color),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: AppTextStyles.labelSm
                    .copyWith(color: color.withValues(alpha: 0.74)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
