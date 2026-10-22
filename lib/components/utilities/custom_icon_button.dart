import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class CustomIconButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color color;
  final String? tooltip;
  const CustomIconButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.iconColor = Colors.black,
    this.tooltip,
  });

  @override
  State<CustomIconButton> createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip ?? widget.title,
      child: Tooltip(
        message: widget.tooltip ?? widget.title,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: AppAnimation.buttonPress,
            curve: AppAnimation.easeInOut,
            child: Container(
              padding: EdgeInsets.all(AppSpacing.lg.r),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: AppAnimation.normal,
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                      boxShadow: _isPressed
                          ? []
                          : [
                              BoxShadow(
                                color: CustomColor.kPrimaryColor
                                    .withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: AppIcons.xxl.r,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    widget.title,
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
