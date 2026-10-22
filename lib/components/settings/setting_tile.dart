import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class SettingTile extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDarkMode;
  final void Function() onTap;

  const SettingTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDarkMode = false,
    required this.onTap,
  });

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  @override
  Widget build(BuildContext context) {
    return PressScale(
        child: Padding(
      padding: EdgeInsets.symmetric(
          horizontal: widget.isDarkMode ? 0 : 15.w, vertical: AppSpacing.xxs.h),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w,
              vertical:
                  widget.subtitle != null ? AppSpacing.lg.h : AppSpacing.md.h),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? CustomColor.kTextOnDark.withValues(alpha: 0.05)
                : CustomColor.kTextOnDark,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            boxShadow: widget.isDarkMode ? AppShadow.none : AppShadow.cardLight,
            border: widget.isDarkMode
                ? Border.all(color: CustomColor.kOverlay6)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      widget.color.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: widget.isDarkMode
                      ? []
                      : [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  widget.icon,
                  color: CustomColor.kTextOnDark,
                  size: AppIcons.lg.r,
                ),
              ),
              SizedBox(width: AppSpacing.xl.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: (widget.isDarkMode
                              ? AppTextStyles.titleSm
                              : AppTextStyles.titleMd)
                          .copyWith(
                        fontWeight: FontWeight.w500,
                        color: widget.isDarkMode
                            ? CustomColor.kTextOnDark.withValues(alpha: 0.92)
                            : null,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      SizedBox(height: AppSpacing.xxs.h),
                      Text(
                        widget.subtitle!,
                        style: AppTextStyles.helper.copyWith(
                          color: widget.isDarkMode
                              ? CustomColor.kTextOnDark.withValues(alpha: 0.4)
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? widget.color.withValues(alpha: 0.15)
                      : CustomColor.kUltraLightPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: widget.isDarkMode
                      ? widget.color
                      : CustomColor.kPrimaryColor,
                  size: AppIcons.lg.r,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
