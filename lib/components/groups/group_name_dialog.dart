import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';

class GroupNameDialog extends StatefulWidget {
  final String roomId;

  const GroupNameDialog({super.key, required this.roomId});

  @override
  State<GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<GroupNameDialog> {
  late final GroupController groupController;
  late final String originalName;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    groupController = Get.find();
    originalName = groupController.getUpdatedGroup(widget.roomId).rName ?? '';
    groupController.groupNameController.text = originalName;
  }

  void _cancel() {
    groupController.groupNameController.text = originalName;
    Get.back();
  }

  Future<void> _save() async {
    final name = groupController.groupNameController.text.trim();
    if (name.isEmpty) {
      Utils.showGetSnackBar('Enter Group Name');
      return;
    }

    final success = await groupController.updateGroup(
      widget.roomId,
      showLoading: false,
    );
    if (success) {
      _saved = true;
      Get.back();
    }
  }

  @override
  void dispose() {
    if (!_saved) {
      groupController.groupNameController.text = originalName;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width * 0.82,
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: CustomColor.kTextOnDark,
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40.r,
                  width: 40.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 20.r,
                    color: CustomColor.kPrimaryColor,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Edit Group Name',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: CustomColor.kTextPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: groupController.groupNameController,
              autofocus: true,
              maxLength: 50,
              style: TextStyle(
                fontSize: 16.sp,
                color: CustomColor.kTextPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Enter group name',
                hintStyle: TextStyle(
                  color: CustomColor.kTextTertiary,
                  fontSize: 16.sp,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  borderSide: BorderSide(
                    color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  borderSide: BorderSide(
                    color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  borderSide: BorderSide(
                    color: CustomColor.kPrimaryColor,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: CustomColor.kUltraLightBg,
              ),
            ),
            SizedBox(height: 24.h),
            Obx(
              () => groupController.showLoading.value
                  ? const CustomLoading()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Cancel',
                            onTap: _cancel,
                            buttonSize: Size(double.maxFinite, 45.h),
                            backgroundColor: CustomColor.kTextTertiary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: AppButton(
                            text: 'Save',
                            onTap: _save,
                            buttonSize: Size(double.maxFinite, 45.h),
                            backgroundColor: CustomColor.kPrimaryFill,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
