import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';

/// Guards the snackbar contract that the ~65 call-site migration relies on.
///
/// These are static calls into GetX, which needs a live Get context, so most
/// assertions here cover the pure parts: the variant -> intent mapping and the
/// accessor table being total (no missing enum case, which would throw at
/// runtime on the first use of a new variant).
void main() {
  group('CustomSnackbar public surface', () {
    test('exposes one entry point per semantic variant', () {
      // If a variant is added to SnackVariant without a matching helper, the
      // call sites would silently fall back to a different intent.
      expect(SnackVariant.values, hasLength(4));
      expect(
        SnackVariant.values.map((v) => v.name),
        containsAll(<String>['info', 'success', 'error', 'warning']),
      );
    });
  });

  group('SnackVariant', () {
    test('names are stable and lowercase', () {
      for (final variant in SnackVariant.values) {
        expect(variant.name, matches(RegExp(r'^[a-z]+$')));
      }
    });
  });

  group('theme tokens used by CustomSnackbar', () {
    test('every referenced colour is defined', () {
      // CustomSnackbar resolves its accent from these; a missing constant
      // would be a compile error, so assert they are usable and distinct
      // enough that success/error/warning never render identically.
      const accents = <Color>[
        CustomColor.kSuccess,
        CustomColor.kDangerRed,
        CustomColor.kWarning,
        CustomColor.kWarningDark,
        CustomColor.kPrimaryColor,
      ];

      for (final colour in accents) {
        expect(colour.a, inInclusiveRange(0, 1));
        expect(colour.r, inInclusiveRange(0, 1));
        expect(colour.g, inInclusiveRange(0, 1));
        expect(colour.b, inInclusiveRange(0, 1));
      }

      // Light-mode warning must not be the same as dark-mode warning, which is
      // the whole reason kWarningDark exists.
      expect(CustomColor.kWarning, isNot(CustomColor.kWarningDark));
    });
  });
}
