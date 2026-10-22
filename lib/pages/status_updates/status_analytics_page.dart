import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class StatusAnalyticsPage extends StatefulWidget {
  const StatusAnalyticsPage({super.key});

  @override
  State<StatusAnalyticsPage> createState() => _StatusAnalyticsPageState();
}

class _StatusAnalyticsPageState extends State<StatusAnalyticsPage> {
  final StatusController _ctrl = Get.find();

  @override
  void initState() {
    super.initState();
    _ctrl.fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: CommonAppBar(title: 'Status Analytics'),
      body: Obx(() {
        final analytics = _ctrl.analytics.value;
        if (_ctrl.analyticsLoading.value) {
          return const CustomLoading();
        }
        if (_ctrl.analyticsError.value || analytics == null) {
          return AppEmptyState(
            icon: Icons.query_stats_rounded,
            title: 'Could not load analytics',
            message: 'Check your connection and try again.',
            actionLabel: 'Try Again',
            onAction: _ctrl.fetchAnalytics,
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16.w, 16.w, 16.w, 16.w + MediaQuery.of(context).padding.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _statCard(
                      isDark: isDark,
                      icon: Icons.visibility,
                      label: 'Total Views',
                      value: '${analytics.totalViews}'),
                  SizedBox(width: 12.w),
                  _statCard(
                      isDark: isDark,
                      icon: Icons.reply,
                      label: 'Replies',
                      value: '${analytics.totalReplies}'),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _statCard(
                      isDark: isDark,
                      icon: Icons.emoji_emotions,
                      label: 'Reactions',
                      value: '${analytics.totalReactions}'),
                  SizedBox(width: 12.w),
                  _statCard(
                      isDark: isDark,
                      icon: Icons.trending_up,
                      label: 'Reach',
                      value: analytics.reach.toStringAsFixed(0)),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _statCard(
                      isDark: isDark,
                      icon: Icons.done_all,
                      label: 'Completion',
                      value: '${analytics.completionRate}%'),
                  SizedBox(width: 12.w),
                  _statCard(
                      isDark: isDark,
                      icon: Icons.post_add,
                      label: 'Total Posts',
                      value: '${analytics.totalUpdates}'),
                ],
              ),
              SizedBox(height: 24.h),
              Text('Recent Statuses', style: AppTextStyles.headingSm),
              SizedBox(height: 12.h),
              ...analytics.updates.map((u) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CustomColor.kDarkSurface
                          : CustomColor.kTextOnDark,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    ),
                    child: ListTile(
                      title: Text(
                        u['content']?.toString() ?? '(no content)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle,
                      ),
                      subtitle: Text(
                        '${u['views'] ?? 0} views · ${u['reactions'] ?? 0} reactions · ${u['replies'] ?? 0} replies',
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kTextTertiary),
                      ),
                      trailing: Text(
                        _dateOnly(u['created_at']?.toString()),
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kTextTertiary),
                      ),
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }

  String _dateOnly(String? value) {
    if (value == null || value.length < 10) return value ?? '';
    return value.substring(0, 10);
  }

  Widget _statCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: CustomColor.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          boxShadow: [
            BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: CustomColor.kOverlay70, size: 20.r),
            SizedBox(height: 8.h),
            Text(value,
                style: AppTextStyles.displayMedium
                    .copyWith(color: CustomColor.kTextOnDark)),
            Text(label,
                style: AppTextStyles.bodySm
                    .copyWith(color: CustomColor.kOverlay70)),
          ],
        ),
      ),
    );
  }
}
