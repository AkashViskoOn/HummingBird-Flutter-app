import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/humming_page_ui.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/pages/setting/account/term_and_condition.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/authentication_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_dimensions.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthenticationController authenticationController =
        Get.put(AuthenticationController());

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
                duration: AppAnimation.extraSlow,
                curve: AppAnimation.decelerate,
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Text(
                  'Welcome back',
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
                  'Enter your mobile number to receive a verification code',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: CustomColor.kTextSecondary),
                ),
              ),
              SizedBox(height: AppSpacing.xpage.h),

              // Phone field label
              Text(
                'Phone Number',
                style: AppTextStyles.label,
              ),
              SizedBox(height: AppSpacing.md.h),

              // Phone input
              IntlPhoneField(
                controller: authenticationController.phoneNumberController,
                style: AppTextStyles.titleMd
                    .copyWith(color: CustomColor.kTextPrimary),
                autovalidateMode: AutovalidateMode.disabled,
                dropdownTextStyle: AppTextStyles.titleMd
                    .copyWith(color: CustomColor.kTextPrimary),
                decoration: InputDecoration(
                  hintText: '000 000 0000',
                  counterText: '',
                  hintStyle: AppTextStyles.titleMd
                      .copyWith(color: CustomColor.kTextTertiary),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl.w, vertical: AppSpacing.xxl.h),
                  filled: true,
                  fillColor: CustomColor.kUltraLightBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    borderSide: BorderSide(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
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
                initialCountryCode: 'IN',
              ),

              SizedBox(height: AppSpacing.page.h),

              // CTA Button
              Obx(() => authenticationController.showLoading.value
                  ? const Center(child: CustomLoading())
                  : _PremiumButton(
                      label: 'Send Verification Code',
                      onTap: authenticationController.submitLogin,
                    )),

              SizedBox(height: AppSpacing.section.h),

              // Footer note
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(height: 1.6),
                    children: [
                      const TextSpan(text: 'By continuing you agree to our '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Semantics(
                          link: true,
                          child: GestureDetector(
                            onTap: () =>
                                Get.to(() => const TermsConditionPage()),
                            child: Text(
                              'Terms of Service',
                              style: AppTextStyles.caption.copyWith(
                                color: CustomColor.kPrimaryText,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '\nand Privacy Policy.'),
                    ],
                  ),
                ),
              ),
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
