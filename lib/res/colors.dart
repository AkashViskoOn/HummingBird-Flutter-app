import 'dart:math' show max, min, pow;

import 'package:flutter/material.dart';

class CustomColor {
  // ═══════════════════════════════════════════════════════════════════════════════
  // NEW BRAND IDENTITY — Primary Blue #2192CF
  // ═══════════════════════════════════════════════════════════════════════════════

  // ── Brand Core ──────────────────────────────────────────────────────────────
  // #2192CF is the single source of truth. kBrandPrimary was a second,
  // competing blue nine steps away; it is now an alias of kPrimaryColor so a
  // screen can never render two "primary" blues side by side.
  static const kPrimaryColor = Color(0xff2192CF);
  static const kPrimaryDark = Color(0xff1678B8);
  static const kPrimaryLight = Color(0xffD6EEFA);
  static const kPrimaryMedium = Color(0xff38A7E6);
  static const kUltraLightPrimary = Color(0xffF0F8FE);

  // ── Humming Bird Signature Palette ──────────────────────────────────────────
  static const kBrandPrimary = kPrimaryColor;
  static const kBrandSecondary = Color(0xFF47B8F3);
  static const kBrandLight = Color(0xFFEAF7FF);
  static const kBrandBorder = Color(0xFFB9E5FF);
  static const kBrandAccent = Color(0xFF0C87D5);

  // ── Neutral Ink (warm-cool neutral ramp) ───────────────────────────────────
  // Replaces the free-floating #0B1727 / #111827 / #1F2937 / #222222 / #1A1A1A
  // blacks that were all used as "the app's dark text colour".
  static const kInk900 = Color(0xFF0B1727);
  static const kInk800 = Color(0xFF16202F);
  static const kInk700 = Color(0xFF2B3648);
  static const kInk600 = Color(0xFF475569);

  // ── Neutral Slate (muted text ramp) ─────────────────────────────────────────
  // Replaces #6B7280 / #6F7696 / #7F8C8D / #94A3B8 / #90A2B6 duplicates.
  static const kSlate700 = Color(0xFF53657C);
  static const kSlate500 = Color(0xFF6F7696);
  // 4.5:1 on kBackground. The old #94A3B8 sat at 2.40:1, which is why every
  // hint and placeholder read as washed out.
  static const kSlate400 = Color(0xFF68727F);
  static const kSlate300 = Color(0xFFB8C5D6);
  static const kSlate200 = Color(0xFFDCE3EC);
  static const kSlate100 = Color(0xFFEDF1F6);

  // ── Surface Tint ramp ───────────────────────────────────────────────────────
  // Replaces nine near-identical "barely tinted white" backgrounds
  // (#F8FCFF, #F7FBFF, #F7F3FF, #FFF6F0, #FEF1F6, #E6F4FF, #DCEFFF, #E0EAF5,
  //  #F0F4FA) with a single four-step ramp.
  static const kSurfaceTintStrong = Color(0xFFE4EDF7);
  static const kSurfaceTint = Color(0xFFEEF5FB);
  static const kSurfaceTintSoft = Color(0xFFF4F8FC);
  static const kSurfaceTintMuted = Color(0xFFF7FAFE);

  // ── Dark Surface (extended) ─────────────────────────────────────────────────
  // The call screens and OTP screen each invented their own near-black.
  static const kDarkDeep = Color(0xFF0A111C);
  static const kDarkSurfaceAlt = Color(0xFF1A2A40);
  static const kDarkSurface4 = Color(0xFF2A3B52);

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static const kDarkBackground = kDarkDeep;
  static const kDarkSurface = Color(0xff111C2D);
  static const kDarkSurface2 = Color(0xff172437);
  static const kDarkSurface3 = Color(0xff1D2C42);
  static const kDarkFloating = Color(0xff24354F);
  static const kDarkBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const kDarkDivider = kDarkSurface4;
  static const kDarkInputFill = Color(0xff18263A);
  static const kDarkPrimaryColor = kDarkSurface2;

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static const kBackground = kSurfaceTintSoft;
  static const kLightSurface = Color(0xffFFFFFF);
  static const kLightSurface2 = kSurfaceTintMuted;
  static const kCardBackground = Color(0xffFFFFFF);
  static const kLightBorder = kSurfaceTintStrong;
  static const kUltraLightBg = kSurfaceTint;
  static const kLightBg = kSurfaceTintStrong;

  // ── White Overlay ramp ───────────────────────────────────────────────────────
  // The 46 distinct alpha literals scattered across the app collapse to this
  // nine-step ramp. Declared as consts so they stay valid inside const
  // gradients and const widget trees.
  static const kOverlay4 = Color(0x0AFFFFFF);
  static const kOverlay6 = Color(0x0FFFFFFF);
  static const kOverlay8 = Color(0x14FFFFFF);
  static const kOverlay12 = Color(0x1FFFFFFF);
  static const kOverlay14 = Color(0x24FFFFFF);
  static const kOverlay18 = Color(0x2EFFFFFF);
  static const kOverlay20 = Color(0x33FFFFFF);
  static const kOverlay24 = Color(0x3DFFFFFF);
  static const kOverlay30 = Color(0x4DFFFFFF);
  static const kOverlay38 = Color(0x61FFFFFF);
  static const kOverlay40 = Color(0x66FFFFFF);
  static const kOverlay54 = Color(0x8AFFFFFF);
  static const kOverlay60 = Color(0x99FFFFFF);
  static const kOverlay70 = Color(0xB3FFFFFF);
  static const kOverlay80 = Color(0xCCFFFFFF);
  static const kOverlay85 = Color(0xD9FFFFFF);
  static const kOverlay90 = Color(0xE6FFFFFF);
  static const kOverlay95 = Color(0xF2FFFFFF);
  static const kOverlay98 = Color(0xFAFFFFFF);

