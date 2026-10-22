import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class Switcher extends StatefulWidget {
  final String title;
  final String subtitle;
  final String icon;
  final void Function() onTap;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const Switcher(
      {super.key,
      required this.title,
      this.subtitle = '',
      required this.icon,
      required this.onTap,
      this.value = true,
      this.onChanged});

  @override
  State<Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends State<Switcher> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          color: CustomColor.kPrimaryLight,
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Padding(
          padding:
              EdgeInsets.only(top: 8.h, bottom: 8.h, right: 10.w, left: 10.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.headingSm
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
              SizedBox(
                width: 70.r,
                height: 30.r,
                child: Padding(
                  padding: EdgeInsets.only(left: 0.w, right: 0.w),
                  child: LiteRollingSwitch(
                    onTap: () {},
                    onSwipe: () {},
                    onDoubleTap: () {},
                    value: widget.value,
                    width: 80.w,
                    textOn: 'on',
                    textOff: 'off',
                    colorOn: CustomColor.kOnlineGreen,
                    colorOff: CustomColor.kDangerRed,
                    iconOn: Icons.done,
                    textOnColor: CustomColor.kTextOnDark,
                    iconOff: Icons.close,
                    textSize: 12.0,
                    onChanged: (bool position) {
                      widget.onChanged?.call(position);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
