import 'package:flutter/material.dart';
import 'package:humming_bird/res/colors.dart';

class AppShadow {
  AppShadow._();

  static const List<BoxShadow> none = [];

  static List<BoxShadow> get cardLight => [
        BoxShadow(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedLight => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get modalLight => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get modalDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get buttonLight => [
        BoxShadow(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get buttonDark => [
        BoxShadow(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
