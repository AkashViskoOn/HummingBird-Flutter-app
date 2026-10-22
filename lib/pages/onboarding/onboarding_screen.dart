import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/Onboarding_Data/data.dart';
import 'package:humming_bird/pages/login_screen/login.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_dimensions.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  static const List<_OnboardingMeta> _meta = [
    _OnboardingMeta(
      iconData: Icons.schedule_send_rounded,
      accentColor: CustomColor.kPrimaryColor,
      accentTextColor: CustomColor.kOnPrimaryTint,
      tag: 'SCHEDULING',
    ),
    _OnboardingMeta(
      iconData: Icons.lock_outline_rounded,
      accentColor: CustomColor.kPrimaryMedium,
      accentTextColor: CustomColor.kOnPrimaryTint,
      tag: 'PRIVACY',
    ),
    _OnboardingMeta(
      iconData: Icons.groups_rounded,
      accentColor: CustomColor.kPrimaryDark,
      accentTextColor: CustomColor.kOnPrimaryTint,
      tag: 'COLLABORATION',
    ),
    _OnboardingMeta(
      iconData: Icons.support_agent_rounded,
      accentColor: CustomColor.kBrandSecondary,
      accentTextColor: CustomColor.kOnPrimaryTint,
      tag: 'SUPPORT',
    ),
  ];

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentIndex < contentsList.length - 1) {
      _controller.nextPage(
        duration: AppAnimation.extraSlow,
        curve: AppAnimation.easeInOut,
      );
    } else {
      Get.off(() => const LoginScreen(), transition: Transition.fadeIn);
    }
  }

  void _skip() {
    Get.off(() => const LoginScreen(), transition: Transition.fadeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kDarkSurface,
      body: Stack(
        children: [
          // Animated background orb
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedSwitcher(
              duration: AppAnimation.extraSlow,
              child: _BackgroundOrb(
                key: ValueKey(_currentIndex),
                color: _meta[_currentIndex].accentColor,
              ),
            ),
          ),

          SafeArea(
            minimum: EdgeInsets.only(top: AppSpacing.sm.h),
            child: Column(
              children: [
                // Top bar with skip
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.section.w,
                    vertical: AppSpacing.xxl.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo chip
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl.w,
                            vertical: AppSpacing.sm.h),
                        decoration: BoxDecoration(
                          color: CustomColor.kTextOnDark.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.spatial_audio_off_rounded,
                                color: CustomColor.kTextOnDark,
                                size: AppIcons.sm.r),
                            SizedBox(width: AppSpacing.sm.w),
                            Text(
                              'Humming Bird',
                              style: AppTextStyles.label
                                  .copyWith(color: CustomColor.kTextOnDark),
                            ),
                          ],
                        ),
                      ),

                      // Skip button
                      GestureDetector(
                        onTap: _skip,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(AppSpacing.xl.w,
                              AppSpacing.sm.h, AppSpacing.xl.w, 7.h),
                          decoration: BoxDecoration(
                            color: CustomColor.kOverlay12,
                            borderRadius:
                                BorderRadius.circular(AppRadius.xxxl.r),
                          ),
                          child: Text(
                            'Skip',
                            style: AppTextStyles.label.copyWith(
                                color: CustomColor.kTextOnDark
                                    .withValues(alpha: 0.85)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Illustration — with animated transitions
                Expanded(
                  flex: 5,
                  child: AnimatedSwitcher(
                    duration: AppAnimation.slow,
                    switchInCurve: AppAnimation.easeInOut,
                    switchOutCurve: AppAnimation.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(
                                parent: animation, curve: AppAnimation.easeOut),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: PageView.builder(
                      key: ValueKey(_currentIndex),
                      controller: _controller,
                      itemCount: contentsList.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (_, index) {
                        return _IllustrationPage(
                          content: contentsList[index],
                          meta: _meta[index],
                        );
                      },
                    ),
                  ),
                ),

                // Bottom content card
                _BottomCard(
                  index: _currentIndex,
                  controller: _controller,
                  meta: _meta[_currentIndex],
                  content: contentsList[_currentIndex],
                  onNext: _next,
                  total: contentsList.length,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  final Color color;
  const _BackgroundOrb({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360.r,
      height: 360.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.22),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _IllustrationPage extends StatelessWidget {
  final UnbordingContent content;
  final _OnboardingMeta meta;
  const _IllustrationPage({required this.content, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.page.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.r,
            height: 100.r,
            decoration: BoxDecoration(
              color: meta.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.rounded.r),
              border: Border.all(
                color: meta.accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(meta.iconData,
                color: meta.accentColor, size: AppIcons.huge.r),
          ),
          SizedBox(height: AppSpacing.page.h),
          SvgPicture.asset(
            content.image,
            height: 240.h,
          ),
        ],
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  final int index;
  final int total;
  final PageController controller;
  final _OnboardingMeta meta;
  final UnbordingContent content;
  final VoidCallback onNext;

  const _BottomCard({
    required this.index,
    required this.total,
    required this.controller,
    required this.meta,
    required this.content,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.medium,
      curve: AppAnimation.easeInOut,
      width: double.infinity,
      margin: EdgeInsets.only(top: AppSpacing.xl.h),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.section.w,
        AppSpacing.page.h,
        AppSpacing.section.w,
        AppSpacing.page.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomColor.kWhite.withValues(alpha: 0.97),
            CustomColor.kUltraLightPrimary.withValues(alpha: 0.95),
            CustomColor.kWhite.withValues(alpha: 0.97),
          ],
        ),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
        boxShadow: [
          BoxShadow(
            color: meta.accentColor.withValues(alpha: 0.18),
            blurRadius: 50,
            offset: const Offset(0, -10),
          ),
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tag chip
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg.w, vertical: AppSpacing.xs.h),
            decoration: BoxDecoration(
              color: meta.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md.r),
              border: Border.all(
                color: meta.accentColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              meta.tag,
              style: AppTextStyles.chatBadge.copyWith(
                color: meta.accentTextColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xxl.h),

          AnimatedSwitcher(
            duration: AppAnimation.slow,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              key: ValueKey('title_$index'),
              content.title,
              style: AppTextStyles.headingXl.copyWith(
                height: 1.25,
                letterSpacing: -0.4,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg.h),
          AnimatedSwitcher(
            duration: AppAnimation.slow,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              key: ValueKey('sub_$index'),
              content.subtitle,
              style: AppTextStyles.bodyMd.copyWith(
                color: CustomColor.kTextSecondary,
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xsection.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SmoothPageIndicator(
                controller: controller,
                count: total,
                effect: ExpandingDotsEffect(
                  dotHeight: AppSpacing.md,
                  dotWidth: AppSpacing.md,
                  expansionFactor: 3.0,
                  spacing: AppSpacing.sm,
                  activeDotColor: meta.accentColor,
                  dotColor: meta.accentColor.withValues(alpha: 0.2),
                ),
              ),

              // Next / Get Started button — with scale animation
              _AnimatedNextButton(
                index: index,
                total: total,
                accentColor: meta.accentColor,
                onNext: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedNextButton extends StatefulWidget {
  final int index;
  final int total;
  final Color accentColor;
  final VoidCallback onNext;

  const _AnimatedNextButton({
    required this.index,
    required this.total,
    required this.accentColor,
    required this.onNext,
  });

  @override
  State<_AnimatedNextButton> createState() => _AnimatedNextButtonState();
}

class _AnimatedNextButtonState extends State<_AnimatedNextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppAnimation.medium,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
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
    widget.onNext();
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
          duration: AppAnimation.medium,
          width: AppDimensions.avatarXl,
          height: AppDimensions.avatarXl,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accentColor,
                widget.accentColor.withValues(alpha: 0.75),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.accentColor
                    .withValues(alpha: _isPressed ? 0.6 : 0.4),
                blurRadius: _isPressed ? 24 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.index == widget.total - 1
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            color: CustomColor.kTextOnDark,
            size: AppIcons.xxl.r,
          ),
        ),
      ),
    );
  }
}

class _OnboardingMeta {
  final IconData iconData;
  final Color accentColor;

  /// Text-safe counterpart of [accentColor].
  ///
  /// The tag chip paints the label in [accentColor] over a 10% tint of the
  /// same colour sitting on a near-white card. That composite lands around
  /// 2.5:1 for the bright accents, so the label needs its own darker value
  /// rather than the identity colour.
  final Color accentTextColor;
  final String tag;
  const _OnboardingMeta({
    required this.iconData,
    required this.accentColor,
    required this.accentTextColor,
    required this.tag,
  });
}
