import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/res/colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 28.sp,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.poppins(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get headingXl => GoogleFonts.poppins(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get headingLg => GoogleFonts.poppins(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get headingMd => GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get headingSm => GoogleFonts.poppins(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get titleLg => GoogleFonts.poppins(
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get titleMd => GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get titleSm => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get subtitle => GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        color: CustomColor.kTextSecondary,
      );

  static TextStyle get bodyLg => GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get bodyMd => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get bodySm => GoogleFonts.poppins(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: CustomColor.kTextSecondary,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: CustomColor.kTextTertiary,
      );

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get labelSm => GoogleFonts.poppins(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: CustomColor.kTextTertiary,
      );

  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: CustomColor.kWhite,
      );

  static TextStyle get buttonSm => GoogleFonts.poppins(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: CustomColor.kWhite,
      );

  static TextStyle get helper => GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: CustomColor.kTextTertiary,
      );

  static TextStyle get error => GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: CustomColor.kDangerText,
      );

  static TextStyle get chatTime => GoogleFonts.poppins(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: CustomColor.kTextTertiary,
      );

  static TextStyle get chatName => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextPrimary,
      );

  static TextStyle get chatPreview => GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        color: CustomColor.kTextSecondary,
      );

  static TextStyle get chatBadge => GoogleFonts.poppins(
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        color: CustomColor.kWhite,
      );

  static TextStyle get buttonPrimary => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kWhite,
      );

  static TextStyle get captionOnDark => GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        color: CustomColor.kTextOnDarkMuted,
      );

  static TextStyle get bodyMdOnDark => GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: CustomColor.kTextOnDarkSecondary,
      );

  static TextStyle get bodySmOnDark => GoogleFonts.poppins(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: CustomColor.kTextOnDarkMuted,
      );

  static TextStyle get headingMdOnDark => GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextOnDark,
      );

  static TextStyle get titleMdOnDark => GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        color: CustomColor.kTextOnDark,
      );

  static TextStyle get labelOnDark => GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: CustomColor.kTextOnDark,
      );

  static TextStyle get labelSmOnDark => GoogleFonts.poppins(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: CustomColor.kTextOnDarkMuted,
      );

  static TextStyle get displayLargeOnDark => displayLarge.copyWith(
        color: CustomColor.kTextOnDark,
      );

  static TextStyle get displayMediumOnDark => displayMedium.copyWith(
        color: CustomColor.kTextOnDark,
      );

  static TextStyle get headingXlOnDark => headingXl.copyWith(
        color: CustomColor.kTextOnDark,
      );

  static TextStyle get headingLgOnDark => headingLg.copyWith(
        color: CustomColor.kTextOnDark,
      );

  static TextStyle get bodyLgOnDark => bodyLg.copyWith(
        color: CustomColor.kTextOnDarkSecondary,
      );
}
