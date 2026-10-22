import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/pages/status_updates/status_viewer_screen.dart';
import 'package:humming_bird/pages/status_updates/updates_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// WhatsApp-style status preview card shown inside a chat bubble when the
/// message carries `m_story_ref` (status reply / reaction / forward).
///
/// The card shows the exact referenced status (thumbnail for image/video,
/// colored text preview for text statuses) plus its caption/content, owner
/// name and the attached reply/reaction. Tapping it opens the EXACT story
/// (`story_id` stored in the message) in the status viewer — never the
/// author's latest story.
class StoryReferenceContainer extends StatelessWidget {
  final Messages message;

  const StoryReferenceContainer({super.key, required this.message});

  String _hexColor(String? hex, {String fallback = '#000000'}) {
    if (hex == null || hex.isEmpty) return fallback;
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    if (cleaned.length != 8) return fallback;
    return '#$cleaned';
  }

  void _openStory(Map<String, dynamic> ref) {
    final storyId = ref['story_id']?.toString();
    final ctrl = Get.find<StatusController>();
    if (storyId != null && storyId.isNotEmpty) {
      // Own story first (e.g. a forward of your own status) — but only if it
      // hasn't expired yet; expired ones fall through to the fallback below.
      final ownIdx =
          ctrl.myStatuses.indexWhere((s) => !s.isExpired && s.suId == storyId);
      if (ownIdx != -1) {
        Get.to(() => StatusViewerScreen(
              updates: const [],
              myStatuses: ctrl.myStatuses.toList(),
              myUser: Get.find<UserController>().user?.toJson(),
              initialIndex: ownIdx,
            ));
        return;
      }
      // Friend story: group by author, then match the EXACT story id.
      final grouped = <String, List<FriendUpdate>>{};
      for (final u in ctrl.friendUpdates) {
        if (u.update == null || u.update!.isExpired) continue;
        final authorId = u.author?['user_id']?.toString() ?? 'unknown';
        grouped.putIfAbsent(authorId, () => []).add(u);
      }
      final allGroups = grouped.values.toList();
      for (var gi = 0; gi < allGroups.length; gi++) {
        final idx = allGroups[gi].indexWhere((f) => f.update?.suId == storyId);
        if (idx != -1) {
          Get.to(() => StatusViewerScreen(
                updates: allGroups[gi],
                initialIndex: idx,
                allGroups: allGroups,
                initialGroupIndex: gi,
              ));
          return;
        }
      }
    }
    // The referenced status is expired, deleted or not in the local feed —
    // refresh once and land on the Status tab, keeping the message intact.
    Utils.showGetSnackBar('This status is no longer available');
    ctrl.refreshAll();
    Get.to(() => const UpdatesScreen());
  }

