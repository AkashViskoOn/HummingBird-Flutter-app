import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Central, runtime-editable config for the app init skeleton duration.
///
/// The default [defaultMs] is a single constant that is easy to find in code;
/// Settings can override it through [setDurationMs], which persists the value
/// in GetStorage so every future skeleton honour's the user's choice.
class AppSkeletonConfig {
  AppSkeletonConfig._();

  static const String storageKey = 'app_skeleton_duration_ms';
  static const int defaultMs = 1600;
  static const int minMs = 400;
  static const int maxMs = 4000;

  static int get durationMs {
    try {
      final stored = GetStorage().read<int?>(storageKey);
      if (stored != null && stored >= minMs && stored <= maxMs) return stored;
    } catch (_) {}
    return defaultMs;
  }

  static Duration get duration => Duration(milliseconds: durationMs);

  static Future<void> setDurationMs(int ms) async {
    final clamped = ms.clamp(minMs, maxMs);
    try {
      await GetStorage().write(storageKey, clamped);
    } catch (_) {}
  }
}

/// A static skeleton "block". Individual blocks do not animate; wrap the whole
/// skeleton (list, screen, card, ...) in a single [AppSkeletonPulse] so one
/// timer drives the fade for every block inside.
class AppSkeletonBlock extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  const AppSkeletonBlock({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: circle ? height ?? width : width,
      height: height,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius.r),
        color: dark ? CustomColor.kDarkSurface3 : CustomColor.kLightBorder,
      ),
    );
  }
}

/// Single animation driver for a whole skeleton — repeat-reverse fade in the
/// same rhythm as the existing brand status skeleton.
class AppSkeletonPulse extends StatefulWidget {
  final Widget child;
  final Duration? pulseDuration;

  const AppSkeletonPulse({super.key, required this.child, this.pulseDuration});

  @override
  State<AppSkeletonPulse> createState() => _AppSkeletonPulseState();
}

class _AppSkeletonPulseState extends State<AppSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.pulseDuration ?? AppAnimation.shimmer,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
      child: widget.child,
    );
  }
}

/// Branded skeleton layouts reused by every "initial loading" state in the
/// app so the loading UI is identical everywhere.
class AppSkeletonPresets {
  AppSkeletonPresets._();

  static Widget _line(double width, double height) =>
      AppSkeletonBlock(width: width, height: height);

