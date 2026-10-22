import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class DefaultButton extends StatefulWidget {
  final void Function() onTap;
  final String title;

  const DefaultButton({super.key, required this.onTap, required this.title});

  @override
  State<DefaultButton> createState() => _DefaultButtonState();
}

class _DefaultButtonState extends State<DefaultButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: AppAnimation.buttonPress,
        curve: AppAnimation.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: CustomColor.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor
                    .withValues(alpha: _isPressed ? 0.15 : 0.3),
                blurRadius: _isPressed ? 8 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: MaterialButton(
            onPressed: widget.onTap,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
            ),
            color: Colors.transparent,
            child: Text(
              widget.title,
              style: AppTextStyles.titleMd
                  .copyWith(color: CustomColor.kTextOnDark),
            ),
          ),
        ),
      ),
    );
  }
}
