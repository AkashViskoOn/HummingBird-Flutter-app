import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class SharedMediaStrip extends StatelessWidget {
  final String roomId;

  const SharedMediaStrip({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final messages = LocalDatabase.getMessages(roomId);
    final mediaMessages = messages
        .where((m) =>
            m.mMedia != null &&
            m.mMedia!.isNotEmpty &&
            ['1', '2', '3', '4'].contains(m.mMessageType))
        .take(4)
        .toList();

    if (mediaMessages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shared Media',
              style:
                  AppTextStyles.headingSm.copyWith(fontWeight: FontWeight.w800),
            ),
            PressScale(
              child: GestureDetector(
                onTap: () => _showAllMedia(context, roomId),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: CustomColor.kWhite,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                    border: Border.all(color: CustomColor.kLightBorder),
                    boxShadow: AppShadow.cardLight,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: CustomColor.kPrimaryColor,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14.r,
                        color: CustomColor.kPrimaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.md.r),
          decoration: BoxDecoration(
            color: CustomColor.kWhite,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(color: CustomColor.kLightBorder),
            boxShadow: AppShadow.cardLight,
          ),
          child: SizedBox(
            height: 80.r,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  ...mediaMessages.map((m) => Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: _MediaThumbnail(message: m),
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAllMedia(BuildContext context, String roomId) {
    final allMessages = LocalDatabase.getMessages(roomId);
    final allMedia = allMessages
        .where((m) =>
            m.mMedia != null &&
            m.mMedia!.isNotEmpty &&
            ['1', '2', '3', '4'].contains(m.mMessageType))
        .toList();

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllMediaSheet(mediaMessages: allMedia, roomId: roomId),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final Messages message;
  const _MediaThumbnail({required this.message});

  @override
  Widget build(BuildContext context) {
    final type = message.mMessageType;
    final url = message.mMedia;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: SizedBox(
        width: 80.r,
        height: 80.r,
        child: type == '1'
            ? CachedNetworkImage(
                imageUrl: '$url',
                fit: BoxFit.cover,
                placeholder: (_, __) => _Placeholder(
                    Icons.image_rounded, CustomColor.kPrimaryLight),
                errorWidget: (_, __, ___) => _Placeholder(
                    Icons.broken_image_rounded, Colors.red.shade50),
              )
            : _TypeIcon(type: type),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final String? type;
  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (type) {
      case '2':
        icon = Icons.description_rounded;
        color = CustomColor.kPrimaryLight;
      case '3':
        icon = Icons.audiotrack_rounded;
        color = CustomColor.kGoldLight;
      case '4':
        icon = Icons.videocam_rounded;
        color = CustomColor.kPrimaryLight;
      default:
        icon = Icons.insert_drive_file_rounded;
        color = CustomColor.kUltraLightBg;
    }
    return Container(
      color: color,
      child: Icon(icon, size: 28.r, color: CustomColor.kTextSecondary),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Placeholder(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: color,
        child: Icon(icon, size: 28.r, color: CustomColor.kTextSecondary));
  }
}

class _AllMediaSheet extends StatelessWidget {
  final List<Messages> mediaMessages;
  final String roomId;
  const _AllMediaSheet({required this.mediaMessages, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.85,
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Media',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: CustomColor.kTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: CustomColor.kUltraLightBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18.r,
                      color: CustomColor.kTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: CustomColor.kTextTertiary.withValues(alpha: 0.15)),
          Expanded(
            child: mediaMessages.isEmpty
                ? const AppEmptyState(
                    icon: Icons.perm_media_rounded,
                    title: 'No media shared yet',
                    message: 'Photos, videos and files appear here',
                    layout: EmptyStateLayout.inline,
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(12.r),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6.r,
                      mainAxisSpacing: 6.r,
                    ),
                    itemCount: mediaMessages.length,
                    itemBuilder: (_, index) {
                      final m = mediaMessages[index];
                      final type = m.mMessageType;
                      final url = '${Endpoints.mediaBaseUrl}${m.mMedia}';
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg.r),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: type == '1'
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                      color: CustomColor.kUltraLightBg),
                                  errorWidget: (_, __, ___) =>
                                      _TypeIcon(type: type),
                                )
                              : _TypeIcon(type: type),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
