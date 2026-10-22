import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/components/connectivity/connection_error_view.dart';
import 'package:humming_bird/components/connectivity/connection_status_bar.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/loading/app_skeleton.dart';
import 'package:humming_bird/components/schedule/animated_schedule_card.dart';
import 'package:humming_bird/components/schedule/reschedule_dialog.dart';
import 'package:humming_bird/components/schedule/schedule_recipient_sheet.dart';
import 'package:humming_bird/components/scheduled_messages_list/scheduled_dates.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_message_details.dart';
import 'package:humming_bird/pages/Schedule_Pages/widgets/edit_message_dialog.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

typedef _ScheduleStatusOption = ({String label, String value, int count});

class ScheduleMessagesList extends StatefulWidget {
  final bool showHeader;
  final VoidCallback? onCreate;

  const ScheduleMessagesList(
      {super.key, this.showHeader = true, this.onCreate});

  @override
  State<ScheduleMessagesList> createState() => _ScheduleMessagesListState();
}

class _ScheduleMessagesListState extends State<ScheduleMessagesList> {
  late final BirdController birdController;
  late final ContactController contactController;
  bool _showCalendar = true;
  bool _showSearch = false;
  String _statusTab = 'upcoming';
  DateTime _visibleCalendarMonth = DateTime.now();

  // Same dark/light palette as schedule_screen.dart.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg =>
      _isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
  Color get _surface2 =>
      _isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
  Color get _inputFill =>
      _isDark ? CustomColor.kDarkInputFill : CustomColor.kTextOnDark;
  Color get _border =>
      _isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
  Color get _text1 =>
      _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
  Color get _text2 =>
      _isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
  Color get _text3 =>
      _isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

  List<String> _pinnedSchedules() =>
      List<String>.from(GetStorage().read<List>('pinned_schedules') ?? []);

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

  void _openRecipientPicker() {
    if (!mounted) return;
    ScheduleRecipientSheet.show(context);
  }

