import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/res/colors.dart';

/// Verifies the documented WCAG 2.1 contrast claims in `CustomColor` instead
/// of trusting the comments. Every pairing the code comments assert as
/// "4.5:1" (AA for normal text) must actually clear 4.5 under the WCAG
/// relative-luminance formula — else the accessibility score is fiction.
///
/// Also asserts the two luminance-driven helpers return a legible foreground.
void main() {
  group('WCAG 2.1 relative luminance', () {
    test('known anchors compute correctly', () {
      // White vs black is exactly 21:1.
      expect(contrastRatio(Color(0xFFFFFFFF), Color(0xFF000000)),
          closeTo(21, 0.01));
      // White vs mid-grey #777777 is ~4.48:1 (classic reference value).
      expect(contrastRatio(Color(0xFFFFFFFF), Color(0xFF777777)),
          closeTo(4.48, 0.02));
    });
  });

  group('Brand core vs surfaces', () {
    const pairs = <(Color, Color, num)>[
      // text, background, expected minimum ratio
      (CustomColor.kTextPrimary, CustomColor.kBackground, 12),
      (CustomColor.kTextPrimary, CustomColor.kLightSurface, 13),
      (CustomColor.kTextSecondary, CustomColor.kBackground, 4.5),
      (CustomColor.kTextSecondary, CustomColor.kLightSurface, 4.5),
      (CustomColor.kTextTertiary, CustomColor.kBackground, 4.5),
      (CustomColor.kTextTertiary, CustomColor.kLightSurface, 4.5),
      (CustomColor.kSlate400, CustomColor.kBackground, 4.5),
      (CustomColor.kInk700, CustomColor.kLightSurface, 7),
      (CustomColor.kInk600, CustomColor.kLightSurface, 4.5),
    ];

    for (final (fg, bg, min) in pairs) {
      test('${fg.toARGB32()} on ${bg.toARGB32()} >= $min:1',
          () {
        final ratio = contrastRatio(fg, bg);
        expect(ratio, greaterThanOrEqualTo(min),
            reason:
                '$ratio:1 for ${fg.toARGB32()} on ${bg.toARGB32()} — below '
                'claimed $min:1');
      });
    }
  });

  group('Button fills carry a white label (>= 4.5:1)', () {
    const fills = <(Color, String)>[
      (CustomColor.kPrimaryFill, 'kPrimaryFill'),
      (CustomColor.kPrimaryFillDeep, 'kPrimaryFillDeep'),
      (CustomColor.kPrimaryDark, 'kPrimaryDark'),
      (CustomColor.kDangerFill, 'kDangerFill'),
      (CustomColor.kSuccessFill, 'kSuccessFill'),
      (CustomColor.kInfoFill, 'kInfoFill'),
      (CustomColor.kWarningFill, 'kWarningFill'),
      (CustomColor.kPurpleFill, 'kPurpleFill'),
      (CustomColor.kPinkFill, 'kPinkFill'),
      (CustomColor.kSentBubble1, 'kSentBubble1'),
      (CustomColor.kSentBubble2, 'kSentBubble2'),
    ];

    for (final (fill, name) in fills) {
      test('white text on $name >= 4.5:1', () {
        final ratio = contrastRatio(CustomColor.kWhite, fill);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '$name is only $ratio:1 against white');
      });
    }
  });

  group('Accent-as-text on a light surface (>= 4.5:1)', () {
    const texts = <(Color, String)>[
      (CustomColor.kPrimaryText, 'kPrimaryText'),
      (CustomColor.kOnPrimaryTint, 'kOnPrimaryTint (on kPrimaryLight)'),
      (CustomColor.kDangerText, 'kDangerText'),
      (CustomColor.kSuccessText, 'kSuccessText'),
      (CustomColor.kInfoText, 'kInfoText'),
      (CustomColor.kWarningText, 'kWarningText'),
      (CustomColor.kPurpleText, 'kPurpleText'),
      (CustomColor.kPinkText, 'kPinkText'),
    ];

    for (final (fg, name) in texts) {
      test('$name on kBackground >= 4.5:1', () {
        final ratio = contrastRatio(fg, CustomColor.kBackground);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: '$name is only $ratio:1 on kBackground');
      });
    }

    test('kOnPrimaryTint clears 4.5:1 on its actual tint surface', () {
      final ratio = contrastRatio(
          CustomColor.kOnPrimaryTint, CustomColor.kPrimaryLight);
      expect(ratio, greaterThanOrEqualTo(4.5),
          reason: 'tint text only $ratio:1 on kPrimaryLight');
    });
  });

  group('Dark theme text on dark surfaces', () {
    const pairs = <(Color, Color, num)>[
      (CustomColor.kTextOnDark, CustomColor.kDarkBackground, 13),
      (CustomColor.kTextOnDark, CustomColor.kDarkSurface, 13),
      (CustomColor.kTextOnDarkSecondary, CustomColor.kDarkSurface, 4.5),
      (CustomColor.kTextOnDarkMuted, CustomColor.kDarkSurface, 4.5),
      (CustomColor.kDangerRed, CustomColor.kDarkSurface, 4.5),
      (CustomColor.kPrimaryColor, CustomColor.kDarkSurface, 4.5),
    ];

    for (final (fg, bg, min) in pairs) {
      test('${fg.toARGB32()} on ${bg.toARGB32()} >= $min:1', () {
        final ratio = contrastRatio(fg, bg);
        expect(ratio, greaterThanOrEqualTo(min),
            reason:
                '$ratio:1 for ${fg.toARGB32()} on ${bg.toARGB32()} — below '
                '$min:1');
      });
    }
  });

  group('Luminance-driven foreground helpers', () {
    test('onColor picks dark ink on light surfaces, white on dark', () {
      expect(CustomColor.onColor(CustomColor.kBackground),
          CustomColor.kTextPrimary);
      expect(CustomColor.onColor(CustomColor.kLightSurface),
          CustomColor.kTextPrimary);
      expect(CustomColor.onColor(CustomColor.kDarkSurface),
          CustomColor.kTextOnDark);
      expect(CustomColor.onColor(CustomColor.kPrimaryFill),
          CustomColor.kTextOnDark);
    });

    test('onColor result is always legible (> 3:1) against its background',
        () {
      for (final bg in [
        CustomColor.kBackground,
        CustomColor.kLightSurface,
        CustomColor.kDarkSurface,
        CustomColor.kPrimaryFill,
        CustomColor.kDangerFill,
        CustomColor.kGoldAccent,
        CustomColor.kBrandPurple,
      ]) {
        final ratio = contrastRatio(CustomColor.onColor(bg), bg);
        expect(ratio, greaterThanOrEqualTo(3.0),
            reason: 'onColor(${bg.toARGB32()}) gives only $ratio:1');
      }
    });

    test('dangerTextFor is 4.5:1 on both brightnesses', () {
      for (final isDark in [false, true]) {
        final fg = CustomColor.dangerTextFor(isDark);
        final bg = isDark
            ? CustomColor.kDarkSurface
            : CustomColor.kBackground;
        final ratio = contrastRatio(fg, bg);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: 'danger text only $ratio:1 (isDark=$isDark)');
      }
    });

    test('primaryTextFor is 4.5:1 on both brightnesses', () {
      for (final isDark in [false, true]) {
        final fg = CustomColor.primaryTextFor(isDark);
        final bg = isDark
            ? CustomColor.kDarkSurface
            : CustomColor.kBackground;
        final ratio = contrastRatio(fg, bg);
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason: 'primary text only $ratio:1 (isDark=$isDark)');
      }
    });
  });
}

/// WCAG 2.1 contrast ratio between two opaque [Color]s.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = max(la, lb);
  final darker = min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

double relativeLuminance(Color c) {
  // Flutter's current Color exposes .r/.g/.b as doubles in 0..1 (legacy ints
  // were 0..255). Normalize whatever range we get into sRGB 0..1.
  double channel(double v) {
    final s = v <= 1.0 ? v : v / 255.0;
    if (s <= 0.03928) return s / 12.92;
    return pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}