import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Visual treatment of a [CommonAppBar].
enum CommonAppBarVariant {
  /// Flat bar that follows the ambient theme surface. The default, and what
  /// most screens want — content-first surfaces.
  surface,

  /// Branded gradient with white text. For entry points where the bar itself
  /// carries the brand (login, onboarding, top-level destinations).
  branded,
}

/// The app's single app bar.
///
/// Replaces the ~55 hand-rolled `AppBar(...)` calls that each repeated the same
/// shape and, worse, each re-decided its own colours with an `isDark ? ... : ...`
/// ternary. Those ternaries meant the bar, the back button and the title drifted
/// apart whenever one of them was updated and the others were not.
///
/// Colour now comes from the ambient [Theme], so a screen gets a bar that
/// matches the scaffold it sits on and stays correct if the palette changes.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final CommonAppBarVariant variant;

  final List<Widget>? actions;
  final Color? backgroundColor;

  /// Escape hatch for bars whose title is not a single line of text — an
  /// avatar plus a two-line label, for example. When set it replaces [title].
  final Widget? titleWidget;

  final String? subtitle;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final bool centerTitle;
  final double elevation;

  /// Replaces the default back button.
  ///
  /// For bars whose leading affordance dismisses the screen (a close X on a
  /// full-screen editor) rather than popping a route. Leave null to get the
  /// standard back button.
  final Widget? leading;

  const CommonAppBar({
    super.key,
    required this.title,
    this.variant = CommonAppBarVariant.surface,
    this.actions,
    this.backgroundColor,
    this.titleWidget,
    this.subtitle,
    this.bottom,
    this.showBackButton = true,
    this.centerTitle = false,
    this.elevation = 0,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBranded = variant == CommonAppBarVariant.branded;
    final isDark = theme.brightness == Brightness.dark;

    // On a branded bar everything is white; on a surface bar everything comes
    // from the theme — unless the caller pinned a background, in which case the
    // label colour has to follow that surface rather than the ambient theme.
    final onBar = isBranded
        ? CustomColor.kTextOnDark
        : backgroundColor != null
            ? CustomColor.onColor(backgroundColor!)
            : (isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary);

    final Widget titleContent;
    if (titleWidget != null) {
      titleContent = titleWidget!;
    } else if (subtitle != null && subtitle!.isNotEmpty) {
      titleContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMd.copyWith(
              color: onBar,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: onBar.withValues(alpha: isBranded ? 0.85 : 0.7),
            ),
          ),
        ],
      );
    } else {
      titleContent = Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headingMd.copyWith(
          color: onBar,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final resolvedLeading =
        leading ?? (showBackButton ? AppBackButton(color: onBar) : null);

    return AppBar(
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor ??
          (isBranded ? Colors.transparent : theme.appBarTheme.backgroundColor),
      foregroundColor: onBar,
      // A translucent default tint fights the flat theme surface.
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      titleSpacing: resolvedLeading == null ? 16 : null,
      title: titleContent,
      actions: actions,
      bottom: bottom,
      flexibleSpace: isBranded
          ? Container(
              decoration: const BoxDecoration(
                // Drawn from the Fill ramp, not the identity blues: the top-left
                // stop is the lightest part of the bar and the white title sits
                // directly on it, so kPrimaryColor here put the title at 3.46:1.
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CustomColor.kPrimaryFill,
                    CustomColor.kPrimaryDark,
                    CustomColor.kPrimaryFillDeep,
                  ],
                ),
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight.h + (bottom?.preferredSize.height ?? 0),
      );
}
