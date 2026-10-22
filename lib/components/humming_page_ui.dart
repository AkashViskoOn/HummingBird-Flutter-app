import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class HummingPageUi extends StatelessWidget {
  final Widget child;
  const HummingPageUi({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kDarkSurface,
      body: Stack(
        children: [
          // Rich gradient background with brand blue undertones
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 0.75, 1.0],
                colors: [
                  CustomColor.kDarkSurface,
                  CustomColor.kInk800,
                  CustomColor.kDarkSurface,
                  CustomColor.kInk900,
                ],
              ),
            ),
          ),

          // Decorative orbs for depth — brand blue glows
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300.r,
              height: 300.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120.h,
            left: -100,
            child: Container(
              width: 320.r,
              height: 320.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CustomColor.kPrimaryMedium.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200.h,
            left: -40,
            child: Container(
              width: 180.r,
              height: 180.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CustomColor.kPrimaryDark.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Logo section
                SizedBox(height: 40.h),
                const _LogoBrand(),
                SizedBox(height: 28.h),

                // Content card — glassmorphic
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CustomColor.kWhite.withValues(alpha: 0.98),
                          CustomColor.kUltraLightPrimary
                              .withValues(alpha: 0.96),
                          CustomColor.kWhite.withValues(alpha: 0.98),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              CustomColor.kPrimaryColor.withValues(alpha: 0.18),
                          blurRadius: 50,
                          offset: const Offset(0, -10),
                        ),
                        BoxShadow(
                          color: CustomColor.kBlack.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(36.r)),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBrand extends StatelessWidget {
  const _LogoBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo mark — with glow
        Container(
          width: 80.r,
          height: 80.r,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CustomColor.kPrimaryColor, CustomColor.kPrimaryMedium],
            ),
            borderRadius: BorderRadius.circular(AppRadius.rounded.r),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                blurRadius: 60,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: const Icon(
            Icons.spatial_audio_off_rounded,
            color: CustomColor.kTextOnDark,
            size: AppIcons.huge,
          ),
        ),
        SizedBox(height: AppSpacing.xxl.h),
        Text(
          'Humming Bird',
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 26.sp,
            color: CustomColor.kWhite,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Text(
          'Fast · Calm · Encrypted',
          style: AppTextStyles.subtitle.copyWith(
            color: CustomColor.kWhite.withValues(alpha: 0.5),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
