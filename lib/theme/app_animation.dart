import 'package:flutter/material.dart';

class AppAnimation {
  AppAnimation._();

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve linear = Curves.linear;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration extraSlow = Duration(milliseconds: 600);

  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration bubbleAppear = Duration(milliseconds: 300);
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration cardHover = Duration(milliseconds: 200);
  static const Duration snackbar = Duration(milliseconds: 250);
  static const Duration shimmer = Duration(milliseconds: 800);
}
