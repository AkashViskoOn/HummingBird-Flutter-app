import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final String hintText;
  final Icon? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Color? bgColor;
  final bool needShadow;
  final int? maxLines;
  final int? maxLength;
  final bool isPassword;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.bgColor,
    this.needShadow = false,
    this.maxLines,
    this.maxLength,
    this.isPassword = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.normal,
      curve: AppAnimation.easeInOut,
      decoration: BoxDecoration(
        color: widget.bgColor ?? CustomColor.kUltraLightPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(
          color: _isFocused ? CustomColor.kPrimaryColor : Colors.transparent,
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: widget.needShadow
            ? null
            : [
                BoxShadow(
                  color: _isFocused
                      ? CustomColor.kPrimaryColor.withValues(alpha: 0.12)
                      : CustomColor.kScrim20,
                  blurRadius: _isFocused ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: TextFormField(
        onChanged: widget.onChanged,
        controller: widget.controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines ?? 1,
        maxLength: widget.maxLength,
        obscureText: _obscureText,
        textCapitalization: widget.textCapitalization,
        style: AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextPrimary),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle:
              AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextTertiary),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.isPassword
              ? IconButton(
                  tooltip: 'Show password',
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20.r,
                    color: CustomColor.kTextTertiary,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : widget.suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18.r,
            vertical: widget.maxLines != null && widget.maxLines! > 1
                ? AppSpacing.xl.h
                : AppSpacing.xxl.r,
          ),
        ),
      ),
    );
  }
}
