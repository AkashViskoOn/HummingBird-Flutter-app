import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/settings_controller.dart';
import 'package:pinput/pinput.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class CommonOTPScreen extends StatelessWidget {
  final String phoneNumber;
  final String otp;
  final String? newNumber;
  final bool forDelete;
  const CommonOTPScreen(
      {super.key,
      required this.phoneNumber,
      required this.otp,
      this.newNumber,
      required this.forDelete});

  @override
  Widget build(BuildContext context) {
    BirdController birdController = Get.find();
    AppSettingsController settingsController = Get.find();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        birdController.showLoading.value = false;
      },
      child: Scaffold(
        backgroundColor: CustomColor.kDarkSurface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Premium glass header with gradient
                Container(
                  margin: EdgeInsets.only(right: 10.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CustomColor.kDarkSurface,
                        CustomColor.kDarkSurface2,
                        CustomColor.kDarkSurfaceAlt,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(50.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(50.r),
                    ),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 20.h, bottom: 20.h, right: 15.w, left: 5.w),
                        child: Row(
                          children: [
                            const AppBackButton(color: CustomColor.kTextOnDark),
                            SizedBox(width: 12.w),
                            Text(
                              'Verify it\'s you',
                              style: AppTextStyles.headingLg
                                  .copyWith(color: CustomColor.kWhite),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Get.height * 0.12),

                // Premium icon
                Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CustomColor.kPrimaryColor,
                        CustomColor.kPrimaryMedium,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                    boxShadow: [
                      BoxShadow(
                        color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.smartphone_rounded,
                    color: CustomColor.kTextOnDark,
                    size: 36.sp,
                  ),
                ),
                SizedBox(height: 24.h),

                Text(
                  'OTP Verification',
                  style: AppTextStyles.headingXl
                      .copyWith(color: CustomColor.kTextPrimary),
                ),
                SizedBox(height: 10.h),
                FittedBox(
                  child: Text(
                    'Enter the OTP sent to your number',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: CustomColor.kTextSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  ),
                  child: Text(
                    phoneNumber,
                    style: AppTextStyles.headingSm
                        .copyWith(color: CustomColor.kPrimaryColor),
                  ),
                ),

                SizedBox(height: 36.h),

                // Premium OTP inputs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Pinput(
                    controller: settingsController.deleteOtpController,
                    onCompleted: (otp) {},
                    length: 4,
                    keyboardType: TextInputType.number,
                    defaultPinTheme: PinTheme(
                      width: 60.r,
                      height: 60.r,
                      textStyle: AppTextStyles.headingXl
                          .copyWith(color: CustomColor.kTextPrimary),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CustomColor.kUltraLightPrimary,
                            CustomColor.kWhite,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                        border: Border.all(
                          color:
                              CustomColor.kPrimaryColor.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 60.r,
                      height: 60.r,
                      textStyle: AppTextStyles.headingXl
                          .copyWith(color: CustomColor.kPrimaryColor),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            CustomColor.kUltraLightPrimary,
                            CustomColor.kPrimaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                        border: Border.all(
                          color: CustomColor.kPrimaryColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CustomColor.kPrimaryColor
                                .withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ),

                SizedBox(height: Get.height * 0.08),

                // Premium button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: _PremiumCommonButton(
                    label: 'Verify OTP',
                    onTap: () {
                      forDelete
                          ? settingsController.deleteAccount()
                          : settingsController.changeNumber(
                              newNumber ?? '',
                              settingsController.deleteOtpController.text,
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCommonButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PremiumCommonButton({required this.label, required this.onTap});

  @override
  State<_PremiumCommonButton> createState() => _PremiumCommonButtonState();
}

class _PremiumCommonButtonState extends State<_PremiumCommonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
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
    widget.onTap();
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
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CustomColor.kPrimaryColor, CustomColor.kPrimaryMedium],
            ),
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
            style: AppTextStyles.titleMd
                .copyWith(color: CustomColor.kTextOnDark, letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }
}
