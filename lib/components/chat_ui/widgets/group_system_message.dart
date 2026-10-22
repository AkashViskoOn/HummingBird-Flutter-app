import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/group_system_message_service.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Centered WhatsApp-style system message pill ("You created this group",
/// "You changed the group name to …", member added/removed/admin events).
///
/// Rendered from the `m_message_type == '7'` payload — the formatted string is
/// derived by [GroupSystemMessageService.format], never from raw text.
class GroupSystemMessage extends StatelessWidget {
  final Messages message;

  const GroupSystemMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = GroupSystemMessageService.preview(message).trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.w, vertical: 2.h),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 275.w),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl.w,
            vertical: AppSpacing.md.h,
          ),
          decoration: BoxDecoration(
            color: dark
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.14)
                : CustomColor.kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: dark
                  ? CustomColor.kTextOnDarkMuted
                  : CustomColor.kTextSecondary,
              fontSize: 12.sp,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