  /// A single chat/contact row: avatar + two lines.
  static Widget listRow({
    double avatarSize = 46,
    double firstWidth = 140,
    double secondWidth = 90,
  }) {
    return Row(
      children: [
        AppSkeletonBlock(width: avatarSize, height: avatarSize, circle: true),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line(firstWidth, 12),
              SizedBox(height: 8.h),
              _line(secondWidth, 10),
            ],
          ),
        ),
      ],
    );
  }

  /// Plain vertical list of rows (chat list, group list, contacts, schedule).
  static Widget list({int rows = 6}) {
    return AppSkeletonPulse(
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) SizedBox(height: 18.h),
            listRow(),
          ],
        ],
      ),
    );
  }

  /// Rounded card with header row + body lines (group info, contact sheet).
  static Widget card({double height = 150}) {
    return AppSkeletonPulse(
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSkeletonBlock(width: 44, height: 44, circle: true),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line(120, 12),
                      SizedBox(height: 6.h),
                      _line(80, 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _line(double.infinity, 12),
            SizedBox(height: 8.h),
            _line(180, 10),
          ],
        ),
      ),
    );
  }

  /// Chat screen: a few alternating message bubble blocks.
  static Widget chatScreen({int bubbles = 8}) {
    return AppSkeletonPulse(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < bubbles; i++) ...[
              SizedBox(height: 16.h),
              Align(
                alignment:
                    i.isEven ? Alignment.centerRight : Alignment.centerLeft,
                child: AppSkeletonBlock(
                  width: i.isEven ? 150.w : 190.w,
                  height: 38.h,
                  radius: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Media grid cells (gallery).
  static Widget cells({int columns = 3, int rows = 3}) {
    return AppSkeletonPulse(
      child: GridView.count(
        crossAxisCount: columns,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        padding: EdgeInsets.all(2.r),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          for (var i = 0; i < columns * rows; i++)
            AppSkeletonBlock(
              width: double.infinity,
              height: double.infinity,
              radius: 10,
            ),
        ],
      ),
    );
  }

  /// Full-screen cold-start skeleton shown while the app decides its first
  /// screen. Includes the brand gradient mark so every init looks identical.
  static Widget fullScreen() {
    bool dark(BuildContext context) =>
        Theme.of(context).brightness == Brightness.dark;
    return AppSkeletonPulse(
      child: Builder(
        builder: (context) => Container(
          width: double.infinity,
          height: double.infinity,
          color: dark(context)
              ? CustomColor.kDarkBackground
              : CustomColor.kBackground,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96.r,
                height: 96.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CustomColor.primaryGradient,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chat_bubble_rounded,
                  size: 48.r,
                  color: CustomColor.kWhite,
                ),
              ),
              SizedBox(height: 28.h),
              _line(150, 14),
              SizedBox(height: 12.h),
              _line(90, 10),
              SizedBox(height: 48.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _line(20, 20),
                  SizedBox(width: 10.w),
                  _line(120, 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full home-page skeleton shown while the app sorts out login before the
  /// chat home renders. Mirrors the real home layout: brand-logo header with
  /// icon placeholders, search bar, upcoming-schedule card, filter pills and
  /// the chat list.
  static Widget homeScreen() {
    bool dark(BuildContext context) =>
        Theme.of(context).brightness == Brightness.dark;
    return AppSkeletonPulse(
      child: Builder(
        builder: (context) => Container(
          width: double.infinity,
          height: double.infinity,
          color: dark(context)
              ? CustomColor.kDarkBackground
              : CustomColor.kBackground,
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand header: real logo + action icon placeholders.
                  SizedBox(
                    height: 42.h,
                    child: Row(
                      children: [
                        Flexible(
                          child: Image.asset(
                            "assets/images/logo1.jpg", // same as home header
                            height: 34.h,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                AppSkeletonBlock(width: 130.w, height: 30.h),
                          ),
                        ),
                        const Spacer(),
                        AppSkeletonBlock(
                            width: 36.r, height: 36.r, circle: true),
                        SizedBox(width: 8.w),
                        AppSkeletonBlock(
                            width: 36.r, height: 36.r, circle: true),
                        SizedBox(width: 8.w),
                        AppSkeletonBlock(
                            width: 36.r, height: 36.r, circle: true),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // Search bar.
                  AppSkeletonBlock(
                    width: double.infinity,
                    height: 46.h,
                    radius: 23,
                  ),
                  SizedBox(height: 14.h),
                  // Upcoming schedule card header.
                  Row(
                    children: [
                      AppSkeletonBlock(width: 18.r, height: 18.r, radius: 5),
                      SizedBox(width: 10.w),
                      _line(70, 14),
                      const Spacer(),
                      _line(60, 10),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  // Schedule card.
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    ),
                    child: Row(
                      children: [
                        AppSkeletonBlock(
                            width: 38.r, height: 38.r, circle: true),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _line(110, 12),
                              SizedBox(height: 8.h),
                              _line(150, 10),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        AppSkeletonBlock(width: 52, height: 26, radius: 13),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  // Filter pills (horizontally scrollable like the real chips).
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: [
                        AppSkeletonBlock(width: 92.w, height: 34.h, radius: 17),
                        SizedBox(width: 10.w),
                        AppSkeletonBlock(width: 72.w, height: 34.h, radius: 17),
                        SizedBox(width: 10.w),
                        AppSkeletonBlock(width: 80.w, height: 34.h, radius: 17),
                        SizedBox(width: 10.w),
                        AppSkeletonBlock(width: 96.w, height: 34.h, radius: 17),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),
                  // Chat list.
                  for (var i = 0; i < 6; i++) ...[
                    if (i > 0) SizedBox(height: 18.h),
                    listRow(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Holds the branded skeleton on screen for [AppSkeletonConfig.duration],
/// then reveals [child] with a soft cross-fade. Wraps every cold start.
class AppInitGate extends StatefulWidget {
  final Widget child;
  final bool homeScreen;

  const AppInitGate({super.key, required this.child, this.homeScreen = false});

  @override
  State<AppInitGate> createState() => _AppInitGateState();
}

class _AppInitGateState extends State<AppInitGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  // NOTE: init skeleton disabled — the home-screen skeleton overflows the
  // bottom by 115px on small devices. Show the real screen directly instead.
  final bool _ready = true;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    // Commented out: delays the real screen behind the branded skeleton.
    // Future<void>.delayed(AppSkeletonConfig.duration).then((_) {
    //   if (!mounted) return;
    //   setState(() => _ready = true);
    //   _reveal.forward();
    // });
    _reveal.value = 1.0;
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, child) {
        if (!_ready) {
          return widget.homeScreen
              ? AppSkeletonPresets.homeScreen()
              : AppSkeletonPresets.fullScreen();
        }
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _reveal,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
