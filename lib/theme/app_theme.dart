import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/res/colors.dart';
import 'app_radius.dart';
import 'app_dimensions.dart';
import 'app_spacing.dart';
import 'app_theme_extensions.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildLight();
  static ThemeData get dark => _buildDark();

  static ThemeData _buildLight() {
    final textTheme = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: CustomColor.kPrimaryColor,
        onPrimary: CustomColor.kWhite,
        primaryContainer: CustomColor.kPrimaryLight,
        onPrimaryContainer: CustomColor.kPrimaryDark,
        secondary: CustomColor.kInfo,
        onSecondary: CustomColor.kWhite,
        secondaryContainer: CustomColor.kUltraLightBg,
        onSecondaryContainer: CustomColor.kTextPrimary,
        tertiary: CustomColor.kGoldAccent,
        onTertiary: CustomColor.kWhite,
        error: CustomColor.kDangerRed,
        onError: CustomColor.kWhite,
        surface: CustomColor.kLightSurface,
        onSurface: CustomColor.kTextPrimary,
        surfaceContainerHighest: CustomColor.kUltraLightBg,
        onSurfaceVariant: CustomColor.kTextSecondary,
        outline: CustomColor.kLightBorder,
      ),
      scaffoldBackgroundColor: CustomColor.kBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
            fontSize: 28.sp, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: textTheme.displayMedium?.copyWith(
            fontSize: 24.sp, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineLarge: textTheme.headlineLarge
            ?.copyWith(fontSize: 22.sp, fontWeight: FontWeight.w700),
        headlineMedium: textTheme.headlineMedium
            ?.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w600),
        titleLarge: textTheme.titleLarge
            ?.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w600),
        titleMedium: textTheme.titleMedium
            ?.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w600),
        bodyLarge: textTheme.bodyLarge?.copyWith(
            fontSize: 15.sp, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: textTheme.bodySmall?.copyWith(
            fontSize: 12.sp, fontWeight: FontWeight.w400, height: 1.4),
        labelLarge: textTheme.labelLarge?.copyWith(
            fontSize: 13.sp, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelSmall: textTheme.labelSmall?.copyWith(
            fontSize: 10.sp, fontWeight: FontWeight.w500, letterSpacing: 0.3),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: CustomColor.kLightSurface,
        foregroundColor: CustomColor.kTextPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headingMd
            .copyWith(color: CustomColor.kTextPrimary, letterSpacing: -0.2),
      ),
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        color: CustomColor.kCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius.r),
        ),
        margin: EdgeInsets.symmetric(
            horizontal: AppDimensions.cardPaddingH.w,
            vertical: AppSpacing.sm.h),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CustomColor.kUltraLightBg,
        contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.cardPaddingH.w,
            vertical: AppSpacing.lg.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(
            color: CustomColor.kPrimaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(
            color: CustomColor.kDangerRed,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(
            color: CustomColor.kDangerRed,
            width: 1.5,
          ),
        ),
        hintStyle:
            AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextTertiary),
        labelStyle:
            AppTextStyles.subtitle.copyWith(color: CustomColor.kTextSecondary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // kPrimaryFill, not kPrimaryColor: the FAB foreground is white, and white
        // on the identity blue is only 3.46:1.
        backgroundColor: CustomColor.kPrimaryFill,
        foregroundColor: CustomColor.kWhite,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CustomColor.kPrimaryLight,
        labelStyle:
            AppTextStyles.subtitle.copyWith(color: CustomColor.kOnPrimaryTint),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
        side: BorderSide.none,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: CustomColor.kLightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.modalRadius.r)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: CustomColor.kLightBorder,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CustomColor.kLightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: CustomColor.kLightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppDimensions.bottomNavHeight.h,
        indicatorColor: CustomColor.kPrimaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.caption
                .copyWith(color: CustomColor.kPrimaryColor);
          }
          return AppTextStyles.error.copyWith(color: CustomColor.kTextTertiary);
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.cardPaddingH.w,
          vertical: AppSpacing.xs.h,
        ),
        minVerticalPadding: AppSpacing.sm.h,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.horizontal),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [AppCustomColors.light],
    );
  }

  static ThemeData _buildDark() {
    final textTheme = GoogleFonts.poppinsTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: CustomColor.kPrimaryColor,
        onPrimary: CustomColor.kWhite,
        primaryContainer: CustomColor.kPrimaryDark,
        onPrimaryContainer: CustomColor.kPrimaryLight,
        secondary: CustomColor.kInfo,
        onSecondary: CustomColor.kWhite,
        secondaryContainer: CustomColor.kDarkSurface2,
        onSecondaryContainer: CustomColor.kTextOnDarkSecondary,
        tertiary: CustomColor.kGoldAccent,
        onTertiary: CustomColor.kWhite,
        error: CustomColor.kDangerRed,
        onError: CustomColor.kWhite,
        surface: CustomColor.kDarkSurface,
        onSurface: CustomColor.kTextOnDark,
        surfaceContainerHighest: CustomColor.kDarkSurface2,
        onSurfaceVariant: CustomColor.kTextOnDarkSecondary,
        outline: CustomColor.kDarkBorder,
      ),
      scaffoldBackgroundColor: CustomColor.kDarkBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: CustomColor.kTextOnDark),
        displayMedium: textTheme.displayMedium?.copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: CustomColor.kTextOnDark),
        headlineLarge: textTheme.headlineLarge?.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: CustomColor.kTextOnDark),
        headlineMedium: textTheme.headlineMedium?.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: CustomColor.kTextOnDark),
        titleLarge: textTheme.titleLarge?.copyWith(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: CustomColor.kTextOnDark),
        titleMedium: textTheme.titleMedium?.copyWith(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: CustomColor.kTextOnDark),
        bodyLarge: textTheme.bodyLarge?.copyWith(
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: CustomColor.kTextOnDarkSecondary),
        bodyMedium: textTheme.bodyMedium?.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: CustomColor.kTextOnDarkSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            height: 1.4,
            color: CustomColor.kTextOnDarkMuted),
        labelLarge: textTheme.labelLarge?.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: CustomColor.kTextOnDark),
        labelSmall: textTheme.labelSmall?.copyWith(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: CustomColor.kTextOnDarkMuted),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: CustomColor.kDarkSurface,
        foregroundColor: CustomColor.kTextOnDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.headingMd
            .copyWith(color: CustomColor.kTextOnDark, letterSpacing: -0.2),
      ),
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        color: CustomColor.kDarkSurface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius.r),
        ),
        margin: EdgeInsets.symmetric(
            horizontal: AppDimensions.cardPaddingH.w,
            vertical: AppSpacing.sm.h),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CustomColor.kDarkInputFill,
        contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.cardPaddingH.w,
            vertical: AppSpacing.lg.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(color: CustomColor.kDarkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(
            color: CustomColor.kPrimaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(
            color: CustomColor.kDangerRed,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          borderSide: BorderSide(
            color: CustomColor.kDangerRed,
            width: 1.5,
          ),
        ),
        hintStyle:
            AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextOnDarkMuted),
        labelStyle: AppTextStyles.subtitle
            .copyWith(color: CustomColor.kTextOnDarkSecondary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // kPrimaryFill, not kPrimaryColor: the FAB foreground is white, and white
        // on the identity blue is only 3.46:1.
        backgroundColor: CustomColor.kPrimaryFill,
        foregroundColor: CustomColor.kWhite,
        elevation: 6,
        highlightElevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CustomColor.kDarkSurface2,
        labelStyle:
            AppTextStyles.subtitle.copyWith(color: CustomColor.kPrimaryMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
        side: BorderSide(color: CustomColor.kDarkBorder),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: CustomColor.kDarkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.modalRadius.r)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: CustomColor.kDarkDivider,
        thickness: AppDimensions.dividerThickness,
        space: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CustomColor.kDarkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: CustomColor.kDarkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        ),
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppDimensions.bottomNavHeight.h,
        indicatorColor: CustomColor.kPrimaryDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.caption
                .copyWith(color: CustomColor.kPrimaryColor);
          }
          return AppTextStyles.error
              .copyWith(color: CustomColor.kTextOnDarkMuted);
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimensions.cardPaddingH.w,
          vertical: AppSpacing.xs.h,
        ),
        minVerticalPadding: AppSpacing.sm.h,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.horizontal),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
      extensions: [AppCustomColors.dark],
    );
  }
}
