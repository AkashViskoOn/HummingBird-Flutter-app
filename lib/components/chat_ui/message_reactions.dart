import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/components/chat_ui/message_reaction_info_sheet.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';

class MessageReactions extends StatelessWidget {
  final String messageId;
  final String? reactionsJson;
  final bool isMe;
  final double? emojiSize;
  final Color? accentColor;

  const MessageReactions({
    super.key,
    required this.messageId,
    this.reactionsJson,
    this.isMe = false,
    this.emojiSize,
    this.accentColor,
  });

  Map<String, dynamic>? get _reactions {
    if (reactionsJson == null || reactionsJson!.isEmpty) return null;
    try {
      final decoded = jsonDecode(reactionsJson!);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reactions = _reactions;
    if (reactions == null || reactions.isEmpty) return const SizedBox.shrink();

    final chatController = Get.find<ChatController>();
    final userId = chatController.userController.userId;
    final accent = accentColor ?? CustomColor.kPrimaryColor;
    final emoji = emojiSize ?? 14.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    var total = 0;
    var mine = false;
    for (final value in reactions.values) {
      if (value is List) {
        total += value.length;
        if (!mine && value.any((u) => u == userId)) mine = true;
      }
    }

    // One solid pill so the reactions read over wallpaper and media. The
    // surface is a real token per theme (not the near-invisible
    // kUltraLightPrimary); the trailing count is the TOTAL and only renders
    // when it exceeds 1.
    final surface = isDark
        ? CustomColor.kDarkSurface3
        : CustomColor.kSurfaceTintStrong;
    final border = mine
        ? accent.withValues(alpha: isDark ? 0.65 : 0.45)
        : (isDark ? CustomColor.kDarkBorder : CustomColor.kSlate200);
    final countColor = mine
        ? CustomColor.primaryTextFor(isDark)
        : (isDark
            ? CustomColor.kTextOnDarkSecondary
            : CustomColor.kTextSecondary);

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xxs.h),
      child: GestureDetector(
        onTap: () => Get.bottomSheet(
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
          ),
          MessageReactionInfoSheet(reactionsJson: reactionsJson!),
        ),
        // Pop-in animation (scale + fade) whenever the pill appears or a
        // reaction update lands.
        child: TweenAnimationBuilder<double>(
          key: const ValueKey('reaction_pill'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: mine
                  ? Color.alphaBlend(accent.withValues(alpha: 0.10), surface)
                  : surface,
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
              border: Border.all(color: border, width: mine ? 1.25 : 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: isDark ? 8 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs.w, vertical: AppSpacing.xxs.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...reactions.entries.map((e) {
                  final users = (e.value as List?)?.cast<String>() ?? [];
                  final userReacted = users.contains(userId);
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.xxs.w),
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                    decoration: BoxDecoration(
                      color: userReacted
                          ? accent.withValues(alpha: isDark ? 0.30 : 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill.r),
                    ),
                    child: Text(e.key,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: emoji.sp,
                          height: 1.2,
                        )),
                  );
                }),
                if (total > 1)
                  Padding(
                    padding: EdgeInsets.only(left: AppSpacing.xxs.w),
                    child: Text(
                      '$total',
                      style: AppTextStyles.labelSm.copyWith(
                        color: countColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
