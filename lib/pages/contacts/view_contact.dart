import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/all_contacts_model.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/utilities/custom_icon_button.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ViewContact extends StatelessWidget {
  final Contacts newContact;
  const ViewContact({super.key, required this.newContact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kUltraLightPrimary,
      appBar: CommonAppBar(
          title: '${newContact.cFirstName} ${newContact.cLastName}'),
      body: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl.w - 1, vertical: AppSpacing.xxxl.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                      CustomColor.kPrimaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                height: 200.h,
                child: SizedBox(
                  width: Get.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50.r,
                        backgroundColor:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                        child: Text(
                          "${newContact.cFirstName![0]}${newContact.cLastName?.isNotEmpty == true ? newContact.cLastName![0] : ''}",
                          style: AppTextStyles.displayMedium
                              .copyWith(color: CustomColor.kPrimaryColor),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl.h - 1),
                      Text(
                        "${newContact.cFirstName} ${newContact.cLastName}",
                        style: AppTextStyles.headingXl
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.page.h - 2.h),
              Container(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl.h),
                decoration: BoxDecoration(
                  color: CustomColor.kLightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomIconButton(
                      title: "Send Message",
                      icon: Icons.message,
                      color: CustomColor.kPrimaryLight,
                      iconColor: CustomColor.kPrimaryColor,
                    ),
                    CustomIconButton(
                      tooltip: 'Schedule message',
                      title: "Schedule Message",
                      icon: Icons.schedule,
                      color: CustomColor.kPrimaryLight,
                      iconColor: CustomColor.kPrimaryColor,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