  @override
  void initState() {
    super.initState();
    birdController = Get.find();
    contactController = Get.find();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await birdController.getScheduledMessages();
      } catch (_) {}
      try {
        await birdController.loadScheduleCategories();
      } catch (_) {}
      try {
        await birdController.loadDrafts();
      } catch (_) {}
      if (mounted) _syncCalendarMonth();
    });
  }

  void _syncCalendarMonth() {
    final selected = _ScheduleCalendar.dateFromKey(
      birdController.selectedDate.value,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _visibleCalendarMonth = DateTime(selected.year, selected.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? CustomColor.kDarkBackground
          : CustomColor.kUltraLightPrimaryColor,
      child: SafeArea(
        top: true,
        child: RefreshIndicator(
          color: CustomColor.kPrimaryColor,
          onRefresh: () async => birdController.getScheduledMessages(),
          child: Obx(
            () => birdController.showLoading.value
                ? _buildSkeleton()
                : birdController.scheduledDates.isEmpty &&
                        birdController.draftSchedules.isEmpty
                    ? !ConnectivityService.to.isOnline.value
                        ? ConnectionErrorView(
                            onRetry: birdController.getScheduledMessages)
                        : AppEmptyState(
                            icon: Icons.schedule_send_outlined,
                            title: 'No scheduled messages',
                            message:
                                'Messages you schedule will appear here by date.',
                            actionLabel: 'New Schedule',
                            onAction: widget.onCreate ?? _openRecipientPicker,
                            secondaryActionLabel: 'Refresh',
                            onSecondaryAction:
                                birdController.getScheduledMessages,
                          )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.showHeader) ...[
                            _Header(
                              total: birdController.scheduledMessagesMap.values
                                  .fold<int>(
                                      0,
                                      (sum, list) =>
                                          sum +
                                          list
                                              .where((m) => ![
                                                    'sent',
                                                    'cancelled',
                                                    'failed'
                                                  ].contains(
                                                      m.mStatus?.toString()))
                                              .length),
                              onCreate: widget.onCreate ?? _openRecipientPicker,
                              backable: Navigator.of(context).canPop(),
                            ),
                            const ConnectionStatusBar(showSubtitle: false),
                          ] else
                            SizedBox(height: 4.h),
                          _ScheduleControls(
                            showCalendar: _showCalendar,
                            showSearch: _showSearch,
                            statusOptions: _statusOptions,
                            selectedStatus: _statusTab,
                            onStatusChanged: (value) =>
                                setState(() => _statusTab = value),
                            onChanged: (value) =>
                                setState(() => _showCalendar = value),
                            onToggleSearch: () =>
                                setState(() => _showSearch = !_showSearch),
                          ),
                          if (_showSearch) ...[
                            _buildSearchBar(),
                            SizedBox(height: 8.h),
                          ],
                          SizedBox(height: 4.h),
                          Expanded(
                            child: _showCalendar
                                ? Obx(
                                    () => ListView(
                                      physics: const ClampingScrollPhysics(),
                                      padding: EdgeInsets.only(bottom: 32.h),
                                      children: [
                                        _ScheduleCalendar(
                                          visibleMonth: _visibleCalendarMonth,
                                          onPreviousMonth: () => setState(() {
                                            _visibleCalendarMonth = DateTime(
                                              _visibleCalendarMonth.year,
                                              _visibleCalendarMonth.month - 1,
                                            );
                                          }),
                                          onNextMonth: () => setState(() {
                                            _visibleCalendarMonth = DateTime(
                                              _visibleCalendarMonth.year,
                                              _visibleCalendarMonth.month + 1,
                                            );
                                          }),
                                          onOpenFullCalendar: _openFullCalendar,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              16.w, 6.h, 16.w, 8.h),
                                          child: Text(
                                            _countLabel(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.label
                                                .copyWith(color: _text3),
                                          ),
                                        ),
                                        ..._scheduleContentItems(),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 74.h,
                                        child: const ScheduledDatesList(),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(
                                            16.w, 6.h, 16.w, 8.h),
                                        child: GetBuilder<BirdController>(
                                          builder: (_) => Text(
                                            _countLabel(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.label
                                                .copyWith(color: _text3),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _statusTab == 'drafts'
                                            ? Obx(() => _buildDraftsList())
                                            : Obx(
                                                () => ListView(
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  padding: EdgeInsets.only(
                                                      bottom: 32.h),
                                                  children:
                                                      _scheduleContentItems(),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: _inputFill,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          border: Border.all(color: _border),
        ),
        child: TextField(
          controller: birdController.scheduleSearchController,
          style: AppTextStyles.bodyMd.copyWith(color: _text1),
          decoration: InputDecoration(
            hintText: 'Search schedules...',
            hintStyle: AppTextStyles.subtitle.copyWith(color: _text3),
            prefixIcon: Icon(Icons.search_rounded, color: _text3, size: 20.r),
            suffixIcon: birdController.scheduleSearchQuery.isNotEmpty
                ? IconButton(
                    tooltip: 'Close',
                    onPressed: () {
                      birdController.scheduleSearchController.clear();
                      birdController.searchSchedules('');
                    },
                    icon: Icon(Icons.close_rounded, color: _text3, size: 18.r),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 10.h),
          ),
          onChanged: (value) => birdController.serverSearchSchedules(value),
        ),
      ),
    );
  }

  Widget _buildMessageCard(Messages message, int index) {
    return AnimatedScheduleCard(
      message: message,
      receiverName: _receiverName(message),
      preview: _messagePreview(message),
      status: _messageStatus(message),
      category: '',
      index: index,
      isPinned: _isPinned(message.mId ?? ''),
      onPin: () => _togglePin(message.mId ?? ''),
      onTap: () => _openDetails(message),
      onOpenChat: () => _openMessage(message),
      onShare: () => _shareSchedule(message),
      onEdit: message.mMessageType == '0'
          ? () => showAdaptiveDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => EditMessageDialog(
                  currentMessage: message,
                ),
              )
          : null,
      onDuplicate: () => birdController.duplicateMessage(message),
      onMarkComplete: _messageStatus(message) == 'pending'
          ? () => birdController.markComplete(message)
          : null,
      onReschedule: () => showAdaptiveDialog(
        context: context,
        builder: (_) => RescheduleDialog(message: message),
      ),
      onCancel: () => birdController.cancelScheduledMessage(message, index),
      onRetry: _messageStatus(message) == 'failed'
          ? () => birdController.retryFailedSchedule(message.mId ?? '')
          : null,
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      children: [
        AppSkeletonPulse(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBlock(width: 150.w, height: 24.h, radius: 8),
              SizedBox(height: 6.h),
              AppSkeletonBlock(width: 190.w, height: 12.h, radius: 6),
              SizedBox(height: 12.h),
              AppSkeletonBlock(
                  width: double.infinity, height: 40.h, radius: 13),
              SizedBox(height: 10.h),
              Row(
                children: [
                  AppSkeletonBlock(width: 70.w, height: 30.h, radius: 10),
                  SizedBox(width: 8.w),
                  AppSkeletonBlock(width: 88.w, height: 30.h, radius: 10),
                  SizedBox(width: 8.w),
                  AppSkeletonBlock(width: 80.w, height: 30.h, radius: 10),
                ],
              ),
              SizedBox(height: 20.h),
              AppSkeletonBlock(
                  width: double.infinity, height: 210.h, radius: 16),
              SizedBox(height: 22.h),
              for (var i = 0; i < 4; i++) ...[
                _skeletonRow(),
                if (i < 3) SizedBox(height: 14.h),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _skeletonRow() {
    return Row(
      children: [
        AppSkeletonBlock(width: 40.r, height: 40.r, circle: true),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBlock(width: 130.w, height: 12.h, radius: 6),
              SizedBox(height: 7.h),
              AppSkeletonBlock(width: 90.w, height: 10.h, radius: 5),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        AppSkeletonBlock(width: 58.w, height: 24.h, radius: 12),
      ],
    );
  }

  List<_ScheduleStatusOption> get _statusOptions => [
        (label: 'Upcoming', value: 'upcoming', count: _statusCount('upcoming')),
        (label: 'Sent', value: 'sent', count: _statusCount('sent')),
        (
          label: 'Cancelled',
          value: 'cancelled',
          count: _statusCount('cancelled')
        ),
        (label: 'Failed', value: 'failed', count: _statusCount('failed')),
        (label: 'Drafts', value: 'drafts', count: _statusCount('drafts')),
      ];

  int _statusCount(String tab) {
    if (tab == 'drafts') return birdController.draftSchedules.length;
    final all = birdController.scheduledMessagesMap.values
        .expand((list) => list)
        .toList();
    String statusOf(Messages m) => (m.mStatus ?? '').toString().toLowerCase();
    switch (tab) {
      case 'sent':
        return all.where((m) => statusOf(m) == 'sent').length;
      case 'cancelled':
        return all.where((m) => statusOf(m) == 'cancelled').length;
      case 'failed':
        return all.where((m) => statusOf(m) == 'failed').length;
      default:
        return all
            .where(
                (m) => !['sent', 'cancelled', 'failed'].contains(statusOf(m)))
            .length;
    }
  }

  List<Messages> _applyStatusTab(List<Messages> source) {
    String statusOf(Messages m) => (m.mStatus ?? '').toString().toLowerCase();
    switch (_statusTab) {
      case 'sent':
        return source.where((m) => statusOf(m) == 'sent').toList();
      case 'cancelled':
        return source.where((m) => statusOf(m) == 'cancelled').toList();
      case 'failed':
        return source.where((m) => statusOf(m) == 'failed').toList();
      default:
        return source
            .where(
                (m) => !['sent', 'cancelled', 'failed'].contains(statusOf(m)))
            .toList();
    }
  }

  String _countLabel() {
    String statusOf(Messages m) => (m.mStatus ?? '').toString().toLowerCase();
    final all = birdController.scheduledMessagesMap.values
        .expand((list) => list)
        .toList();
    switch (_statusTab) {
      case 'sent':
        return '${all.where((m) => statusOf(m) == 'sent').length} sent schedules';
      case 'cancelled':
        return '${all.where((m) => statusOf(m) == 'cancelled').length} cancelled schedules';
      case 'failed':
        return '${all.where((m) => statusOf(m) == 'failed').length} failed schedules';
      case 'drafts':
        return '${birdController.draftSchedules.length} drafts';
      default:
        return '${all.where((m) => ![
              'sent',
              'cancelled',
              'failed'
            ].contains(statusOf(m))).length} upcoming schedules';
    }
  }

  Widget _tabEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44.r, color: _text3),
          SizedBox(height: 10.h),
          Text(
            message,
            style: AppTextStyles.label.copyWith(color: _text2),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsList() {
    final drafts = birdController.draftSchedules
        .map((d) =>
            d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{})
        .toList();
    if (drafts.isEmpty) {
      return _tabEmptyState('No drafts yet', Icons.edit_note_rounded);
    }
    return ListView.builder(
      padding: EdgeInsets.only(top: 4.h, bottom: 32.h),
      itemCount: drafts.length,
      itemBuilder: (context, index) => Entrance(
          delayFactor: (index % 8) * 0.05,
          child: _buildDraftCard(drafts[index], index)),
    );
  }

  List<Widget> _scheduleContentItems() {
    if (_statusTab == 'drafts') {
      final drafts = birdController.draftSchedules
          .map((d) =>
              d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{})
          .toList();
      if (drafts.isEmpty) {
        return [
          SizedBox(
            height: 160.h,
            child: _tabEmptyState('No drafts yet', Icons.edit_note_rounded),
          ),
        ];
      }
      return [
        for (var i = 0; i < drafts.length; i++)
          Entrance(
              delayFactor: (i % 8) * 0.05,
              child: _buildDraftCard(drafts[i], i)),
      ];
    }

    final activeFilter = birdController.activeScheduleFilter.value;
    final allDateMessages = birdController.scheduledMessagesMap.values
        .expand((list) => list)
        .toList();
    final sourceMessages =
        (activeFilter != 'all' && birdController.filteredSchedules.isNotEmpty)
            ? List<Messages>.from(birdController.filteredSchedules)
            : allDateMessages;
    final statusMessages = _applyStatusTab(sourceMessages);

    if (statusMessages.isEmpty) {
      return [
        SizedBox(
          height: 160.h,
          child: _tabEmptyState(
            _statusTab == 'sent'
                ? 'No sent schedules yet'
                : _statusTab == 'cancelled'
                    ? 'No cancelled schedules'
                    : _statusTab == 'failed'
                        ? 'No failed schedules'
                        : 'No upcoming schedules',
            Icons.event_available_rounded,
          ),
        ),
      ];
    }

    statusMessages.sort((a, b) {
      final aPinned = _isPinned(a.mId ?? '');
      final bPinned = _isPinned(b.mId ?? '');
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      final aEpoch = int.tryParse(a.mScheduledAt ?? '0') ?? 0;
      final bEpoch = int.tryParse(b.mScheduledAt ?? '0') ?? 0;
      return aEpoch.compareTo(bEpoch);
    });

    final groups = _groupByTimeOfDay(statusMessages);
    final items = <Widget>[];
    int msgCounter = 0;
    for (final group in groups) {
      items.add(
          _TimeGroupHeader(label: group.label, count: group.messages.length));
      for (final msg in group.messages) {
        final currentIndex = msgCounter;
        msgCounter++;
        items.add(Entrance(
          delayFactor: (currentIndex % 8) * 0.05,
          child: _buildMessageCard(msg, currentIndex),
        ));
      }
    }
    return items;
  }

  Widget _buildDraftCard(Map<String, dynamic> draft, int index) {
    final draftId = draft['draft_id']?.toString() ?? '';
    final scheduledAt = draft['scheduled_at']?.toString() ?? '0';
    final interval = draft['interval']?.toString() ?? '0';
    final category = draft['category']?.toString() ?? 'custom';

    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
            ),
            child: Icon(Icons.edit_note_rounded,
                color: CustomColor.kTextOnDark, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _draftPreview(draft),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(color: _text1),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Scheduled for ${AppHelper.formatDateTimeFromEpoch(scheduledAt, 'dd MMM yyyy, h:mm a')}',
                  style: AppTextStyles.error.copyWith(color: _text3),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    _draftMetaChip(_draftIntervalLabel(interval)),
                    SizedBox(width: 6.w),
                    _draftMetaChip(category.capitalizeFirst ?? category),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          IconButton(
            onPressed: () => _deleteDraft(draftId),
            tooltip: 'Delete draft',
            icon: Icon(Icons.delete_outline_rounded,
                color: CustomColor.kDangerRed, size: 20.r),
          ),
        ],
      ),
    );
  }

  Widget _draftMetaChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: _text2),
      ),
    );
  }

  String _draftIntervalLabel(String interval) {
    switch (interval) {
      case '1':
        return 'Daily';
      case '2':
        return 'Weekly';
      case '3':
        return 'Monthly';
      case '4':
        return 'Yearly';
      default:
        return 'Once';
    }
  }

  String _draftPreview(Map<String, dynamic> draft) {
    final messageType = draft['message_type']?.toString() ?? '0';
    if (messageType != '0') {
      return AppHelper.getMediaName(fileType: messageType);
    }
    final message = draft['message']?.toString() ?? '';
    if (message.trim().isEmpty) return '(empty draft)';
    return message;
  }

  void _deleteDraft(String draftId) {
    if (draftId.isEmpty) return;
    showAdaptiveDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete draft?', style: AppTextStyles.titleMd),
        content: Text('This draft will be permanently removed.',
            style: AppTextStyles.subtitle),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: _text2)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              birdController.deleteDraft(draftId);
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: CustomColor.dangerTextFor(_isDark),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<({String label, List<Messages> messages})> _groupByTimeOfDay(
      List<Messages> messages) {
    final morning = <Messages>[];
    final afternoon = <Messages>[];
    final evening = <Messages>[];
    final night = <Messages>[];

    for (var m in messages) {
      final epoch = int.tryParse(m.mScheduledAt ?? '');
      if (epoch == null) {
        morning.add(m);
        continue;
      }
      final hour = DateTime.fromMillisecondsSinceEpoch(epoch * 1000).hour;
      if (hour < 12) {
        morning.add(m);
      } else if (hour < 17) {
        afternoon.add(m);
      } else if (hour < 21) {
        evening.add(m);
      } else {
        night.add(m);
      }
    }

    final groups = <({String label, List<Messages> messages})>[];
    if (morning.isNotEmpty) groups.add((label: 'Morning', messages: morning));
    if (afternoon.isNotEmpty) {
      groups.add((label: 'Afternoon', messages: afternoon));
    }
    if (evening.isNotEmpty) {
      groups.add((label: 'Evening', messages: evening));
    }
    if (night.isNotEmpty) {
      groups.add((label: 'Night', messages: night));
    }
    return groups;
  }

  String _messageStatus(Messages message) {
    if (message.mStatus?.toString() == 'failed') return 'failed';
    if (message.mStatus?.toString() == 'sent') return 'sent';
    if (message.mStatus?.toString() == 'cancelled') return 'cancelled';
    return 'pending';
  }

  String _receiverName(Messages message) {
    final fromApi = message.mReceiver?.trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;

    final receiverId = message.mReceiverId?.trim() ?? '';
    if (receiverId.isEmpty) return 'Group chat';

    final name = contactController.getUserNameById(receiverId);
    return name.trim().isEmpty ? 'Unknown contact' : name;
  }

  String _messagePreview(Messages message) {
    if (message.mMessageType == '0') {
      try {
        final decrypted =
            EncryptionHelper().decryptMessage(message.mMessage ?? '');
        return decrypted.trim().isNotEmpty ? decrypted : message.mMessage ?? '';
      } catch (_) {
        return message.mMessage ?? '';
      }
    }

    return AppHelper.getMediaName(fileType: message.mMessageType ?? '');
  }

  void _openDetails(Messages message) {
    Get.to(() => ScheduledMessageDetailsScreen(message: message));
  }

  Future<void> _openFullCalendar() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _FullCalendarDialog(initialMonth: _visibleCalendarMonth),
    );
    if (picked == null || !mounted) return;
    setState(() => _visibleCalendarMonth = DateTime(picked.year, picked.month));
    final key = DateFormat('yyyy-MM-dd').format(picked);
    birdController.selectDate(date: key);
    final index = birdController.scheduledDates.indexOf(key);
    if (index >= 0) birdController.updateIndex(index);
  }

  void _openMessage(Messages message) {
    Get.to(
      () => ChatScreen(
        name: _receiverName(message),
        userNumber: '',
        roomId: message.mRoomId ?? '',
        receiverId: message.mReceiverId ?? '',
        isGroup: (message.mReceiverId ?? '').isEmpty,
        userProfile: contactController.getUserProfilePic(
          message.mReceiverId ?? '',
        ),
      ),
      arguments: {'isScroll': true, 'messageId': message.mId ?? ''},
    );
  }

  void _shareSchedule(Messages message) {
    final scheduleInfo =
        'ðŸ“… Scheduled: ${AppHelper.formatDateTimeFromEpoch(message.mScheduledAt ?? '0', 'dd MMM yyyy, h:mm a')}\n'
        'To: ${_receiverName(message)}\n'
        'Message: ${message.mMessage ?? '(no text)'}';
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
}

class _ScheduleControls extends StatelessWidget {
  final bool showCalendar;
  final bool showSearch;
  final List<_ScheduleStatusOption> statusOptions;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onChanged;
  final VoidCallback onToggleSearch;

  const _ScheduleControls({
    required this.showCalendar,
    required this.showSearch,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.onChanged,
    required this.onToggleSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? CustomColor.kDarkSurface2 : CustomColor.kTextOnDark;
    final border = isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
    final primaryText =
        isDark ? CustomColor.kTextOnDark : CustomColor.kDarkSecondaryColor;
    final secondaryText = isDark
        ? CustomColor.kTextOnDarkSecondary
        : CustomColor.k2SecondaryColor;
    final selectedIndex =
        statusOptions.indexWhere((option) => option.value == selectedStatus);
    final selected = statusOptions[selectedIndex < 0 ? 0 : selectedIndex];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scheduled messages',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLg.copyWith(color: primaryText),
                ),
              ),
              _SwitchIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Search schedules',
                selected: showSearch,
                onTap: onToggleSearch,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            height: 42.h,
            padding: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              color: isDark
                  ? CustomColor.kDarkSurface2
                  : CustomColor.kUltraLightPrimary,
              borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PopupMenuButton<String>(
                    initialValue: selectedStatus,
                    onSelected: onStatusChanged,
                    tooltip: 'Filter schedules',
                    color: surface,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      side: BorderSide(color: border),
                    ),
                    itemBuilder: (_) => statusOptions
                        .map(
                          (option) => PopupMenuItem<String>(
                            value: option.value,
                            height: 46.h,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22.w,
                                  child: option.value == selectedStatus
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 17.r,
                                          color: CustomColor.kPrimaryColor,
                                        )
                                      : null,
                                ),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: AppTextStyles.bodySm
                                        .copyWith(color: primaryText),
                                  ),
                                ),
                                _ControlCountBadge(count: option.count),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 17.r,
                            color: CustomColor.kPrimaryColor,
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: Text(
                              selected.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: primaryText),
                            ),
                          ),
                          _ControlCountBadge(count: selected.count),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18.r,
                            color: secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 22.h, color: border),
                _SwitchButton(
                  icon: Icons.calendar_month_rounded,
                  tooltip: 'Calendar view',
                  selected: showCalendar,
                  onTap: () => onChanged(true),
                ),
                _SwitchButton(
                  icon: Icons.view_day_rounded,
                  tooltip: 'Date list',
                  selected: !showCalendar,
                  onTap: () => onChanged(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCountBadge extends StatelessWidget {
  final int count;

  const _ControlCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(minWidth: 19.r),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color:
            isDark ? CustomColor.kDarkSurface : CustomColor.kLightPrimaryColor,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.labelSm.copyWith(color: CustomColor.kPrimaryColor),
      ),
    );
  }
}

