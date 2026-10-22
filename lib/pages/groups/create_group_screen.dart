import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/common/common_textfield.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_animation.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.find();

    return Scaffold(
      backgroundColor: CustomColor.kUltraLightPrimary,
      appBar: const CommonAppBar(
        title: 'Create New Group',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl.w - 1,
          AppSpacing.xxxl.h,
          AppSpacing.xxl.w - 1,
          AppSpacing.xxxl.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xxxl.r),
              decoration: BoxDecoration(
                color: CustomColor.kLightSurface,
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                boxShadow: AppShadow.cardLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.xxs.w + 1,
                        height: AppSpacing.xxxl.h - 2,
                        decoration: BoxDecoration(
                          gradient: CustomColor.primaryGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.xxs.r),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md.w),
                      Text(
                        'Group Name',
                        style: AppTextStyles.headingSm,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  CommonTextField(
                    hintText: 'Group Name (optional)',
                    controller: contactController.groupNameController,
                    bgColor: CustomColor.kUltraLightPrimary,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.section.h),
            Container(
              padding: EdgeInsets.all(AppSpacing.xxxl.r),
              decoration: BoxDecoration(
                color: CustomColor.kLightSurface,
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                boxShadow: AppShadow.cardLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppSpacing.xxs.w + 1,
                        height: AppSpacing.xxxl.h - 2,
                        decoration: BoxDecoration(
                          gradient: CustomColor.primaryGradient,
                          borderRadius: BorderRadius.circular(AppSpacing.xxs.r),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md.w),
                      Text(
                        'Add Participants',
                        style: AppTextStyles.headingSm,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  CommonTextField(
                    onChanged: (value) {
                      contactController.searchContacts(value);
                    },
                    bgColor: CustomColor.kUltraLightPrimary,
                    hintText: 'Search Contacts',
                    suffixIcon: Icon(
                      Icons.search,
                      size: AppIcons.xxl.r,
                      color: CustomColor.kPrimaryColor,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl.h),
                  Obx(() {
                    if (contactController.isFetchingContacts.value) {
                      return const CustomLoading();
                    } else if (contactController.hummingContacts.isEmpty &&
                        contactController.allContacts.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'No saved contacts',
                        message: 'Contacts saved to the app appear here',
                        layout: EmptyStateLayout.inline,
                      );
                    } else {
                      return GetBuilder<ContactController>(
                        id: 'update-contacts-search',
                        builder: (_) => ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: contactController.hummingContacts.length,
                          itemBuilder: (context, index) {
                            User user =
                                contactController.hummingContacts[index];
                            return Entrance(
                              delayFactor: (index % 8) * 0.05,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs.h),
                                child: Obx(
                                  () {
                                    final isSelected = contactController
                                        .groupParticipants
                                        .contains(user);
                                    return AnimatedContainer(
                                      duration: AppAnimation.cardHover,
                                      curve: AppAnimation.easeInOut,
                                      decoration: BoxDecoration(
                                        color: CustomColor.kLightSurface,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.xl.r),
                                        border: Border.all(
                                          color: isSelected
                                              ? CustomColor.kPrimaryColor
                                                  .withValues(alpha: 0.3)
                                              : Colors.transparent,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? CustomColor.kPrimaryColor
                                                    .withValues(alpha: 0.06)
                                                : Colors.black
                                                    .withValues(alpha: 0.03),
                                            blurRadius: isSelected ? 8 : 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        onTap: () {
                                          contactController.groupParticipants
                                                  .contains(user)
                                              ? contactController
                                                  .groupParticipants
                                                  .remove(user)
                                              : contactController
                                                  .groupParticipants
                                                  .add(user);
                                        },
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xl.w),
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.xl.r),
                                        ),
                                        leading: CircleAvatar(
                                          radius: AppSpacing.section + 1,
                                          backgroundImage: user
                                                  .userImage!.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  '${Endpoints.mediaBaseUrl}${user.userImage!}')
                                              : const AssetImage(AppAssets
                                                      .defaultProfilePic)
                                                  as ImageProvider,
                                          onBackgroundImageError: (_, __) {},
                                        ),
                                        title: Text(
                                          contactController
                                              .getAllContactsName(user),
                                          style: AppTextStyles.titleSm,
                                        ),
                                        subtitle: Text(
                                          '${user.userMobileNum}',
                                          style: AppTextStyles.bodySm.copyWith(
                                              color:
                                                  CustomColor.kTextSecondary),
                                        ),
                                        trailing: isSelected
                                            ? Container(
                                                padding: EdgeInsets.all(
                                                    AppSpacing.xs.r),
                                                decoration: BoxDecoration(
                                                  gradient: CustomColor
                                                      .primaryGradient,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color:
                                                      CustomColor.kTextOnDark,
                                                  size: AppIcons.md.r,
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CustomColor.kPrimaryFill,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl.r)),
        elevation: 4,
        focusElevation: 8,
        hoverElevation: 8,
        onPressed: () {
          if (contactController.groupParticipants.isEmpty) {
            Utils.showGetSnackBar('Select at least one contact');
            return;
          }
          contactController.createGroup();
        },
        child: Icon(
          Icons.check,
          size: AppIcons.xxxl.r,
          color: CustomColor.kTextOnDark,
        ),
      ),
    );
  }
}
