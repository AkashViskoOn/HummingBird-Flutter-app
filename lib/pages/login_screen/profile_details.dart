import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/humming_page_ui.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_dimensions.dart';
import 'package:humming_bird/components/profile/image_picker_bottom_sheet.dart';

class ProfileCreate extends StatelessWidget {
  const ProfileCreate({super.key});

  @override
  Widget build(BuildContext context) {
    UserController userController = Get.put(UserController());

    return HummingPageUi(child: Obx(() {
      if (userController.isLoggedIn.isTrue) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
                  AppSpacing.section.w,
                  AppSpacing.section.h,
                  AppSpacing.section.w,
                  AppSpacing.section.h)
              .copyWith(
                  bottom: AppSpacing.section.h +
                      MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: AppSpacing.xxl.h),

              // Premium profile picture picker with animated ring
              _PremiumAvatar(userController: userController),

              SizedBox(height: AppSpacing.page.h),

              // Glass text fields
              _GlassTextField(
                controller: userController.firstNameController,
                label: 'First Name',
              ),
              SizedBox(height: AppSpacing.xl.h),
              _GlassTextField(
                controller: userController.lastNameController,
                label: 'Last Name',
              ),
              SizedBox(height: AppSpacing.xl.h),
              _GlassTextField(
                controller: userController.emailController,
                label: 'Email Id',
              ),

              SizedBox(height: AppSpacing.xsection.h),

              // Premium submit button
              userController.isUpdatingUser.isFalse
                  ? _PremiumProfileButton(
                      onTap: userController.updateProfile,
                      label: 'Create Profile',
                    )
                  : Container(
                      height: AppDimensions.buttonHeightXl.h,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: AppSpacing.section,
                        height: AppSpacing.section,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: CustomColor.kPrimaryColor,
                        ),
                      ),
                    ),
              SizedBox(height: AppSpacing.section.h),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.section.w),
        child: Center(
          child: Text(
            'Authorization Failed',
            style: AppTextStyles.headingSm
                .copyWith(color: CustomColor.kTextSecondary),
          ),
        ),
      );
    }));
  }
}

class _PremiumAvatar extends StatelessWidget {
  final UserController userController;

  const _PremiumAvatar({required this.userController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated ring
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppAnimation.extraSlow,
          curve: AppAnimation.decelerate,
          builder: (context, value, child) {
            return Container(
              width: 120.r,
              height: 120.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    CustomColor.kPrimaryColor,
                    CustomColor.kPrimaryMedium,
                    CustomColor.kPrimaryDark,
                    CustomColor.kPrimaryColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor
                        .withValues(alpha: 0.3 * value),
                    blurRadius: 24 * value,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              padding: EdgeInsets.all(AppSpacing.xxs.r),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CustomColor.kDarkSurface,
                ),
                child: CircleAvatar(
                  radius: 54.r,
                  backgroundColor: CustomColor.kDarkSurface2,
                  backgroundImage: userController.croppedFile.value!.path != ''
                      ? Image.file(File(userController.croppedFile.value!.path))
                          .image
                      : Image.asset('assets/images/user1.jpg').image,
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            );
          },
        ),

        // Camera button
        Positioned(
          bottom: 2.h,
          right: 2.w,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                showDragHandle: true,
                backgroundColor: CustomColor.kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xxxl.r)),
                ),
                builder: (sheetContext) => SafeArea(
                  child: ImagePickerBottomSheet(
                    onPickImage: (source) =>
                        userController.selectProfilePhoto(source: source),
                  ),
                ),
              );
            },
            child: Container(
              height: AppDimensions.inputHeightSm,
              width: AppDimensions.inputHeightSm,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CustomColor.kPrimaryColor,
                    CustomColor.kPrimaryMedium
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_a_photo,
                color: CustomColor.kTextOnDark,
                size: 16.r,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _GlassTextField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: AppShadow.cardLight,
      ),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.titleMd.copyWith(color: CustomColor.kTextPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextTertiary),
          floatingLabelStyle:
              AppTextStyles.titleSm.copyWith(color: CustomColor.kPrimaryColor),
          contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl.w, vertical: AppSpacing.xxxl.h)
              .copyWith(top: 18.h, bottom: 18.h),
          filled: true,
          fillColor: CustomColor.kUltraLightBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            borderSide: BorderSide(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            borderSide: const BorderSide(
              color: CustomColor.kPrimaryColor,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumProfileButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _PremiumProfileButton({
    required this.onTap,
    required this.label,
  });

  @override
  State<_PremiumProfileButton> createState() => _PremiumProfileButtonState();
}

class _PremiumProfileButtonState extends State<_PremiumProfileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppAnimation.snackbar,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: AppAnimation.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: AppAnimation.medium,
          width: double.infinity,
          height: AppDimensions.buttonHeightXl.h,
          decoration: BoxDecoration(
            gradient: CustomColor.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor
                    .withValues(alpha: _isPressed ? 0.55 : 0.38),
                blurRadius: _isPressed ? 28 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTextStyles.button
                .copyWith(fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
