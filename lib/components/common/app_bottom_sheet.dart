import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_dimensions.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required Widget child,
    double? maxHeight,
    bool isDismissible = true,
    String? title,
    Widget? trailing,
  }) {
    return showModalBottomSheet<T>(
      context: _getContext(),
      useSafeArea: true,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => _AppBottomSheetContent(
        maxHeight: maxHeight,
        title: title,
        trailing: trailing,
        child: child,
      ),
    );
  }

  static BuildContext _getContext() {
    return _getNavigatorKey().currentContext!;
  }

  static GlobalKey<NavigatorState> _getNavigatorKey() {
    return _navigatorKey;
  }

  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();
}

class _AppBottomSheetContent extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final String? title;
  final Widget? trailing;

  const _AppBottomSheetContent({
    required this.child,
    this.maxHeight,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.modalRadius.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || trailing != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.cardPaddingH.w,
                  vertical: AppSpacing.lg.h,
                ),
                child: Row(
                  children: [
                    if (title != null)
                      Text(title!,
                          style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl.h),
                child: Container(
                  width: 36.r,
                  height: 4.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                ),
              ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.cardPaddingH.w),
                child: child,
              ),
            ),
            SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom + AppSpacing.xl.h),
          ],
        ),
      ),
    );
  }
}
