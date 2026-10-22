import 'package:flutter/material.dart';
import 'package:humming_bird/res/colors.dart';

class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color? primaryColor;
  final Color? primaryDark;
  final Color? primaryLight;
  final Color? primaryMedium;
  final Color? ultraLightPrimary;
  final Color? textPrimary;
  final Color? textSecondary;
  final Color? textTertiary;
  final Color? textOnDark;
  final Color? textOnDarkSecondary;
  final Color? textOnDarkMuted;
  final Color? onlineGreen;
  final Color? dangerRed;
  final Color? warning;
  final Color? success;
  final Color? info;
  final Color? goldAccent;
  final Color? sentBubble1;
  final Color? sentBubble2;
  final Color? receivedBubble;
  final Color? receivedBubbleDark;
  final Color? lightBorder;
  final Color? ultraLightBg;
  final Color? darkBorder;
  final Color? darkDivider;
  final Color? darkInputFill;
  final LinearGradient? primaryGradient;
  final LinearGradient? sentBubbleGradient;

  const AppCustomColors({
    this.primaryColor,
    this.primaryDark,
    this.primaryLight,
    this.primaryMedium,
    this.ultraLightPrimary,
    this.textPrimary,
    this.textSecondary,
    this.textTertiary,
    this.textOnDark,
    this.textOnDarkSecondary,
    this.textOnDarkMuted,
    this.onlineGreen,
    this.dangerRed,
    this.warning,
    this.success,
    this.info,
    this.goldAccent,
    this.sentBubble1,
    this.sentBubble2,
    this.receivedBubble,
    this.receivedBubbleDark,
    this.lightBorder,
    this.ultraLightBg,
    this.darkBorder,
    this.darkDivider,
    this.darkInputFill,
    this.primaryGradient,
    this.sentBubbleGradient,
  });

  static const light = AppCustomColors(
    primaryColor: CustomColor.kPrimaryColor,
    primaryDark: CustomColor.kPrimaryDark,
    primaryLight: CustomColor.kPrimaryLight,
    primaryMedium: CustomColor.kPrimaryMedium,
    ultraLightPrimary: CustomColor.kUltraLightPrimary,
    textPrimary: CustomColor.kTextPrimary,
    textSecondary: CustomColor.kTextSecondary,
    textTertiary: CustomColor.kTextTertiary,
    textOnDark: CustomColor.kTextOnDark,
    textOnDarkSecondary: CustomColor.kTextOnDarkSecondary,
    textOnDarkMuted: CustomColor.kTextOnDarkMuted,
    onlineGreen: CustomColor.kOnlineGreen,
    dangerRed: CustomColor.kDangerRed,
    warning: CustomColor.kWarning,
    success: CustomColor.kSuccess,
    info: CustomColor.kInfo,
    goldAccent: CustomColor.kGoldAccent,
    sentBubble1: CustomColor.kSentBubble1,
    sentBubble2: CustomColor.kSentBubble2,
    receivedBubble: CustomColor.kReceivedBubble,
    receivedBubbleDark: CustomColor.kReceivedBubbleDark,
    lightBorder: CustomColor.kLightBorder,
    ultraLightBg: CustomColor.kUltraLightBg,
    darkBorder: CustomColor.kDarkBorder,
    darkDivider: CustomColor.kDarkDivider,
    darkInputFill: CustomColor.kDarkInputFill,
    primaryGradient: CustomColor.primaryGradient,
    sentBubbleGradient: CustomColor.sentBubbleGradient,
  );

  static const dark = AppCustomColors(
    primaryColor: CustomColor.kPrimaryColor,
    primaryDark: CustomColor.kPrimaryDark,
    primaryLight: CustomColor.kPrimaryLight,
    primaryMedium: CustomColor.kPrimaryMedium,
    ultraLightPrimary: CustomColor.kUltraLightPrimary,
    textPrimary: CustomColor.kTextOnDark,
    textSecondary: CustomColor.kTextOnDarkSecondary,
    textTertiary: CustomColor.kTextOnDarkMuted,
    textOnDark: CustomColor.kTextOnDark,
    textOnDarkSecondary: CustomColor.kTextOnDarkSecondary,
    textOnDarkMuted: CustomColor.kTextOnDarkMuted,
    onlineGreen: CustomColor.kOnlineGreen,
    dangerRed: CustomColor.kDangerRed,
    warning: CustomColor.kWarning,
    success: CustomColor.kSuccess,
    info: CustomColor.kInfo,
    goldAccent: CustomColor.kGoldAccent,
    sentBubble1: CustomColor.kSentBubble1,
    sentBubble2: CustomColor.kSentBubble2,
    receivedBubble: CustomColor.kReceivedBubbleDark,
    receivedBubbleDark: CustomColor.kReceivedBubbleDark,
    lightBorder: CustomColor.kDarkBorder,
    ultraLightBg: CustomColor.kDarkSurface2,
    darkBorder: CustomColor.kDarkBorder,
    darkDivider: CustomColor.kDarkDivider,
    darkInputFill: CustomColor.kDarkInputFill,
    primaryGradient: CustomColor.primaryGradient,
    sentBubbleGradient: CustomColor.sentBubbleGradient,
  );

  @override
  ThemeExtension<AppCustomColors> copyWith({
    Color? primaryColor,
    Color? primaryDark,
    Color? primaryLight,
    Color? primaryMedium,
    Color? ultraLightPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnDark,
    Color? textOnDarkSecondary,
    Color? textOnDarkMuted,
    Color? onlineGreen,
    Color? dangerRed,
    Color? warning,
    Color? success,
    Color? info,
    Color? goldAccent,
    Color? sentBubble1,
    Color? sentBubble2,
    Color? receivedBubble,
    Color? receivedBubbleDark,
    Color? lightBorder,
    Color? ultraLightBg,
    Color? darkBorder,
    Color? darkDivider,
    Color? darkInputFill,
    LinearGradient? primaryGradient,
    LinearGradient? sentBubbleGradient,
  }) {
    return AppCustomColors(
      primaryColor: primaryColor ?? this.primaryColor,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryMedium: primaryMedium ?? this.primaryMedium,
      ultraLightPrimary: ultraLightPrimary ?? this.ultraLightPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnDark: textOnDark ?? this.textOnDark,
      textOnDarkSecondary: textOnDarkSecondary ?? this.textOnDarkSecondary,
      textOnDarkMuted: textOnDarkMuted ?? this.textOnDarkMuted,
      onlineGreen: onlineGreen ?? this.onlineGreen,
      dangerRed: dangerRed ?? this.dangerRed,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      info: info ?? this.info,
      goldAccent: goldAccent ?? this.goldAccent,
      sentBubble1: sentBubble1 ?? this.sentBubble1,
      sentBubble2: sentBubble2 ?? this.sentBubble2,
      receivedBubble: receivedBubble ?? this.receivedBubble,
      receivedBubbleDark: receivedBubbleDark ?? this.receivedBubbleDark,
      lightBorder: lightBorder ?? this.lightBorder,
      ultraLightBg: ultraLightBg ?? this.ultraLightBg,
      darkBorder: darkBorder ?? this.darkBorder,
      darkDivider: darkDivider ?? this.darkDivider,
      darkInputFill: darkInputFill ?? this.darkInputFill,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      sentBubbleGradient: sentBubbleGradient ?? this.sentBubbleGradient,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t),
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t),
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t),
      primaryMedium: Color.lerp(primaryMedium, other.primaryMedium, t),
      ultraLightPrimary:
          Color.lerp(ultraLightPrimary, other.ultraLightPrimary, t),
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t),
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t),
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t),
      textOnDark: Color.lerp(textOnDark, other.textOnDark, t),
      textOnDarkSecondary:
          Color.lerp(textOnDarkSecondary, other.textOnDarkSecondary, t),
      textOnDarkMuted: Color.lerp(textOnDarkMuted, other.textOnDarkMuted, t),
      onlineGreen: Color.lerp(onlineGreen, other.onlineGreen, t),
      dangerRed: Color.lerp(dangerRed, other.dangerRed, t),
      warning: Color.lerp(warning, other.warning, t),
      success: Color.lerp(success, other.success, t),
      info: Color.lerp(info, other.info, t),
      goldAccent: Color.lerp(goldAccent, other.goldAccent, t),
      sentBubble1: Color.lerp(sentBubble1, other.sentBubble1, t),
      sentBubble2: Color.lerp(sentBubble2, other.sentBubble2, t),
      receivedBubble: Color.lerp(receivedBubble, other.receivedBubble, t),
      receivedBubbleDark:
          Color.lerp(receivedBubbleDark, other.receivedBubbleDark, t),
      lightBorder: Color.lerp(lightBorder, other.lightBorder, t),
      ultraLightBg: Color.lerp(ultraLightBg, other.ultraLightBg, t),
      darkBorder: Color.lerp(darkBorder, other.darkBorder, t),
      darkDivider: Color.lerp(darkDivider, other.darkDivider, t),
      darkInputFill: Color.lerp(darkInputFill, other.darkInputFill, t),
      primaryGradient: primaryGradient ?? other.primaryGradient,
      sentBubbleGradient: sentBubbleGradient ?? other.sentBubbleGradient,
    );
  }
}
