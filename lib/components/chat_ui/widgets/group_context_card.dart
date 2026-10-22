import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/groups/add_member_bottom_sheet.dart';
import 'package:humming_bird/components/groups/group_name_dialog.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// WhatsApp-style group context card — shown above an empty group thread
/// ("Create your group" / "Name this group" / set icon / add members).
///
/// Only displays actions the backend actually supports (name, icon, members);
/// description + invite links are backend gaps and deliberately omitted.
class GroupContextCard extends StatelessWidget {
  final String roomId;

  const GroupContextCard({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GetBuilder<GroupController>(
      builder: (controller) {
        final members = controller.groupData?.members ?? const [];
        return Padding(
          padding: EdgeInsets.fromLTRB(28.w, 16.h, 28.w, 8.h),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.xxxl.r),
            decoration: BoxDecoration(
              color: dark ? CustomColor.kDarkSurface : CustomColor.kWhite,
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
              boxShadow: dark
                  ? null
                  : [
                      BoxShadow(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 32.r,
                  backgroundColor:
                      CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.groups_rounded,
                    size: 30.r,
                    color: CustomColor.kPrimaryColor,
                  ),
                ),
                SizedBox(height: AppSpacing.lg.h),
                Text(
                  'Create your group',
                  style: AppTextStyles.headingSm,
                ),
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  members.isEmpty
                      ? 'You can name this group and add members to start chatting.'
                      : 'Add a name, photo and more members to make this group yours.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kTextSecondary),
                ),
                SizedBox(height: AppSpacing.xl.h),
                Wrap(
                  spacing: AppSpacing.lg.w,
                  runSpacing: AppSpacing.lg.h,
                  alignment: WrapAlignment.center,
                  children: [
                    _ContextAction(
                      icon: Icons.edit_outlined,
                      label: 'Name this group',
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => GroupNameDialog(roomId: roomId),
                      ),
                    ),
                    _ContextAction(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Group icon',
                      onTap: () => controller.pickGroupImage(
                          ImageSource.gallery, roomId),
                    ),
                    _ContextAction(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Add members',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        useSafeArea: true,
                        builder: (_) => AddMemberBottomSheet(roomId: roomId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.w, vertical: AppSpacing.sm.h),
          decoration: BoxDecoration(
            color: dark
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.14)
                : CustomColor.kPrimaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.r, color: CustomColor.kPrimaryColor),
              SizedBox(width: 6.w),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: CustomColor.kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
