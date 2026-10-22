import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/components/scheduled_moments/countdown_timer.dart';

import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class MomentCard extends StatelessWidget {
  final ScheduledMoment moment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onPublish;

  const MomentCard({
    super.key,
    required this.moment,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = moment.isPending;
    final epoch = moment.scheduledEpoch;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        border: Border.all(
          color: isDark
              ? CustomColor.kDarkBorder
              : CustomColor.kLightBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((moment.smCaption ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Text(
                      moment.smCaption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                          color: isDark
                              ? CustomColor.kTextOnDark
                              : CustomColor.kTextPrimary),
                    ),
                  ),
                if (isPending && epoch != null) ...[
                  CountdownTimer(epochSeconds: epoch),
                  SizedBox(height: 4.h),
                ],
                _buildMeta(isDark),
              ],
            ),
          ),
          if (!isPending) _buildStatusBadge(isDark),
          _buildActions(isDark),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (moment.smMediaType == 'text' || (moment.smMediaUrl?.isEmpty ?? true)) {
      return Container(
        height: 140.h,
        decoration: BoxDecoration(
          gradient: CustomColor.primaryGradient,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.text_fields_rounded,
            color: CustomColor.kTextOnDark, size: 40.r),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
      child: CachedNetworkImage(
        imageUrl: '${Endpoints.mediaBaseUrl}${moment.smMediaUrl}',
        height: 140.h,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 140.h,
          color: CustomColor.kUltraLightPrimary,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 140.h,
          color: CustomColor.kUltraLightPrimary,
          child: Icon(Icons.broken_image_rounded,
              color: CustomColor.kTextTertiary),
        ),
      ),
    );
  }

  Widget _buildMeta(bool isDark) {
    final scheduledDate = moment.scheduledEpoch != null
        ? DateTime.fromMillisecondsSinceEpoch(moment.scheduledEpoch! * 1000)
        : null;

    return Row(
      children: [
        Icon(Icons.schedule_rounded,
            size: 12.r, color: CustomColor.kTextTertiary),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            scheduledDate != null
                ? DateFormat('MMM d, h:mm a').format(scheduledDate)
                : 'No date',
            style: AppTextStyles.labelSm
                .copyWith(color: CustomColor.kTextTertiary),
          ),
        ),
        SizedBox(width: 8.w),
        Icon(Icons.visibility_rounded,
            size: 12.r, color: CustomColor.kTextTertiary),
        SizedBox(width: 4.w),
        Text(
          _visibilityLabel(moment.smVisibility ?? 'everyone'),
          style:
              AppTextStyles.labelSm.copyWith(color: CustomColor.kTextTertiary),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isDark) {
    final label = moment.isPublished ? 'Published' : 'Expired';
    final color = moment.isPublished
        ? CustomColor.kOnlineGreen
        : CustomColor.kTextTertiary;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.r),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: color),
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? CustomColor.kDarkBorder
                : CustomColor.kLightBorder.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          _ActionChip(icon: Icons.edit_rounded, label: 'Edit', onTap: onEdit),
          _ActionChip(
              icon: Icons.copy_rounded, label: 'Duplicate', onTap: onDuplicate),
          if (moment.isPending)
            _ActionChip(
              icon: Icons.publish_rounded,
              label: 'Publish',
              color: CustomColor.kOnlineGreen,
              onTap: onPublish,
            ),
          _ActionChip(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: CustomColor.kDangerRed,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  String _visibilityLabel(String v) {
    switch (v) {
      case 'close_friends':
        return 'Close Friends';
      case 'family':
        return 'Family';
      case 'contacts':
        return 'Contacts';
      case 'only_me':
        return 'Only Me';
      default:
        return 'Everyone';
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: color?.withValues(alpha: 0.2) ??
                    CustomColor.kLightBorder.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 16.r, color: color ?? CustomColor.kTextSecondary),
              SizedBox(height: 2.h),
              Text(
                label,
                style: AppTextStyles.labelSm
                    .copyWith(color: color ?? CustomColor.kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
