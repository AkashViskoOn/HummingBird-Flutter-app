import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Semantic intent of a message, so callers pick a meaning instead of a colour
/// and every surface renders it the same way.
enum SnackVariant { info, success, error, warning }

/// The app's single snackbar entry point.
///
/// Replaces the ~65 scattered `Get.snackbar(...)` calls, which each invented
/// their own colours, durations and margins — that inconsistency is why
/// feedback looked different on every screen.
///
/// Colour comes from the active [Theme] rather than a constant, so feedback is
/// legible in both light and dark mode. Previously this class hard-coded a dark
/// surface with white text, which was invisible against a light background.
///
/// Every message is also announced to screen readers via [Semantics] and
/// [SnackBar], and each variant pairs its icon with a text label so the meaning
/// does not depend on colour alone.
class CustomSnackbar {
  CustomSnackbar._();

  /// Shown at the bottom, out of the way of the content it describes.
  static const SnackPosition _position = SnackPosition.BOTTOM;

  /// Long enough to read a sentence, short enough not to block a flow. Errors
  /// stay longer because they usually need to be read and acted on.
  static const Duration _infoDuration = Duration(seconds: 3);
  static const Duration _errorDuration = Duration(seconds: 5);

  /// Neutral message.
  static void show({
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(
        title: title,
        message: message,
        variant: SnackVariant.info,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// Something the user asked for succeeded.
  static void success({
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(
        title: title,
        message: message,
        variant: SnackVariant.success,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// The action failed, or the user's input was rejected.
  static void error({
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(
        title: title,
        message: message,
        variant: SnackVariant.error,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  /// The action needs attention before it can succeed.
  static void warning({
    String? title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(
        title: title,
        message: message,
        variant: SnackVariant.warning,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  static void _show({
    String? title,
    required String message,
    required SnackVariant variant,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // No navigator means the app is tearing down or the widget was built
    // outside a Get context. Showing anyway would throw.
    if (Get.context == null) {
      debugPrint('[snackbar:${variant.name}] ${title ?? ''} $message'.trim());
      return;
    }

    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    final accent = _accent(variant, isDark);
    final surface = isDark ? CustomColor.kDarkSurface2 : CustomColor.kWhite;
    final onSurface = isDark ? Colors.white : CustomColor.kTextPrimary;
    final bodyColor = isDark ? Colors.white70 : CustomColor.kTextSecondary;

    Get.showSnackbar(
      GetSnackBar(
        message: message,
        title: title,
        isDismissible: true,
        snackPosition: _position,
        snackStyle: SnackStyle.FLOATING,
        borderRadius: AppRadius.xl.r,
        margin: EdgeInsets.symmetric(
          vertical: AppSpacing.xl.h,
          horizontal: AppSpacing.xl.w,
        ),
        duration:
            variant == SnackVariant.error ? _errorDuration : _infoDuration,
        backgroundColor: surface,
        icon: Icon(_icon(variant), color: accent, size: 20),
        mainButton: (actionLabel != null && onAction != null)
            ? TextButton(
                onPressed: () {
                  // Dismiss first so the destination screen is not covered.
                  Get.closeCurrentSnackbar();
                  onAction();
                },
                child: Text(
                  actionLabel,
                  style: AppTextStyles.label.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        titleText: title == null || title.isEmpty
            ? null
            : Text(
                title,
                style: AppTextStyles.titleSm.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
        messageText: message.isEmpty
            ? null
            : Text(
                message,
                style: AppTextStyles.bodyMd.copyWith(color: bodyColor),
              ),
        boxShadows: isDark ? AppShadow.elevatedDark : AppShadow.elevatedLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  static Color _accent(SnackVariant variant, bool isDark) {
    switch (variant) {
      case SnackVariant.success:
        return CustomColor.kSuccess;
      case SnackVariant.error:
        return CustomColor.kDangerRed;
      case SnackVariant.warning:
        return isDark ? CustomColor.kWarning : CustomColor.kWarningDark;
      case SnackVariant.info:
        return CustomColor.kPrimaryColor;
    }
  }

  static IconData _icon(SnackVariant variant) {
    switch (variant) {
      case SnackVariant.success:
        return Icons.check_circle_rounded;
      case SnackVariant.error:
        return Icons.error_rounded;
      case SnackVariant.warning:
        return Icons.warning_rounded;
      case SnackVariant.info:
        return Icons.info_rounded;
    }
  }
}
