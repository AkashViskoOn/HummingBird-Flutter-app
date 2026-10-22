import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/pages/status_v2/status_story_viewer.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// WhatsApp-style Status Archive — shows my archived statuses.
class StatusArchiveScreen extends StatefulWidget {
  const StatusArchiveScreen({super.key});

  @override
  State<StatusArchiveScreen> createState() => _StatusArchiveScreenState();
}

class _StatusArchiveScreenState extends State<StatusArchiveScreen> {
  late StatusController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.isRegistered<StatusController>()
        ? Get.find<StatusController>()
        : Get.put(StatusController(), permanent: true);
    _ctrl.fetchArchivedList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Archive'),
      body: RefreshIndicator(
        onRefresh: () => _ctrl.fetchArchivedList(),
        color: CustomColor.kPrimaryColor,
        backgroundColor: CustomColor.kTextOnDark,
        child: Obx(() {
          final items = _ctrl.archivedUpdates;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84.r,
                    height: 84.r,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CustomColor.kUltraLightPrimary,
                    ),
                    child: const Icon(
                      Icons.archive_rounded,
                      color: CustomColor.kPrimaryColor,
                      size: 44,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text('No archived statuses', style: AppTextStyles.headingSm),
                  SizedBox(height: 8.h),
                  Text(
                    'Statuses you archive appear here',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final status = items[i];
              return _ArchiveTile(
                status: status,
                onRestore: () async {
                  final ok = await _ctrl.archiveUpdate(status.suId!, false);
                  if (ok) _ctrl.fetchArchivedList();
                },
                onView: () {
                  Get.to(() => StatusStoryViewer(
                        myStatuses: items,
                        initialIndex: i,
                      ));
                },
              );
            },
          );
        }),
      ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  final StatusModel status;
  final VoidCallback onRestore;
  final VoidCallback onView;

  const _ArchiveTile({
    required this.status,
    required this.onRestore,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final mediaUrl = status.suMediaUrl;
    final isImage = status.suMediaType == 'image';
    final isVideo = status.suMediaType == 'video';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark,
        borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
        border:
            Border.all(color: CustomColor.kLightBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
            child: mediaUrl != null && mediaUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${Endpoints.mediaBaseUrl}$mediaUrl',
                    width: 56.r,
                    height: 56.r,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 56.r,
                      height: 56.r,
                      color: CustomColor.kUltraLightBg,
                      child: const Icon(
                        Icons.image_rounded,
                        color: CustomColor.kTextTertiary,
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56.r,
                      height: 56.r,
                      color: CustomColor.kUltraLightBg,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: CustomColor.kTextTertiary,
                      ),
                    ),
                  )
                : Container(
                    width: 56.r,
                    height: 56.r,
                    color: CustomColor.kUltraLightPrimary,
                    child: const Icon(
                      Icons.text_fields_rounded,
                      color: CustomColor.kPrimaryColor,
                    ),
                  ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVideo
                      ? 'Video status'
                      : isImage
                          ? 'Photo status'
                          : (status.suCaption?.isNotEmpty == true
                              ? status.suCaption!
                              : 'Text status'),
                  style: AppTextStyles.titleSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  _formatDate(status.suCreatedAt),
                  style: AppTextStyles.subtitle.copyWith(fontSize: 12.sp),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View',
            icon: const Icon(Icons.visibility_rounded,
                color: CustomColor.kPrimaryColor),
            onPressed: onView,
          ),
          IconButton(
            tooltip: 'Restore',
            icon: const Icon(Icons.unarchive_rounded,
                color: CustomColor.kPrimaryColor),
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today · ${_two(dt.hour)}:${_two(dt.minute)}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday · ${_two(dt.hour)}:${_two(dt.minute)}';
    }
    return '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