  // ── Black Overlay ramp (scrims, shadows) ─────────────────────────────────────
  static const kScrim20 = Color(0x33000000);
  static const kScrim40 = Color(0x66000000);
  static const kScrim45 = Color(0x73000000);
  static const kScrim60 = Color(0x99000000);

  // ── Glass ───────────────────────────────────────────────────────────────────
  static const kGlassColor = Color(0x0FFFFFFF); // rgba(255,255,255,.08)
  static const kGlassColor2 = Color(0x05FFFFFF); // rgba(255,255,255,.02)

  /// Foreground that is legible on top of [background].
  ///
  /// A surface can be passed in by a caller (a user-chosen status background, a
  /// branded bar) and the app cannot assume it is light. Picking the label
  /// colour from the surface's own luminance is what keeps a bar from ending up
  /// with dark text on a dark fill.
  static Color onColor(Color background) {
    return _contrast(kTextPrimary, background) >=
            _contrast(kTextOnDark, background)
        ? kTextPrimary
        : kTextOnDark;
  }

  /// WCAG 2.1 contrast ratio between two opaque colours.
  static double _contrast(Color a, Color b) {
    final la = _luminance(a);
    final lb = _luminance(b);
    final lighter = max(la, lb);
    final darker = min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _luminance(Color c) {
    double channel(double v) {
      final s = v <= 1.0 ? v : v / 255.0;
      if (s <= 0.03928) return s / 12.92;
      return pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  /// Danger-coloured *text* for the current surface.
  ///
  /// Neither the identity red nor the light-mode text red works everywhere:
  /// kDangerRed is only 3.53:1 on a light surface, and kDangerText is 3.70:1 on
  /// a dark one. The bright/dark split is the only pair that clears 4.5:1 in
  /// both, so it is resolved from the ambient brightness rather than picked per
  /// call site.
  ///
  /// Takes a bool rather than a [Brightness] so it can be fed straight from the
  /// `bool get _isDark => ...` accessors these screens already expose.
  static Color dangerTextFor(bool isDark) => isDark ? kDangerRed : kDangerText;

  /// Primary-coloured *text* for the current surface. kPrimaryColor is 3.24:1
  /// on light and 5.48:1 on dark, so the same split applies.
  static Color primaryTextFor(bool isDark) =>
      isDark ? kPrimaryColor : kPrimaryText;

  // ═══════════════════════════════════════════════════════════════════════════════
  // ACCESSIBLE ROLES
  // The bright accent above is an *identity* colour. It cannot be reused for
  // two jobs: white labels on a filled button need >= 4.5:1, and accent-coloured
  // body text on a light surface needs >= 4.5:1. Those are separate roles, so
  // each accent gets an explicit -Fill (for white-on-colour) and -Text
  // (accent-as-type-on-light) variant. Measured, not guessed.
  // ═══════════════════════════════════════════════════════════════════════════════

  // ── Button fills (white label on top: all >= 4.5:1) ─────────────────────────
  static const kPrimaryFill = Color(0xFF1A7DB3);
  // Darkest stop, for gradients that need real range while still carrying a
  // white label (7.11:1).
  static const kPrimaryFillDeep = Color(0xFF0E5C8C);
  static const kDangerFill = Color(0xFFD43E3E);
  static const kSuccessFill = Color(0xFF198340);
  static const kInfoFill = Color(0xFF2B79B9);
  static const kWarningFill = Color(0xFF9B650B);
  static const kPurpleFill = Color(0xFF8558EC);
  static const kPinkFill = Color(0xFFC94081);

  // ── Accent-as-text on a light surface (all >= 4.5:1) ────────────────────────
  static const kPrimaryText = Color(0xFF1979AC);
  // For a *tint* background (kPrimaryLight). A tint is lighter than kBackground,
  // so kPrimaryDark (4.06:1) fails there even though it passes on white.
  static const kOnPrimaryTint = Color(0xFF12619A);
  static const kDangerText = Color(0xFFCC3C3C);
  static const kSuccessText = Color(0xFF198340);
  static const kInfoText = Color(0xFF2975B1);
  static const kWarningText = Color(0xFF9B650B);
  static const kPurpleText = Color(0xFF7F54E2);
  static const kPinkText = Color(0xFFC13E7B);

  // ── Gold Accent ──────────────────────────────────────────────────────────────
  static const kGoldAccent = Color(0xffF59E0B);
  static const kGoldLight = Color(0xffFEF3C7);

  // ── Extended Accents ────────────────────────────────────────────────────────
  // Ten near-identical greens, reds, purples and oranges were each defined
  // locally. These collapse them onto one value per family.
  static const kBrandPink = Color(0xFFEC4899);
  static const kBrandPinkSoft = Color(0xFFFEF1F6);
  static const kBrandPurple = Color(0xFF8B5CF6);
  static const kBrandPurpleDeep = Color(0xFF4C1D95);
  static const kBrandPurpleSoft = Color(0xFFE6DFFB);
  static const kBrandIndigo = Color(0xFF2B579A);
  static const kSuccessDeep = Color(0xFF2E5A47);
  static const kSuccessSoft = Color(0xFFD9F2E6);
  static const kWarningDeep = Color(0xFF2B2410);
  static const kWarningSoft = Color(0xFFFFF176);
  static const kDangerSoft = Color(0xFFFEE2E2);
  static const kInfoSoft = Color(0xFFB3E5FC);

  // ── Base ─────────────────────────────────────────────────────────────────────
  static const kWhite = Color(0xffFFFFFF);
  static const kBlack = Color(0xff0B1727);

  // ── Text (Dark) ─────────────────────────────────────────────────────────────
  static const kTextOnDark = Color(0xffFFFFFF);
  static const kTextOnDarkSecondary = kSlate300;
  static const kTextOnDarkMuted = Color(0xff7B8DA7);

  // ── Text (Light) ────────────────────────────────────────────────────────────
  static const kTextPrimary = kInk900;
  static const kTextSecondary = kSlate700;
  static const kTextTertiary = kSlate400;

  // ── Status ───────────────────────────────────────────────────────────────────
  static const kOnlineGreen = Color(0xff22C55E);
  static const kDangerRed = Color(0xffEF4444);
  static const kDarkDangerColor = Color(0xffEF4444);
  static const kWarning = Color(0xffF59E0B);
  // Amber is hard to read on a white surface, so light mode uses a deeper
  // amber for text-adjacent accents.
  static const kWarningDark = Color(0xffB45309);
  static const kInfo = Color(0xff3BA8FF);
  static const kSuccess = Color(0xff22C55E);

  // ── Chat Bubbles ─────────────────────────────────────────────────────────────
  // Sent-bubble stops live on the AA-safe Fill ramp: white bubble text at 4.5:1
  // sits on whichever stop is lighter, so a brighter identity blue (3.46:1 for
  // #2192CF, 2.68:1 for #38A7E6) would fail WCAG 1.4.3 on half the bubble.
  static const kSentBubble1 = Color(0xff1678B8); // AA-safe on white text
  static const kSentBubble2 = Color(0xff0E5C8C); // AA-safe on white text
  static const kReceivedBubble = Color(0xffF0F4FA);
  static const kReceivedBubbleDark = Color(0xff1D2C42);

  // ── Borders / Dividers ───────────────────────────────────────────────────────
  static const kBorderAlpha = 0.08;
  static const kShadowAlphaLow = 0.04;
  static const kShadowAlphaHigh = 0.12;
  static const kIncomingBubbleBorder = Color(0x0f2192CF);

  // ── Glow ─────────────────────────────────────────────────────────────────────
  static const kPrimaryGlow = Color(0x4D2192CF); // rgba(33,146,207,0.30)

  // ═══════════════════════════════════════════════════════════════════════════════
  // LEGACY ALIASES — kept for backward compatibility
  // All old references map to the new brand colors
  // ═══════════════════════════════════════════════════════════════════════════════

  // Old brand (6C63FF purple) → New brand (2192CF blue)
  static const kMutedPurple = Color(0xff5B9BD5);
  static const kHeaderTint = kPrimaryLight;
  static const kDeepInk = kDarkBackground;
  static const kSoftLavender = kPrimaryLight;
  static const kLightDanger = Color(0xffFEE2E2);
  static const kLightDangerColor = kLightDanger;
  static const kLightPrimaryColor = kPrimaryLight;
  static const kDarkSecondaryColor = kDarkSurface;
  static const kSecondaryColor = kPrimaryColor;
  static const k2SecondaryColor = kTextSecondary;
  static const kLightSecondaryColor = kPrimaryLight;
  static const k2LightsecondaryColor = kWhite;
  static const kUltraLightPrimaryColor = kUltraLightPrimary;

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kDarkSurface, kDarkSurface2],
  );

  // Gradient over a filled button carrying a white label: BOTH stops come from
  // the AA-safe Fill ramp. A gradient's lightest stop is what the white label
  // actually sits against, so mixing the brighter identity blue back in would
  // put the label back below 4.5:1 on that half of the button.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kPrimaryFill, kPrimaryDark],
  );

  static const LinearGradient sentBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kSentBubble1, kSentBubble2],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kGoldAccent, Color(0xffD97706)],
  );

  // ── New Premium Gradients ───────────────────────────────────────────────────
  static const LinearGradient primaryVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [kPrimaryColor, kPrimaryMedium, kPrimaryDark],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [kGlassColor, kGlassColor2],
  );
}
