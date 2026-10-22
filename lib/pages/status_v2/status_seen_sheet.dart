import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Instagram-style "Seen by" sheet — swipe up on your own story to reveal
/// the list of users who viewed it (most recent first).
class StatusSeenSheet extends StatefulWidget {
  final StatusModel status;
  const StatusSeenSheet({super.key, required this.status});

  @override
  State<StatusSeenSheet> createState() => _StatusSeenSheetState();
}

class _StatusSeenSheetState extends State<StatusSeenSheet> {
  late StatusController _ctrl;
  List<Map<String, dynamic>> _viewers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<StatusController>();
    _viewers = _ctrl.viewersMap[widget.status.suId] ?? [];
    _load();
  }

  Future<void> _load() async {
    await _ctrl.fetchViewers(widget.status.suId!);
    if (mounted) {
      setState(() {
        _viewers = _ctrl.viewersMap[widget.status.suId] ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
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
          SizedBox(height: 16.h),
          Row(
            children: [
              Text('Seen by', style: AppTextStyles.headingSm),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: CustomColor.kUltraLightPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                ),
                child: Text(
                  '${widget.status.viewCount ?? _viewers.length}',
                  style: AppTextStyles.titleSm
                      .copyWith(color: CustomColor.kPrimaryColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_loading)
            const CustomLoading()
          else if (_viewers.isEmpty)
            const AppEmptyState(
              icon: Icons.visibility_outlined,
              title: 'No one has seen this yet',
              message: 'Views of this status appear here',
              layout: EmptyStateLayout.inline,
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _viewers.length,
                separatorBuilder: (_, __) =>
                    Divider(color: CustomColor.kLightBorder, height: 1.h),
                itemBuilder: (ctx, i) => _viewerRow(_viewers[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _viewerRow(Map<String, dynamic> u) {
    final name =
        '${u['user_first_name'] ?? ''} ${u['user_last_name'] ?? ''}'.trim();
    final reaction = u['reaction']?.toString();
    final replied = u['replied'] == true;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          ClipOval(
            child: (u['user_image']?.toString().isNotEmpty ?? false)
                ? CachedNetworkImage(
                    imageUrl: '${Endpoints.mediaBaseUrl}${u['user_image']}',
                    width: 44.r,
                    height: 44.r,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Image.asset(
                      AppAssets.defaultProfilePic,
                      width: 44.r,
                      height: 44.r,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    AppAssets.defaultProfilePic,
                    width: 44.r,
                    height: 44.r,
                    fit: BoxFit.cover,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.isEmpty ? 'User' : name,
                        style: AppTextStyles.titleSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (reaction != null && reaction.isNotEmpty) ...[
                      SizedBox(width: 6.w),
                      Text(reaction, style: TextStyle(fontSize: 14.sp)),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Viewed ${_formatTime(u['viewed_at']?.toString())}',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 11.sp),
                    ),
                    if (replied) ...[
                      SizedBox(width: 6.w),
                      Icon(Icons.reply_rounded,
                          size: 12.r, color: CustomColor.kPrimaryColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';
    final dt = AppHelper.parseServerUtc(value);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
