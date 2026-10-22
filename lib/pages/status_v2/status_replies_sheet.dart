import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Replies list for an own status (realtime refreshed via socket).
class StatusRepliesSheet extends StatefulWidget {
  final String statusId;
  const StatusRepliesSheet({super.key, required this.statusId});

  @override
  State<StatusRepliesSheet> createState() => _StatusRepliesSheetState();
}

class _StatusRepliesSheetState extends State<StatusRepliesSheet> {
  late StatusController _ctrl;
  List<StatusReply> _replies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<StatusController>();
    _load();
  }

  Future<void> _load() async {
    await _ctrl.fetchReplies(widget.statusId);
    if (mounted) {
      setState(() {
        _replies = _ctrl.repliesMap[widget.statusId] ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.7.sh),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: CustomColor.kLightBorder,
                borderRadius: BorderRadius.circular(AppRadius.xxs.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text('Replies (${_replies.length})', style: AppTextStyles.headingSm),
          SizedBox(height: 12.h),
          if (_loading)
            const CustomLoading()
          else if (_replies.isEmpty)
            const AppEmptyState(
              icon: Icons.reply_rounded,
              title: 'No replies yet',
              message: 'Replies to this status appear here',
              layout: EmptyStateLayout.inline,
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _replies.length,
                separatorBuilder: (_, __) =>
                    Divider(color: CustomColor.kLightBorder, height: 1.h),
                itemBuilder: (ctx, i) => _replyRow(_replies[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _replyRow(StatusReply reply) {
    final author = reply.author;
    final authorId = author?['user_id']?.toString();
    final name = author != null
        ? '${author['user_first_name'] ?? ''} ${author['user_last_name'] ?? ''}'
            .trim()
        : 'User';
    final image = author?['user_image']?.toString();
    return InkWell(
      onTap: () {
        if (authorId == null || authorId.isEmpty) return;
        Get.back();
        _openChatWithReplier(authorId, name);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: (image?.isNotEmpty ?? false)
                  ? CachedNetworkImage(
                      imageUrl: '${Endpoints.mediaBaseUrl}$image',
                      width: 40.r,
                      height: 40.r,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Image.asset(
                        AppAssets.defaultProfilePic,
                        width: 40.r,
                        height: 40.r,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      AppAssets.defaultProfilePic,
                      width: 40.r,
                      height: 40.r,
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleSm.copyWith(
                        color: CustomColor.kPrimaryColor, fontSize: 12.sp),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    reply.srpMessage ?? '',
                    style: AppTextStyles.bodyMd,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _formatTime(reply.srpCreatedAt),
                    style: AppTextStyles.subtitle.copyWith(fontSize: 10.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithReplier(String userId, String fallbackName) {
    try {
      final home = Get.find<HomeController>();
      final myId = Get.find<UserController>().user?.userId?.toString();
      for (final r in home.singleChatsList) {
        final ids = (jsonDecode(r.rUsers ?? '[]') as List)
            .map((e) => e.toString())
            .toList();
        if (ids.contains(myId) && ids.contains(userId)) {
          final data = Get.find<ContactController>().getContactData(r);
          Get.to(() => ChatScreen(
                name: data.$1.isNotEmpty ? data.$1 : fallbackName,
                roomId: r.rId ?? '',
                userNumber: data.$3,
                receiverId: data.$2.isNotEmpty ? data.$2 : userId,
                isGroup: false,
                userProfile: r.rAvatar ?? '',
                userBio: data.$4,
              ));
          return;
        }
      }
      CustomSnackbar.show(
          title: 'No chat',
          message: 'Start a chat with $fallbackName to continue');
    } catch (_) {}
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    final dt = AppHelper.parseServerUtc(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