  /// Clean fallback when the status reference can't be resolved (expired,
  /// deleted, or the payload is unreadable) — the message stays a status
  /// message, never degrades into an ordinary chat message.
  Widget _buildUnavailableCard() {
    return Container(
      constraints: BoxConstraints(maxWidth: 0.62.sw),
      padding: EdgeInsets.symmetric(
          horizontal: AppRadius.sm.r, vertical: AppRadius.xs.r),
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        border: Border.all(color: CustomColor.kLightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.w,
            height: 56.h,
            decoration: BoxDecoration(
              color: CustomColor.kPrimaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md.r),
            ),
            child: Icon(Icons.history_toggle_off_rounded,
                color: CustomColor.kPrimaryColor, size: 20.r),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline_rounded,
                        size: 13.r, color: CustomColor.kPrimaryColor),
                    SizedBox(width: 4.w),
                    Text(
                      'Status',
                      style: AppTextStyles.label.copyWith(
                        color: CustomColor.kPrimaryColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Status unavailable',
                  style: AppTextStyles.label.copyWith(
                    color: CustomColor.kTextSecondary,
                    fontSize: 11.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = message.storyRef;
    if (message.mStoryRef == null || message.mStoryRef!.isEmpty) {
      // Not a status message at all — render nothing.
      return const SizedBox.shrink();
    }
    if (kDebugMode) {
      debugPrint('STATUS-REPLY-TRACE → StoryReferenceContainer render '
          'parsed=${ref != null} type=${ref?['reply_type']} '
          'storyId=${ref?['story_id']}');
    }
    if (ref == null || (ref['story_id']?.toString() ?? '').isEmpty) {
      // The reference exists but is unreadable/empty — keep the message
      // intact and show a clean unavailable card instead of a plain message.
      return _buildUnavailableCard();
    }

    final replyType = ref['reply_type']?.toString() ?? 'reply';
    final isReaction = replyType == 'reaction';
    final isForward = replyType == 'forward';
    final mediaUrl = ref['media_url']?.toString() ?? '';
    final mediaType = ref['media_type']?.toString() ?? 'text';
    final content = ref['content']?.toString() ?? '';
    final caption = ref['caption']?.toString() ?? '';
    final ownerName = ref['story_owner_name']?.toString() ?? 'Story';
    final storyText =
        caption.isNotEmpty ? caption : (content.isNotEmpty ? content : '');
    final isMedia =
        mediaUrl.isNotEmpty && (mediaType == 'image' || mediaType == 'video');
    final isVideo = isMedia && mediaType == 'video';
    final bgColor = Color(int.parse(
        _hexColor(ref['bg_color']?.toString()).replaceAll('#', ''),
        radix: 16));
    final textColor = Color(int.parse(
        _hexColor(ref['text_color']?.toString(), fallback: '#FFFFFF')
            .replaceAll('#', ''),
        radix: 16));

    final Widget thumb;
    if (isMedia) {
      thumb = Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: '${Endpoints.mediaBaseUrl}$mediaUrl',
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              color: bgColor,
              alignment: Alignment.center,
              child: Text(
                'Aa',
                style: AppTextStyles.titleSm
                    .copyWith(color: CustomColor.kTextOnDark),
              ),
            ),
          ),
          if (isVideo)
            Center(
              child: Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: CustomColor.kScrim45,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: CustomColor.kTextOnDark, size: 16.r),
              ),
            ),
        ],
      );
    } else {
      thumb = Container(
        color: bgColor,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aa',
              style: AppTextStyles.titleSm.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (storyText.isNotEmpty)
              Text(
                storyText,
                style: AppTextStyles.caption.copyWith(color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openStory(ref),
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.62.sw),
        padding: EdgeInsets.symmetric(
            horizontal: AppRadius.sm.r, vertical: AppRadius.xs.r),
        decoration: BoxDecoration(
          color: CustomColor.kTextOnDark,
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          border: Border.all(color: CustomColor.kLightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                  child: SizedBox(width: 44.w, height: 56.h, child: thumb),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline_rounded,
                              size: 13.r, color: CustomColor.kPrimaryColor),
                          SizedBox(width: 4.w),
                          Text(
                            'Status',
                            style: AppTextStyles.label.copyWith(
                              color: CustomColor.kPrimaryColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        ownerName,
                        style: AppTextStyles.label.copyWith(
                          color: CustomColor.kTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isReaction
                            ? 'Reacted to status'
                            : isForward
                                ? 'Forwarded status'
                                : 'Replying to status',
                        style: AppTextStyles.caption.copyWith(
                          color: CustomColor.kTextSecondary,
                          fontSize: 10.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (storyText.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          storyText,
                          style: AppTextStyles.caption.copyWith(
                            color: CustomColor.kTextSecondary,
                            fontSize: 10.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // The reply text / reaction lives in the message bubble itself
            // (m_message), so the card never repeats it — only forwards get
            // a label since they have no attached message text.
            if (isForward)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  'Forwarded',
                  style: AppTextStyles.caption.copyWith(
                    color: CustomColor.kTextSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
