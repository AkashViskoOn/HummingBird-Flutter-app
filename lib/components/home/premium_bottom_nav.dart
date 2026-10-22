import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class PremiumBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userController = Get.find<UserController>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 10.h),
        child: SizedBox(
          height: 82.h,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              /// MAIN BAR
              Positioned.fill(
                top: 12.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? CustomColor.kDarkSurface
                        : CustomColor.kTextOnDark,
                    borderRadius: BorderRadius.circular(AppRadius.thirty.r),
                    border: Border.all(
                      color: isDark
                          ? CustomColor.kOverlay8
                          : Colors.blue.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.08),
                        blurRadius: 35,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 70.w,
                      right: 12.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _IconItem(
                            index: 1,
                            currentIndex: currentIndex,
                            icon: Icons.call_outlined,
                            title: "Calls",
                            onTap: onTap,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _StatusItem(
                            index: 2,
                            currentIndex: currentIndex,
                            onTap: onTap,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _IconItem(
                            index: 3,
                            currentIndex: currentIndex,
                            icon: Icons.calendar_month_outlined,
                            title: "Schedule",
                            onTap: onTap,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _ProfileItem(
                            index: 4,
                            currentIndex: currentIndex,
                            userController: userController,
                            onTap: onTap,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Floating Logo
              Positioned(
                left: 6.w,
                top: -2.h,
                child: Semantics(
                  button: true,
                  selected: currentIndex == 0,
                  label: 'Chat',
                  child: GestureDetector(
                    onTap: () => onTap(0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 62.r,
                    height: 62.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CustomColor.kTextOnDark,
                      border: Border.all(
                        color: currentIndex == 0
                            ? CustomColor.kPrimaryColor
                            : CustomColor.kTextOnDark,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.20),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.r),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/logo2.jpg",
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.chat_bubble_outline,
                            color: CustomColor.kPrimaryColor,
                            size: 26.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

///------------------------------------------------------------
/// NORMAL ITEM
///------------------------------------------------------------

class _IconItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String title;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _IconItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selected = currentIndex == index;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(
            horizontal: 10.w,
            vertical: 6.h,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 23.r,
                color:
                    selected ? CustomColor.kPrimaryColor : CustomColor.kSlate500,
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: AppTextStyles.labelSm.copyWith(
                    color: selected
                        ? CustomColor.kPrimaryColor
                        : CustomColor.kSlate500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///------------------------------------------------------------
/// STATUS ITEM
///------------------------------------------------------------

class _StatusItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _StatusItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 6.h,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.radio_button_checked_rounded,
                  size: 23.r,
                  color: selected
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kSlate500,
                ),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8.r,
                    height: 8.r,
                    decoration: BoxDecoration(
                      color: CustomColor.kInfo,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CustomColor.kTextOnDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              "Status",
              style: AppTextStyles.labelSm.copyWith(
                  color: selected
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kSlate500),
            ),
          ],
        ),
      ),
    );
  }
}

///------------------------------------------------------------
/// PROFILE ITEM
///------------------------------------------------------------

class _ProfileItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final UserController userController;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _ProfileItem({
    required this.index,
    required this.currentIndex,
    required this.userController,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = currentIndex == index;

    final String image = userController.user?.userImage ?? "";

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 6.h,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 30.r,
                  height: 30.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? CustomColor.kPrimaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 15.r,
                    backgroundColor: isDark
                        ? CustomColor.kDarkSurface3
                        : CustomColor.kUltraLightBg,
                    backgroundImage: image.isNotEmpty
                        ? CachedNetworkImageProvider(
                            "${Endpoints.mediaBaseUrl}$image",
                          )
                        : null,
                    onBackgroundImageError:
                        image.isNotEmpty ? (_, __) {} : null,
                    child: image.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 16.r,
                            color: CustomColor.kSlate500,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 1.w,
                  bottom: 1.h,
                  child: Container(
                    width: 9.r,
                    height: 9.r,
                    decoration: BoxDecoration(
                      color: CustomColor.kSuccess,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CustomColor.kTextOnDark,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              "You",
              style: AppTextStyles.labelSm.copyWith(
                  color: selected
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kSlate500),
            ),
          ],
        ),
      ),
    );
  }
}
