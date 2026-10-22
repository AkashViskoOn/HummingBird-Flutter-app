import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Bottom sheet showing reactions grouped by emoji for an own status.
class StatusReactionsSheet extends StatefulWidget {
  final String statusId;
  const StatusReactionsSheet({super.key, required this.statusId});

  @override
  State<StatusReactionsSheet> createState() => _StatusReactionsSheetState();
}

class _StatusReactionsSheetState extends State<StatusReactionsSheet> {
  late StatusController _ctrl;
  Map<String, int> _counts = {};
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<StatusController>();
    _load();
  }

  Future<void> _load() async {
    final res = await _ctrl.fetchReactionsDetail(widget.statusId);
    if (res != null && res['data'] != null) {
      final reactions = res['data']['reactions'] as Map<String, dynamic>? ?? {};
      final users = res['data']['users'] as List? ?? [];
      if (mounted) {
        setState(() {
          _counts = reactions.map(
              (k, v) => MapEntry(k, (v as Map<String, dynamic>)['count'] ?? 0));
          _users = users.map((u) => Map<String, dynamic>.from(u)).toList();
          _loading = false;
        });
      }
    } else if (mounted) {
      setState(() => _loading = false);
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
          Text('Reactions', style: AppTextStyles.headingSm),
          SizedBox(height: 12.h),
          if (_loading)
            const CustomLoading()
          else if (_counts.isEmpty)
            const AppEmptyState(
              icon: Icons.mood_rounded,
              title: 'No reactions yet',
              message: 'Reactions to this status appear here',
              layout: EmptyStateLayout.inline,
            )
          else
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _counts.entries.map((e) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: CustomColor.kUltraLightPrimary,
                          borderRadius: BorderRadius.circular(AppRadius.pill.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.key, style: TextStyle(fontSize: 16.sp)),
                            SizedBox(width: 6.w),
                            Text(
                              '${e.value}',
                              style: AppTextStyles.titleSm
                                  .copyWith(color: CustomColor.kPrimaryColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 12.h),
                  Divider(color: CustomColor.kLightBorder, height: 1.h),
                  if (_users.isNotEmpty) ..._users.map((u) => _userRow(u)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _userRow(Map<String, dynamic> u) {
    final name =
        '${u['user_first_name'] ?? ''} ${u['user_last_name'] ?? ''}'.trim();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          ClipOval(
            child: (u['user_image']?.toString().isNotEmpty ?? false)
                ? CachedNetworkImage(
                    imageUrl: '${Endpoints.mediaBaseUrl}${u['user_image']}',
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
            child: Text(
              name.isEmpty ? 'User' : name,
              style: AppTextStyles.titleSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
