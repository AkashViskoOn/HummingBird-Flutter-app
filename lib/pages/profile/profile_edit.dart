import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/app_textfield.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/profile/image_picker_bottom_sheet.dart';
import 'package:humming_bird/components/profile/pick_date_of_birth_field.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/profile_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/text_generation_service.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_shadow.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final ProfileController profileController = Get.find();
  final UserController userController = Get.find();
  final BirdController birdController = Get.find();
  bool _generatingBio = false;

  @override
  void initState() {
    super.initState();
    final user = userController.user;
    profileController.firstNameController.text = user?.userFirstName ?? '';
    profileController.lastNameController.text = user?.userLastName ?? '';
    profileController.bioController.text = user?.userBio ?? '';
    profileController.emailController.text = user?.userEmail ?? '';
    profileController.dobController.text =
        AppHelper.formatDobForDisplay(user?.userDob);
    profileController.profilePic = null;
    profileController.profilePicPath.value = '';
    profileController.removeImage = '';
  }

  void _clearDraftState() {
    birdController.showLoading.value = false;
    profileController.profilePic = null;
    profileController.profilePicPath.value = '';
    profileController.removeImage = '';
  }

  void _onSaveChanges() {
    final email = profileController.emailController.text.trim();
    if (email.isNotEmpty) {
      final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
      if (!valid) {
        Utils.showGetSnackBar('Please enter a valid email address');
        return;
      }
    }
    profileController.updateProfile();
  }

  Future<void> _generateBio() async {
    if (_generatingBio) return;
    setState(() => _generatingBio = true);
    final name = profileController.firstNameController.text.trim();
    final text = await TextGeneration().getGeneratedText(
      'Write a short, friendly profile bio (max 80 words)'
      '${name.isNotEmpty ? ' for someone named $name' : ''}'
      ' for a messaging app. Return only the bio text.',
    );
    if (!mounted) return;
    setState(() => _generatingBio = false);
    if (text == null || text.trim().isEmpty) {
      Utils.showGetSnackBar('Could not generate a bio right now. Try again.');
      return;
    }
    profileController.bioController.text = text.trim();
  }

  void _openImagePicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: CustomColor.kWhite,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl.r)),
      ),
      builder: (context) => const ImagePickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) => _clearDraftState(),
      child: Scaffold(

        appBar: CommonAppBar(title: 'Edit Profile'),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.xxl.w, AppSpacing.xl.h,
                    AppSpacing.xxl.w, AppSpacing.xsection.h)
                .copyWith(
                    bottom: AppSpacing.xsection.h +
                        MediaQuery.of(context).viewInsets.bottom),
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxxl.w - 2.w,
                    AppSpacing.xxxl.h,
                    AppSpacing.xxxl.w - 2.w,
                    AppSpacing.xxxl.h + 2.h),
                decoration: BoxDecoration(
                  color: CustomColor.kDarkSurface,
                  borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GetBuilder<ProfileController>(
                          id: 'update-profile',
                          builder: (_) => Container(
                            padding: EdgeInsets.all(3.r),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: CustomColor.primaryGradient,
                            ),
                            child: CircleAvatar(
                              radius: 58.r,
                              backgroundColor: CustomColor.kWhite,
                              backgroundImage:
                                  profileController.getProfilePic(),
                              onBackgroundImageError: (_, __) {},
                            ),
                          ),
                        ),
                        Material(
                          color: CustomColor.kGoldAccent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _openImagePicker,
                            child: SizedBox(
                              width: 42.r,
                              height: 42.r,
                              child: Icon(
                                Icons.photo_camera_rounded,
                                color: CustomColor.kDarkSurface,
                                size: 21.r,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xxl.h - 2.h),
                    Text(
                      'Let your profile speak for you',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingSm
                          .copyWith(color: CustomColor.kWhite),
                    ),
                    SizedBox(height: AppSpacing.xs.h),
                    Text(
                      userController.user?.userMobileNum ?? '',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle.copyWith(
                          color: CustomColor.kWhite.withValues(alpha: 0.68)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl.h),
              _FormSection(
                children: [
                  const _FieldLabel('First name'),
                  AppTextField(
                    controller: profileController.firstNameController,
                    hintText: 'First name',
                    textCapitalization: TextCapitalization.sentences,
                    prefixIcon: Icon(
                      Icons.person_rounded,
                      size: AppIcons.xl.r,
                      color: CustomColor.kDarkPrimaryColor,
                    ),
                  ),
                  const _FieldGap(),
                  const _FieldLabel('Last name'),
                  AppTextField(
                    controller: profileController.lastNameController,
                    hintText: 'Last name',
                    textCapitalization: TextCapitalization.sentences,
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      size: AppIcons.xl.r,
                      color: CustomColor.kDarkPrimaryColor,
                    ),
                  ),
                  const _FieldGap(),
                  const _FieldLabel('Bio'),
                  AppTextField(
                    controller: profileController.bioController,
                    hintText: 'Bio',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      size: AppIcons.xl.r + 1,
                      color: CustomColor.kDarkPrimaryColor,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _generatingBio ? null : _generateBio,
                      icon: _generatingBio
                          ? SizedBox(
                              width: 14.r,
                              height: 14.r,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: CustomColor.kPrimaryColor),
                            )
                          : Icon(
                              Icons.auto_awesome_rounded,
                              size: 16.r,
                              color: CustomColor.kPrimaryColor,
                            ),
                      label: Text(
                        _generatingBio
                            ? 'Generating...'
                            : 'Generate Bio with AI',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: CustomColor.kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  const _FieldGap(),
                  const _FieldLabel('Email'),
                  AppTextField(
                    controller: profileController.emailController,
                    hintText: 'Email',
                    prefixIcon: Icon(
                      Icons.mail_rounded,
                      size: AppIcons.xl.r,
                      color: CustomColor.kDarkPrimaryColor,
                    ),
                  ),
                  const _FieldGap(),
                  const _FieldLabel('Date of birth'),
                  PickDateOfBirthField(
                    controller: profileController.dobController,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxxl.h - 2.h),
              AppButton(
                text: 'Save Changes',
                onTap: _onSaveChanges,
                backgroundColor: CustomColor.kPrimaryFill,
                borderRadius: AppRadius.xxl.r,
                fontSize: 15.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final List<Widget> children;

  const _FormSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xxl.r - 1),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r - 2),
        border: Border.all(color: CustomColor.kLightBorder),
        boxShadow: AppShadow.elevatedLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: AppSpacing.xs.w, bottom: AppSpacing.md.h),
      child: Text(
        text,
        style: AppTextStyles.bodySm.copyWith(
            color: CustomColor.kTextSecondary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FieldGap extends StatelessWidget {
  const _FieldGap();

  @override
  Widget build(BuildContext context) => SizedBox(height: 14.h);
}
