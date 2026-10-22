import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outlined, text, danger }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final Size? buttonSize;
  final Icon? buttonIcon;
  final double? fontSize;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? fontColor;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.buttonSize,
    this.buttonIcon,
    this.fontSize,
    this.borderRadius,
    this.backgroundColor,
    this.fontColor,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.height,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _isActive =>
      widget.onTap != null && !widget.isDisabled && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown:
          _isActive ? (_) => setState(() => _isPressed = true) : null,
      onPointerUp: _isActive ? (_) => setState(() => _isPressed = false) : null,
      onPointerCancel:
          _isActive ? (_) => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: AppAnimation.buttonPress,
        curve: AppAnimation.easeInOut,
        child: AnimatedContainer(
          duration: AppAnimation.buttonPress,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(widget.borderRadius ?? AppRadius.xxxl.r),
            gradient: _resolveGradient(),
            color: _resolveBackground(),
            boxShadow: _resolveShadow(),
          ),
          child: MaterialButton(
            onPressed: _isActive ? widget.onTap : null,
            disabledElevation: 0,
            highlightElevation: 0,
            height: widget.height ?? 50.h,
            minWidth: widget.buttonSize?.width ?? double.infinity,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? AppRadius.xxxl.r),
              side: _resolveBorderSide() ?? BorderSide.none,
            ),
            color: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        width: AppIcons.xl.r,
        height: AppIcons.xl.r,
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(CustomColor.kTextOnDark),
        ),
      );
    }

    final textStyle = AppTextStyles.titleSm.copyWith(
      fontSize: widget.fontSize ?? 15.sp,
      color: _resolveTextColor(),
    );

    if (widget.buttonIcon == null) {
      return Text(widget.text, style: textStyle);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        widget.buttonIcon!,
        SizedBox(width: AppSpacing.lg.w),
        Text(widget.text, style: textStyle),
      ],
    );
  }

  Gradient? _resolveGradient() {
    if (widget.backgroundColor != null) return null;
    if (widget.isDisabled) return null;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return CustomColor.primaryGradient;
      case AppButtonVariant.danger:
        return const LinearGradient(
          colors: [CustomColor.kDangerFill, CustomColor.kDangerText],
        );
      case AppButtonVariant.secondary:
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return null;
    }
  }

  Color? _resolveBackground() {
    if (widget.isDisabled)
      return CustomColor.kTextTertiary.withValues(alpha: 0.2);
    if (widget.backgroundColor != null) return widget.backgroundColor;
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return null;
      case AppButtonVariant.secondary:
        return CustomColor.kPrimaryLight;
      case AppButtonVariant.outlined:
        return Colors.transparent;
      case AppButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _resolveTextColor() {
    if (widget.isDisabled) return CustomColor.kTextTertiary;
    if (widget.fontColor != null) return widget.fontColor!;
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return CustomColor.kTextOnDark;
      case AppButtonVariant.secondary:
        return CustomColor.kPrimaryDark;
      case AppButtonVariant.outlined:
        return CustomColor.kPrimaryText;
      case AppButtonVariant.text:
        return CustomColor.kPrimaryText;
    }
  }

  BorderSide? _resolveBorderSide() {
    if (widget.isDisabled)
      return BorderSide(
          color: CustomColor.kTextTertiary.withValues(alpha: 0.2));
    switch (widget.variant) {
      case AppButtonVariant.outlined:
        return BorderSide(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.4));
      default:
        return BorderSide.none;
    }
  }

  List<BoxShadow>? _resolveShadow() {
    if (widget.isDisabled || !_isActive)
      return [BoxShadow(color: Colors.transparent, blurRadius: 0)];
    if (widget.variant == AppButtonVariant.text ||
        widget.variant == AppButtonVariant.outlined) return null;
    return [
      BoxShadow(
        color: CustomColor.kPrimaryColor
            .withValues(alpha: _isPressed ? 0.15 : 0.3),
        blurRadius: _isPressed ? 8 : 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