class _SwitchIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _SwitchIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor:
            selected ? CustomColor.kPrimaryColor : Colors.transparent,
        foregroundColor: selected
            ? CustomColor.kTextOnDark
            : isDark
                ? CustomColor.kTextOnDarkSecondary
                : CustomColor.kDarkSecondaryColor,
        fixedSize: Size(34.r, 34.r),
        minimumSize: Size(34.r, 34.r),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg.r)),
      ),
      icon: Icon(icon, size: 18.r),
    );
  }
}

class _TimeGroupHeader extends StatelessWidget {
  final String label;
  final int count;

  const _TimeGroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    switch (label) {
      case 'Morning':
        icon = Icons.wb_sunny_rounded;
        break;
      case 'Afternoon':
        icon = Icons.wb_cloudy_rounded;
        break;
      case 'Evening':
        icon = Icons.nightlight_round;
        break;
      case 'Night':
        icon = Icons.nights_stay_rounded;
        break;
      default:
        icon = Icons.schedule_rounded;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.r,
            color: isDark
                ? CustomColor.kTextOnDarkSecondary
                : CustomColor.k2SecondaryColor,
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: AppTextStyles.subtitle.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDarkSecondary
                    : CustomColor.k2SecondaryColor),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isDark
                  ? CustomColor.kDarkSurface2
                  : CustomColor.kUltraLightPrimary,
              borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? CustomColor.kTextOnDarkSecondary
                      : CustomColor.k2SecondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor:
            selected ? CustomColor.kPrimaryColor : Colors.transparent,
        foregroundColor: selected
            ? CustomColor.kTextOnDark
            : isDark
                ? CustomColor.kTextOnDarkSecondary
                : CustomColor.kDarkSecondaryColor,
        fixedSize: Size(34.r, 34.r),
        minimumSize: Size(34.r, 34.r),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg.r)),
      ),
      icon: Icon(icon, size: 18.r),
    );
  }
}

