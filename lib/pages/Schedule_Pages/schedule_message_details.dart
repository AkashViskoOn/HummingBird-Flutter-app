import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/schedule/edit_schedule_dialog.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Scheduled Message Details — content, status, repeat, start, end
/// condition, audience and occurrence counts, with Edit / Cancel /
/// Open Chat actions. Reached from the Schedule tab cards and the
/// scheduled-message bubble menu in chat.
class ScheduledMessageDetailsScreen extends StatefulWidget {
  final Messages message;

  const ScheduledMessageDetailsScreen({super.key, required this.message});

  @override
  State<ScheduledMessageDetailsScreen> createState() =>
      _ScheduledMessageDetailsScreenState();
}

class _ScheduledMessageDetailsScreenState
    extends State<ScheduledMessageDetailsScreen> {
  late Messages _message;
  BirdController get birdController => Get.find();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg =>
      _isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
  Color get _border => _isDark ? CustomColor.kDarkBorder : CustomColor.kScrim20;
  Color get _text1 =>
      _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
  Color get _text2 =>
      _isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
  Color get _text3 =>
      _isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
  }

  String get _status {
    final status = _message.mStatus?.toString();
    if (status == 'failed') return 'failed';
    if (status == 'sent') return 'sent';
    if (status == 'cancelled') return 'cancelled';
    return 'pending';
  }

  bool get _isPending => _status == 'pending';

  String _intervalLabel() {
    switch (_message.interval) {
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

  String _endCondition() {
    if (_message.interval == null || _message.interval == '0') return 'Once';
    if (_message.count == '-1' || _message.count == '0') return 'Forever';
    return 'After ${_message.count} occurrences';
  }

  String _audience() {
    final receiverId = _message.mReceiverId?.trim() ?? '';
    if (receiverId.isEmpty) return 'Group chat';
    final name =
        Get.find<ContactController>().getUserNameById(receiverId).trim();
    return name.isEmpty ? 'Unknown contact' : name;
  }

  String _preview() {
    if (_message.mMessageType != '0') {
      return AppHelper.getMediaName(fileType: _message.mMessageType ?? '');
    }
    final text = _message.mMessage?.trim() ?? '';
    return text.isEmpty ? '(no message text)' : text;
  }

  int get _totalOccurrences {
    if (_message.interval == null || _message.interval == '0') return 1;
    final count = int.tryParse(_message.count ?? '0') ?? 0;
    if (count <= 0) return -1;
    return count;
  }

  int get _sentCount => _status == 'sent' ? 1 : 0;

  int get _pendingCount {
    if (!_isPending) return 0;
    if (_message.interval == null || _message.interval == '0') return 1;
    return _totalOccurrences;
  }

  String _occurrenceLabel(int value) => value < 0 ? '∞' : '$value';

  Future<void> _editSchedule() async {
    await showAdaptiveDialog(
      context: context,
      builder: (_) => EditScheduleDialog(message: _message),
    );
    _refreshFromController();
  }

  Future<void> _cancelSchedule() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            _isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        ),
        title: Text(
          'Cancel schedule?',
          style: AppTextStyles.titleLg.copyWith(color: _text1),
        ),
        content: Text(
          'This scheduled message will be cancelled. This can\'t be undone.',
          style: AppTextStyles.subtitle.copyWith(color: _text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Keep it',
              style: GoogleFonts.poppins(
                color: _text3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Cancel schedule',
              style: GoogleFonts.poppins(
                color: CustomColor.dangerTextFor(_isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messageId = _message.mId;
    if (messageId == null) return;
    final success = await birdController.cancelScheduleById(messageId);
    if (success && mounted) Get.back();
  }

  void _refreshFromController() {
    final messageId = _message.mId;
    if (messageId == null) return;
    final fresh = birdController.allScheduledMessages
        .where((m) => m.mId == messageId)
        .toList();
    if (fresh.isEmpty) {
      if (mounted) Get.back();
      return;
    }
    setState(() => _message = fresh.first);
  }

  void _openChat() {
    final receiverId = _message.mReceiverId?.trim() ?? '';
    Get.to(
      () => ChatScreen(
        name: _audience(),
        userNumber: '',
        roomId: _message.mRoomId ?? '',
        receiverId: receiverId,
        isGroup: receiverId.isEmpty,
        userProfile:
            Get.find<ContactController>().getUserProfilePic(receiverId),
      ),
      arguments: {'isScroll': true, 'messageId': _message.mId ?? ''},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark
          ? CustomColor.kDarkBackground
          : CustomColor.kUltraLightPrimaryColor,
      appBar: CommonAppBar(title: 'Scheduled Message'),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: [
            _StatusBanner(status: _status),
            SizedBox(height: 14.h),
            _buildSection(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(9.r),
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      ),
                      child: Icon(
                        _message.mMessageType != '0'
                            ? Icons.attach_file_rounded
                            : Icons.chat_bubble_rounded,
                        color: CustomColor.kTextOnDark,
                        size: 18.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _preview(),
                        style: AppTextStyles.bodyMd.copyWith(color: _text1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _buildSection(
              children: [
                _infoRow(
                    Icons.schedule_rounded,
                    'Scheduled time',
                    AppHelper.formatDateTimeFromEpoch(
                        _message.mScheduledAt ?? '0',
                        'EEE, MMM d, yyyy · h:mm a')),
                _infoRow(
                    Icons.event_repeat_rounded, 'Repeat', _intervalLabel()),
                _infoRow(Icons.flag_rounded, 'End', _endCondition()),
                _infoRow(Icons.person_rounded, 'Audience', _audience()),
                _infoRow(
                  Icons.history_rounded,
                  'Created on',
                  _message.mCreatedAt != null
                      ? DateFormat('MMM d, yyyy h:mm a').format(
                          DateTime.tryParse(_message.mCreatedAt!) ??
                              DateTime.now())
                      : '—',
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _buildSection(
              children: [
                Text(
                  'Occurrences',
                  style: AppTextStyles.label.copyWith(color: _text2),
                ),
                SizedBox(height: 10.h),
                _countRow('Total', _occurrenceLabel(_totalOccurrences)),
                _countRow('Sent', '$_sentCount'),
                _countRow('Pending', _occurrenceLabel(_pendingCount)),
              ],
            ),
            SizedBox(height: 22.h),
            if (_isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Edit Schedule',
                      onTap: _editSchedule,
                      backgroundColor: CustomColor.kPrimaryFill,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      onTap: _cancelSchedule,
                      backgroundColor: CustomColor.kDangerFill,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
            ],
            AppButton(
              text: _status == 'sent' ? 'View in Chat' : 'Open Chat',
              onTap: _openChat,
              backgroundColor: CustomColor.kDarkPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 17.r, color: CustomColor.kPrimaryColor),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.subtitle.copyWith(color: _text2),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.label.copyWith(color: _text1),
          ),
        ],
      ),
    );
  }

  Widget _countRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.subtitle.copyWith(color: _text2),
          ),
          Text(
            value,
            style: AppTextStyles.subtitle
                .copyWith(color: CustomColor.kPrimaryColor),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color color, IconData icon, String label) = switch (status) {
      'sent' => (CustomColor.kSuccess, Icons.check_circle_rounded, 'Sent'),
      'cancelled' => (
          CustomColor.kDangerRed,
          Icons.cancel_rounded,
          'Cancelled'
        ),
      'failed' => (CustomColor.kDangerRed, Icons.error_rounded, 'Failed'),
      _ => (CustomColor.kPrimaryColor, Icons.schedule_rounded, 'Pending'),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.r, color: color),
          SizedBox(width: 10.w),
          Text(
            label,
            style: AppTextStyles.chatBadge.copyWith(color: color),
          ),
          const Spacer(),
          Text(
            status == 'pending'
                ? 'Waiting to send'
                : 'No further action needed',
            style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDarkSecondary
                    : CustomColor.kTextSecondary),
          ),
        ],
      ),
    );
  }
}
