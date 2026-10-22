import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// How an [AppEmptyState] arranges itself inside its parent.
enum EmptyStateLayout {
  /// Centred in the available space. For a whole screen or list that is empty.
  centered,

  /// Left-aligned, compact. For an empty card or a section of a larger screen.
  inline,
}

/// The app's single "there is nothing here" presentation.
///
/// Replaces the handful of near-identical private `_Empty*` widgets that each
/// rolled their own icon badge, spacing and copy treatment. Beyond consistency,
/// this is what makes an empty list *actionable*: pass [actionLabel] and
/// [onAction] and the user gets a way out of the dead end, instead of a dead
/// screen that only says "no items".
///
/// Colours come from the active [Theme] rather than a brightness check, so it
/// is legible in both light and dark mode. The title and message are merged
/// into one semantic node so a screen reader announces them as a single
/// statement rather than two disconnected strings.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final EmptyStateLayout layout;

  /// Optional call to action. Both must be provided for the button to show.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Secondary, lower-emphasis action — typically "Refresh"/"Retry" sitting
  /// next to the primary "Create". Both must be provided to show.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  /// Overrides the tinted badge default.
  final Color? accent;

  /// Draws the content inside a bordered surface card instead of bare.
  ///
  /// For an empty state that occupies a card within a larger screen, where the
  /// card boundary is what separates it from the surrounding content. Bare
  /// [EmptyStateLayout.inline] is for a section that already has a container.
  final bool bordered;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.layout = EmptyStateLayout.centered,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.accent,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colour = accent ?? theme.colorScheme.primary;
    final titleColour = theme.colorScheme.onSurface;
    final bodyColour = isDark
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurfaceVariant;

    final badge = Container(
      padding: EdgeInsets.all(AppSpacing.xxxl.r),
      decoration: BoxDecoration(
        // A low-alpha tint of the accent reads as "brand-tinted" in either
        // mode without hard-coding a light-only background colour.
        color: colour.withValues(alpha: isDark ? 0.18 : 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: colour, size: AppIcons.huge.r + 4),
    );

    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: layout == EmptyStateLayout.centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign:
              layout == EmptyStateLayout.centered ? TextAlign.center : null,
          style: AppTextStyles.titleLg.copyWith(
            color: titleColour,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm.h),
          Text(
            message!,
            textAlign:
                layout == EmptyStateLayout.centered ? TextAlign.center : null,
            style: AppTextStyles.subtitle.copyWith(
              color: bodyColour,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    // Title + body are announced by the surrounding Semantics(label:) above,
    // so exclude them as raw nodes to avoid double-announcement. The actions
    // must STAY semantic so a screen reader can reach and activate them.
    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: AppSpacing.xl.h),
          AppButton(text: actionLabel!, onTap: onAction),
        ],
        if (secondaryActionLabel != null && onSecondaryAction != null) ...[
          SizedBox(height: AppSpacing.md.h),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: onSecondaryAction,
              style: TextButton.styleFrom(
                foregroundColor: bodyColour,
                minimumSize: const Size(88, 48),
              ),
              child: Text(secondaryActionLabel!),
            ),
          ),
        ],
      ],
    );

    // One semantic node: the icon is decorative (the title already carries the
    // meaning) and title+message should be announced together. The action
    // buttons are excluded from that container so they remain individually
    // focusable and activatable by a screen reader.
    final hasActions = (actionLabel != null && onAction != null) ||
        (secondaryActionLabel != null && onSecondaryAction != null);
    final excluded = ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: layout == EmptyStateLayout.centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [badge, SizedBox(height: AppSpacing.xl.h), copy],
      ),
    );

    final content = layout == EmptyStateLayout.centered
        ? Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.section.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [excluded, actions],
              ),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    badge,
                    SizedBox(height: AppSpacing.xl.h),
                    copy,
                  ],
                ),
              ),
              if (hasActions) ...[
                SizedBox(height: AppSpacing.xl.h),
                actions,
              ],
            ],
          );

    return Semantics(
      container: true,
      label: message == null || message!.isEmpty ? title : '$title. $message',
      child: !bordered
          ? content
          : Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: AppSpacing.xxl.h,
                horizontal: AppSpacing.xxl.r,
              ),
              decoration: BoxDecoration(
                color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
                borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                border: Border.all(
                  color: isDark
                      ? CustomColor.kDarkBorder
                      : CustomColor.kLightBorder.withValues(alpha: 0.5),
                ),
              ),
              child: content,
            ),
    );
  }
}
