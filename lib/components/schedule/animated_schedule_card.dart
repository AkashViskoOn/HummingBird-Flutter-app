import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AnimatedScheduleCard extends StatefulWidget {
  final Messages message;
  final String receiverName;
  final String preview;
  final String status;
  final String category;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenChat;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onShare;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMarkComplete;
  final bool isPinned;
  final VoidCallback? onPin;

  const AnimatedScheduleCard({
    super.key,
    required this.message,
    required this.receiverName,
    required this.preview,
    this.status = 'pending',
    this.category = '',
    required this.index,
    required this.onTap,
    this.onEdit,
    this.onOpenChat,
    this.onDuplicate,
    this.onMarkComplete,
    required this.onReschedule,
    required this.onCancel,
    this.onRetry,
    this.onShare,
    this.isPinned = false,
    this.onPin,
  });

  @override
  State<AnimatedScheduleCard> createState() => _AnimatedScheduleCardState();
}

class _AnimatedScheduleCardState extends State<AnimatedScheduleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _categoryColor() {
    switch (widget.category.toLowerCase()) {
      case 'birthday':
        return CustomColor.kWarning;
      case 'anniversary':
        return CustomColor.kBrandPink;
      case 'reminder':
        return CustomColor.kInfo;
      case 'promotional':
        return CustomColor.kSuccess;
      case 'meeting':
        return CustomColor.kBrandPurple;
      case 'follow-up':
        return CustomColor.kWarning;
      case 'greeting':
        return CustomColor.kInfo;
      case 'emergency':
        return CustomColor.kDangerRed;
      default:
        return CustomColor.kPrimaryColor;
    }
  }

  Color _statusColor() {
    switch (widget.status) {
      case 'sent':
        return CustomColor.kSuccess;
      case 'failed':
        return CustomColor.kDangerRed;
      case 'sending':
        return CustomColor.kWarning;
      default:
        return CustomColor.kTextTertiary;
    }
  }

  String _statusLabel() {
    switch (widget.status) {
      case 'sent':
        return 'Sent';
      case 'failed':
        return 'Failed';
      case 'sending':
        return 'Sending';
      default:
        return 'Pending';
    }
  }

  IconData _statusIcon() {
    switch (widget.status) {
      case 'sent':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.error_rounded;
      case 'sending':
        return Icons.sync_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String _repeatLabel() {
    switch (widget.message.interval) {
      case '1':
        return 'Daily';
      case '2':
        return 'Weekly';
      case '3':
        return 'Monthly';
      case '4':
        return 'Yearly';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _categoryColor();
    final statusColor = _statusColor();

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30.h * _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(
              color: widget.status == 'failed'
                  ? CustomColor.kDangerRed.withValues(alpha: 0.15)
                  : (isDark ? CustomColor.kDarkBorder : CustomColor.kScrim20),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.status == 'failed'
                    ? CustomColor.kDangerRed.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: isDark ? 0.0 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            onTap: widget.onTap,
            onLongPress: widget.onEdit,
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44.r,
                        height: 44.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor,
                              categoryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.fourteen.r),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.schedule_send_rounded,
                          color: CustomColor.kTextOnDark,
                          size: 21.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.preview.isEmpty
                                  ? 'Scheduled message'
                                  : widget.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.chatBadge.copyWith(
                                  color: isDark
                                      ? CustomColor.kTextOnDark
                                      : CustomColor.kDarkSecondaryColor),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'To ${widget.receiverName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                  color: isDark
                                      ? CustomColor.kTextOnDarkMuted
                                      : CustomColor.k2SecondaryColor),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      if (widget.isPinned)
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Icon(Icons.push_pin_rounded,
                              size: 14.r, color: CustomColor.kPrimaryColor),
                        ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(),
                              size: 12.r,
                              color: statusColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              _statusLabel(),
                              style: AppTextStyles.labelSm
                                  .copyWith(color: statusColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      _MetaChip2(
                        icon: Icons.access_time_rounded,
                        label: AppHelper.formatDateTimeFromEpoch(
                            widget.message.mScheduledAt ?? '0', 'h:mm a'),
                      ),
                      if (widget.category.isNotEmpty)
                        _MetaChip2(
                          icon: Icons.label_rounded,
                          label: widget.category,
                          color: categoryColor,
                        ),
                      if (_repeatLabel().isNotEmpty)
                        _MetaChip2(
                          icon: Icons.repeat_rounded,
                          label: _repeatLabel(),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onOpenChat != null)
                        _ActionButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          tooltip: 'Open Chat',
                          color: CustomColor.kPrimaryColor,
                          bgColor: CustomColor.kUltraLightPrimary,
                          onTap: widget.onOpenChat!,
                        ),
                      if (widget.onPin != null)
                        _ActionButton(
                          icon: widget.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                          tooltip: widget.isPinned ? 'Unpin' : 'Pin',
                          color: CustomColor.kDarkPrimaryColor,
                          bgColor: CustomColor.kUltraLightPrimary,
                          onTap: widget.onPin!,
                        ),
                      if (widget.onShare != null)
                        _ActionButton(
                          icon: Icons.share_rounded,
                          tooltip: 'Share',
                          color: CustomColor.kPrimaryColor,
                          bgColor: CustomColor.kUltraLightPrimary,
                          onTap: widget.onShare!,
                        ),
                      if (widget.status == 'failed' && widget.onRetry != null)
                        _ActionButton(
                          icon: Icons.refresh_rounded,
                          tooltip: 'Retry',
                          color: CustomColor.kPrimaryColor,
                          bgColor: CustomColor.kLightPrimaryColor,
                          onTap: widget.onRetry!,
                        ),
                      if (widget.onDuplicate != null)
                        _ActionButton(
                          icon: Icons.content_copy_rounded,
                          tooltip: 'Duplicate',
                          color: CustomColor.kPrimaryColor,
                          bgColor: CustomColor.kUltraLightPrimary,
                          onTap: widget.onDuplicate!,
                        ),
                      if (widget.onMarkComplete != null)
                        _ActionButton(
                          icon: Icons.check_circle_outline_rounded,
                          tooltip: 'Mark Complete',
                          color: CustomColor.kSuccess,
                          bgColor: CustomColor.kUltraLightPrimary,
                          onTap: widget.onMarkComplete!,
                        ),
                      _ActionButton(
                        icon: Icons.event_repeat_rounded,
                        tooltip: 'Reschedule',
                        color: CustomColor.kDarkPrimaryColor,
                        bgColor: CustomColor.kUltraLightPrimary,
                        onTap: widget.onReschedule,
                      ),
                      SizedBox(width: 6.w),
                      _ActionButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Cancel schedule',
                        color: CustomColor.kDarkDangerColor,
                        bgColor: CustomColor.kLightDangerColor,
                        onTap: widget.onCancel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip2 extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip2({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? CustomColor.kPrimaryColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: chipColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: chipColor),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: color,
        fixedSize: Size(34.r, 34.r),
        minimumSize: Size(34.r, 34.r),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 18.r),
    );
  }
}