class _ScheduleCalendar extends StatelessWidget {
  final DateTime visibleMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onOpenFullCalendar;

  const _ScheduleCalendar({
    required this.visibleMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenFullCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GetBuilder<BirdController>(
      builder: (birdController) {
        final selectedDate = dateFromKey(birdController.selectedDate.value);
        final now = DateTime.now();
        final daysInMonth =
            DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;

        return Container(
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h),
          decoration: BoxDecoration(
            color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
            borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
            border: Border.all(
                color: isDark ? CustomColor.kDarkBorder : CustomColor.kScrim20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: onPreviousMonth,
                    style: IconButton.styleFrom(
                      fixedSize: Size(32.r, 32.r),
                      minimumSize: Size(32.r, 32.r),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.chevron_left_rounded,
                        color: CustomColor.kDarkPrimaryColor, size: 22.r),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _monthLabel(visibleMonth),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMd.copyWith(
                          color: isDark
                              ? CustomColor.kTextOnDark
                              : CustomColor.kDarkSecondaryColor),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    tooltip: 'Open full calendar',
                    onPressed: onOpenFullCalendar,
                    style: IconButton.styleFrom(
                      fixedSize: Size(32.r, 32.r),
                      minimumSize: Size(32.r, 32.r),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.calendar_month_rounded,
                        color: CustomColor.kPrimaryColor, size: 20.r),
                  ),
                  SizedBox(width: 4.w),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: onNextMonth,
                    style: IconButton.styleFrom(
                      fixedSize: Size(32.r, 32.r),
                      minimumSize: Size(32.r, 32.r),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.chevron_right_rounded,
                        color: CustomColor.kDarkPrimaryColor, size: 22.r),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _WeekdayLabel('M'),
                    _WeekdayLabel('T'),
                    _WeekdayLabel('W'),
                    _WeekdayLabel('T'),
                    _WeekdayLabel('F'),
                    _WeekdayLabel('S'),
                    _WeekdayLabel('S'),
                  ],
                ),
              ),
              SizedBox(height: 6.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.15,
                ),
                itemCount: _leadingBlanks(visibleMonth) + daysInMonth,
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                itemBuilder: (context, index) {
                  if (index < _leadingBlanks(visibleMonth)) {
                    return const SizedBox.shrink();
                  }
                  final dayNumber = index - _leadingBlanks(visibleMonth) + 1;
                  final date = DateTime(
                      visibleMonth.year, visibleMonth.month, dayNumber);
                  final key = _keyFromDate(date);
                  final messages =
                      birdController.scheduledMessagesMap[key] ?? const [];
                  final hasMessages = messages.isNotEmpty;
                  final isSelected = selectedDate != null &&
                      date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  return Entrance(
                    delayFactor: (index % 8) * 0.05,
                    child: GestureDetector(
                      onTap: hasMessages || isToday
                          ? () {
                              final index =
                                  birdController.scheduledDates.indexOf(key);
                              birdController.selectDate(date: key);
                              if (index >= 0) {
                                birdController.updateIndex(index);
                              }
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    CustomColor.kPrimaryColor,
                                    CustomColor.kPrimaryMedium,
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.lg.r),
                          border: !isSelected && isToday
                              ? Border.all(
                                  color: CustomColor.kPrimaryColor,
                                  width: 1.4,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: CustomColor.kPrimaryColor
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: AppTextStyles.bodySm.copyWith(
                                  color: isSelected
                                      ? CustomColor.kTextOnDark
                                      : isDark
                                          ? CustomColor.kTextOnDark
                                          : CustomColor.kDarkSecondaryColor),
                            ),
                            SizedBox(height: 3.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: hasMessages
                                  ? messages
                                      .take(3)
                                      .map((m) => Container(
                                            width: 4.r,
                                            height: 4.r,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 1.2.w),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? CustomColor.kTextOnDark
                                                  : _dotColor(m),
                                              shape: BoxShape.circle,
                                            ),
                                          ))
                                      .toList()
                                  : [
                                      Container(
                                        width: 4.r,
                                        height: 4.r,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _dotColor(Messages m) {
    if (m.mStatus == 'sent') return CustomColor.kSuccess;
    if (m.mStatus == 'failed') return CustomColor.kDangerRed;
    return CustomColor.kPrimaryColor;
  }

  int _leadingBlanks(DateTime month) {
    return DateTime(month.year, month.month, 1).weekday - 1;
  }

  static String _keyFromDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static DateTime? dateFromKey(String key) {
    return DateTime.tryParse(key);
  }

  static String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
          color: isDark
              ? CustomColor.kTextOnDarkMuted
              : CustomColor.kTextTertiary),
    );
  }
}

class _Header extends StatelessWidget {
  final int total;
  final VoidCallback onCreate;
  final bool backable;

  const _Header({
    required this.total,
    required this.onCreate,
    this.backable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 16.w, 2.h),
      child: Row(
        children: [
          if (backable) ...[
            AppBackButton(),
            SizedBox(width: 6.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedules',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.displayMedium.copyWith(
                      color: isDark
                          ? CustomColor.kTextOnDark
                          : CustomColor.kTextPrimary,
                      height: 1.1),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$total messages waiting to send',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                      color: isDark
                          ? CustomColor.kTextOnDarkSecondary
                          : CustomColor.kTextSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          PressScale(
            child: GestureDetector(
              onTap: onCreate,
              behavior: HitTestBehavior.opaque,
              child: Semantics(
                label: 'Create schedule',
                button: true,
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: CustomColor.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add_rounded,
                      color: CustomColor.kTextOnDark, size: 26.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullCalendarDialog extends StatefulWidget {
  final DateTime initialMonth;

  const _FullCalendarDialog({required this.initialMonth});

  @override
  State<_FullCalendarDialog> createState() => _FullCalendarDialogState();
}

class _FullCalendarDialogState extends State<_FullCalendarDialog> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialMonth.year, widget.initialMonth.month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? CustomColor.kTextOnDarkSecondary
        : CustomColor.k2SecondaryColor;
    return Dialog(
      backgroundColor:
          isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.twentyTwo.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous year',
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year - 1, _month.month)),
                  style: IconButton.styleFrom(
                    fixedSize: Size(34.r, 34.r),
                    minimumSize: Size(34.r, 34.r),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.keyboard_double_arrow_left_rounded,
                      color: muted, size: 20.r),
                ),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1)),
                  style: IconButton.styleFrom(
                    fixedSize: Size(34.r, 34.r),
                    minimumSize: Size(34.r, 34.r),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.chevron_left_rounded,
                      color: muted, size: 22.r),
                ),
                Expanded(
                  child: Text(
                    _ScheduleCalendar._monthLabel(_month),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingSm.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kDarkSecondaryColor),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1)),
                  style: IconButton.styleFrom(
                    fixedSize: Size(34.r, 34.r),
                    minimumSize: Size(34.r, 34.r),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.chevron_right_rounded,
                      color: muted, size: 22.r),
                ),
                IconButton(
                  tooltip: 'Next year',
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year + 1, _month.month)),
                  style: IconButton.styleFrom(
                    fixedSize: Size(34.r, 34.r),
                    minimumSize: Size(34.r, 34.r),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.keyboard_double_arrow_right_rounded,
                      color: muted, size: 20.r),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyles.caption.copyWith(color: muted),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 4.h),
            GetBuilder<BirdController>(
              builder: (birdController) {
                final firstWeekday = _month.weekday % 7;
                final daysInMonth =
                    DateTime(_month.year, _month.month + 1, 0).day;
                final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;
                final selectedDate = _ScheduleCalendar.dateFromKey(
                    birdController.selectedDate.value);
                final now = DateTime.now();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4.h,
                    crossAxisSpacing: 4.w,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final dayNumber = index - firstWeekday + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final date = DateTime(_month.year, _month.month, dayNumber);
                    final key = _ScheduleCalendar._keyFromDate(date);
                    final hasMessages =
                        (birdController.scheduledMessagesMap[key] ?? const [])
                            .isNotEmpty;
                    final isSelected = selectedDate != null &&
                        date.year == selectedDate.year &&
                        date.month == selectedDate.month &&
                        date.day == selectedDate.day;
                    final isToday = date.year == now.year &&
                        date.month == now.month &&
                        date.day == now.day;

                    return Entrance(
                      delayFactor: (index % 8) * 0.05,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      CustomColor.kPrimaryColor,
                                      CustomColor.kPrimaryMedium,
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.lg.r),
                            border: !isSelected && isToday
                                ? Border.all(
                                    color: CustomColor.kPrimaryColor,
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNumber',
                                style: AppTextStyles.bodySm.copyWith(
                                    color: isSelected
                                        ? CustomColor.kTextOnDark
                                        : isDark
                                            ? CustomColor.kTextOnDark
                                            : CustomColor.kDarkSecondaryColor),
                              ),
                              SizedBox(height: 3.h),
                              Container(
                                width: 4.5.r,
                                height: 4.5.r,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? CustomColor.kTextOnDark
                                      : hasMessages
                                          ? CustomColor.kPrimaryColor
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Text(
                  'Tap a date to view its schedules',
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close',
                      style: AppTextStyles.label.copyWith(
                          color: isDark
                              ? CustomColor.kTextOnDarkMuted
                              : CustomColor.kTextTertiary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
