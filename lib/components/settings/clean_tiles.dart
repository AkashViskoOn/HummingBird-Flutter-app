import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class CleanSectionLabel extends StatelessWidget {
  final String text;

  const CleanSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? CustomColor.kTextOnDarkMuted
              : CustomColor.kTextTertiary,
          letterSpacing: 1),
    );
  }
}

class CleanSettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  const CleanSettingsTile({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.icon,
    this.onTap,
    this.danger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tint =
        danger ? CustomColor.kDangerRed : CustomColor.kPrimaryColor;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Material(
        color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kCardBackground,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(icon, size: 20.r, color: tint),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSm.copyWith(
                            color: danger
                                ? CustomColor.kDangerRed
                                : (isDark
                                    ? CustomColor.kTextOnDark
                                    : CustomColor.kTextPrimary)),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySm.copyWith(
                              color: isDark
                                  ? CustomColor.kTextOnDarkMuted
                                  : CustomColor.kTextTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark
                          ? CustomColor.kTextOnDarkMuted
                          : CustomColor.kTextTertiary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CleanSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool danger;

  const CleanSwitchTile({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.icon,
    required this.value,
    required this.onChanged,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return CleanSettingsTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      danger: danger,
      onTap: () => onChanged(!value),
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch.adaptive(
          value: value,
          activeThumbColor:
              danger ? CustomColor.kDangerRed : CustomColor.kPrimaryColor,
          activeTrackColor:
              (danger ? CustomColor.kDangerRed : CustomColor.kPrimaryColor)
                  .withValues(alpha: 0.3),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class CleanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const CleanCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? CustomColor.kDarkSurface2
            : CustomColor.kCardBackground,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
      ),
      child: child,
    );
  }
}
