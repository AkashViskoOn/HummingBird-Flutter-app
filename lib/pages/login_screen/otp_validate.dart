import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/humming_page_ui.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/authentication_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_dimensions.dart';
import 'package:pinput/pinput.dart';

class OTPValidate extends StatefulWidget {
  const OTPValidate({super.key});

  @override
  State<OTPValidate> createState() => _OTPValidateState();
}

class _OTPValidateState extends State<OTPValidate>
    with SingleTickerProviderStateMixin {
  AuthenticationController authenticationController = Get.find();
  late AnimationController _timerPulseController;
  late Animation<double> _timerPulseAnim;

  @override
  void initState() {
    super.initState();
    _timerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _timerPulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
          parent: _timerPulseController, curve: AppAnimation.easeInOut),
    );
    _timerPulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timerPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 62.r,
      height: 62.r,
      textStyle:
          AppTextStyles.headingXl.copyWith(color: CustomColor.kTextPrimary),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomColor.kWhite,
            CustomColor.kUltraLightPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
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
        border: Border.all(color: CustomColor.kPrimaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomColor.kPrimaryLight,
            CustomColor.kUltraLightPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(color: CustomColor.kPrimaryColor),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    return Obx(() {
      if (authenticationController.isPageReady.isFalse) {
        return const Scaffold(
          backgroundColor: CustomColor.kDarkSurface,
          body: CustomLoading(),
        );
      }

      return HummingPageUi(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
                  AppSpacing.section.w,
                  AppSpacing.xsection.h,
                  AppSpacing.section.w,
                  AppSpacing.section.h)
              .copyWith(
                  bottom: AppSpacing.section.h +
                      MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppAnimation.normal,
                curve: AppAnimation.decelerate,
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Text(
                  'Verify your number',
                  style: AppTextStyles.displayLarge,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppAnimation.extraSlow,
                curve: AppAnimation.decelerate,
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Text(
                  'Enter the 4-digit code sent to your phone',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: CustomColor.kTextSecondary),
                ),
              ),
              SizedBox(height: AppSpacing.xpage.h),

              // OTP display for debugging
              Obx(() {
                if (authenticationController.otpCode.value.isNotEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xxl.h),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxxl.w,
                            vertical: AppSpacing.lg.h),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.xl.r),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Text(
                          'Your OTP is: ${authenticationController.otpCode.value}',
                          style: AppTextStyles.headingMd.copyWith(
                            color: Colors.amber.shade800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // OTP Pin Inputs
              Center(
                child: Pinput(
                  controller: authenticationController.otpController,
                  length: 4,
                  keyboardType: TextInputType.number,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  onSubmitted: (_) => authenticationController.validateOTP(),
                ),
              ),

              SizedBox(height: AppSpacing.xsection.h),

              // Timer + Resend row — animated
              Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 44.h,
                        child: Semantics(
                          button: true,
                          enabled: authenticationController.timer.value == 0,
                          label: 'Resend Code',
                          child: GestureDetector(
                            onTap: () {
                              if (authenticationController.timer.value == 0) {
                                authenticationController.submitLogin();
                              }
                            },
                            child: AnimatedDefaultTextStyle(
                              duration: AppAnimation.medium,
                              style: AppTextStyles.titleSm.copyWith(
                                color: authenticationController.timer.value == 0
                                    ? CustomColor.kPrimaryColor
                                    : CustomColor.kTextTertiary,
                              ),
                              child: const Text('Resend Code'),
                            ),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _timerPulseAnim,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: authenticationController.timer.value != 0
                                ? _timerPulseAnim.value
                                : 1.0,
                            child: child,
                          );
                        },
                        child: AnimatedContainer(
                          duration: AppAnimation.medium,
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl.w,
                              vertical: AppSpacing.md.h),
                          decoration: BoxDecoration(
                            gradient: authenticationController.timer.value != 0
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      CustomColor.kUltraLightPrimary,
                                      CustomColor.kPrimaryLight,
                                    ],
                                  )
                                : null,
                            color: authenticationController.timer.value == 0
                                ? CustomColor.kUltraLightBg
                                : null,
                            borderRadius: BorderRadius.circular(AppRadius.xl.r),
                            border: Border.all(
                              color: authenticationController.timer.value != 0
                                  ? CustomColor.kPrimaryColor
                                      .withValues(alpha: 0.15)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '00:${authenticationController.timer.value.toString().padLeft(2, '0')}',
                            style: AppTextStyles.titleMd.copyWith(
                              fontWeight: FontWeight.w700,
                              color: authenticationController.timer.value != 0
                                  ? CustomColor.kPrimaryDark
                                  : CustomColor.kTextTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),

              SizedBox(height: AppSpacing.xpage.h),

              // Validate button
              Obx(() => authenticationController.showLoading.value
                  ? const Center(child: CustomLoading())
                  : _PremiumButton(
                      label: 'Verify Code',
                      onTap: authenticationController.validateOTP,
                    )),
            ],
          ),
        ),
      );
    });
  }
}

class _PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PremiumButton({required this.label, required this.onTap});

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
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
