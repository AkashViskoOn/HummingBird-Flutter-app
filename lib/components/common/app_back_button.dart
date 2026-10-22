import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/theme/app_icons.dart';

/// The one and only back button for the whole app — an iOS-style chevron.
///
/// Every screen must use this widget instead of raw `Icons.arrow_back*` /
/// `Icons.chevron_left*` so size, stroke, alignment, padding, color handling
/// and pop behavior stay identical everywhere. Leave [color] null to inherit
/// the theme's surface foreground, which is correct in both light and dark
/// mode; only override it on a surface the app bar foreground cannot describe.
class AppBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onTap;

  const AppBackButton({super.key, this.color, this.onTap});

  /// Single source of truth for the back glyph across the app.
  static const IconData iconData = Icons.arrow_back_ios_new;

  /// Glyph size — never override per screen.
  static final double glyphSize = AppIcons.lg.r;

  /// Fixed square hit target (HIG-friendly) so alignment/padding match
  /// whether the button stands alone or sits inside a decorated container.
  static final double hitSize = AppIcons.huge.r;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? Get.back,
        child: Semantics(
          label: 'Back',
          button: true,
          child: SizedBox(
            width: hitSize,
            height: hitSize,
            child: Center(
              child: Icon(
                iconData,
                size: glyphSize,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
