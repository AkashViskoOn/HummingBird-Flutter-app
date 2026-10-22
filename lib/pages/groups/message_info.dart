import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

void showMessageInfoSheet(String messageId) {
  Get.bottomSheet(
    MessageInfoSheet(messageId: messageId),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
  );
}

class MessageInfoSheet extends StatefulWidget {
  final String messageId;
  const MessageInfoSheet({super.key, required this.messageId});

  @override
  State<MessageInfoSheet> createState() => _MessageInfoSheetState();
}

class _MessageInfoSheetState extends State<MessageInfoSheet> {
  late ChatController chatController;
  late ContactController contactController;
  late GroupController groupController;
  List<String> seenBy = [];
  List<User> remaining = [];
  Messages? message;
  String userId = '';

  @override
  void initState() {
    super.initState();
    chatController = Get.find();
    contactController = Get.find();
    groupController = Get.find();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      message =
          chatController.messages.firstWhere((e) => e.mId == widget.messageId);
    } catch (_) {
      message = null;
    }
    if (message != null) {
      try {
        final decoded = jsonDecode(message!.mSeenBy ?? '');
        seenBy = (decoded as List).cast<String>();
      } catch (_) {
        seenBy = [];
      }
    }
    remaining = groupController.groupData?.members ?? [];
    userId = await chatController.getUserId();
    remaining
        .removeWhere((e) => e.userId == userId || seenBy.contains(e.userId));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      constraints: BoxConstraints(maxHeight: Get.height * 0.75),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Text(
                      'Message Info',
                      style: AppTextStyles.headingMd
                          .copyWith(color: CustomColor.kTextPrimary),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(AppRadius.lg.r),
                      child: Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: CustomColor.kUltraLightBg,
                          borderRadius: BorderRadius.circular(AppRadius.lg.r),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.close_rounded,
                            size: 18.r, color: CustomColor.kTextTertiary),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              if (message != null) ...[
                _buildMessagePreview(),
                SizedBox(height: 16.h),
                _buildTimeline(),
              ],
              if (seenBy.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _buildSectionHeader('Read By (${seenBy.length})'),
                _buildUsersList(seenBy),
              ],
              if (remaining.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _buildSectionHeader('Remaining (${remaining.length})'),
                _buildRemainingList(),
              ],
              if (message == null)
                Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text(
                    'Message not found',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: CustomColor.kTextTertiary),
                  ),
                ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagePreview() {
    final msg = message!;
    final senderName = msg.mSenderId != null
        ? contactController.getUserNameById(msg.mSenderId!)
        : 'Unknown';
    final senderPic = msg.mSenderId != null
        ? contactController.getUserProfilePic(msg.mSenderId!)
        : '';
    final timestamp = msg.mCreatedAt ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CustomColor.kPrimaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundImage: senderPic.isNotEmpty
                ? CachedNetworkImageProvider(
                    '${Endpoints.mediaBaseUrl}$senderPic')
                : const AssetImage(AppAssets.defaultProfilePic)
                    as ImageProvider,
            onBackgroundImageError: (_, __) {},
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: AppTextStyles.titleSm
                      .copyWith(color: CustomColor.kTextPrimary),
                ),
                SizedBox(height: 4.h),
                Text(
                  msg.mMessage ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle
                      .copyWith(color: CustomColor.kTextSecondary),
                ),
                SizedBox(height: 6.h),
                Text(
                  _formatTimestamp(timestamp),
                  style: AppTextStyles.caption
                      .copyWith(color: CustomColor.kTextTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: CustomColor.kUltraLightBg,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border:
            Border.all(color: CustomColor.kLightBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _timelineRow(
            Icons.check_circle_outline,
            'Sent',
            message?.mCreatedAt ?? '',
            isFirst: true,
          ),
          SizedBox(height: 12.h),
          _timelineRow(
            Icons.done_all_rounded,
            'Delivered',
            message?.mCreatedAt ?? '',
          ),
          SizedBox(height: 12.h),
          _timelineRow(
            Icons.visibility_rounded,
            'Read',
            seenBy.isNotEmpty ? message?.mCreatedAt ?? '' : '',
            isLast: true,
            value: seenBy.isNotEmpty
                ? '${seenBy.length} ${seenBy.length == 1 ? 'person' : 'people'}'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(IconData icon, String label, String timestamp,
      {bool isFirst = false, bool isLast = false, String? value}) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 6.h,
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
              ),
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md.r),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16.r, color: CustomColor.kPrimaryColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 6.h,
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.subtitle
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
              const Spacer(),
              if (value != null)
                Text(
                  value,
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kPrimaryColor),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Text(
        title,
        style: AppTextStyles.titleSm.copyWith(color: CustomColor.kTextPrimary),
      ),
    );
  }

  Widget _buildUsersList(List<String> userIds) {
    return SizedBox(
      height: 72.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: userIds.length,
        itemBuilder: (context, index) {
          final uid = userIds[index];
          final profile = contactController.getUserProfilePic(uid);
          final name = contactController.getUserNameById(uid);
          return Container(
            width: 64.w,
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundImage: profile.isNotEmpty
                      ? CachedNetworkImageProvider(
                          '${Endpoints.mediaBaseUrl}$profile')
                      : const AssetImage(AppAssets.defaultProfilePic)
                          as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                ),
                SizedBox(height: 4.h),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSm
                      .copyWith(color: CustomColor.kTextSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemainingList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: remaining.length,
      itemBuilder: (context, index) {
        final user = remaining[index];
        final profile = user.userImage ?? '';
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundImage: profile.isNotEmpty
                    ? CachedNetworkImageProvider(
                        '${Endpoints.mediaBaseUrl}$profile')
                    : const AssetImage(AppAssets.defaultProfilePic)
                        as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  contactController.getUserNameById(user.userId ?? ''),
                  style: AppTextStyles.subtitle
                      .copyWith(color: CustomColor.kTextPrimary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return ts;
    }
  }
}
