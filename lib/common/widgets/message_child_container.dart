import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';

class MessageChildContainer extends StatelessWidget {
  const MessageChildContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: MessageClipper(),
      child: Container(
        width: 35.r,
        height: 35.r,
        decoration: const BoxDecoration(
          color: CustomColor.kPrimaryColor,
        ),
      ),
    );
  }
}

class LeftMessageChildContainer extends StatelessWidget {
  const LeftMessageChildContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: LeftMessageClipper(),
      child: Container(
        width: 35.r,
        height: 35.r,
        decoration: const BoxDecoration(
          color: CustomColor.kReceivedBubble,
        ),
      ),
    );
  }
}

class MessageClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    var mPath = Path();

    mPath.moveTo(size.width * 0.4, size.height * 0.37);
    mPath.lineTo(size.width * 0.7, size.height * 0.68);
    mPath.lineTo(0, size.height * 0.55);

    return mPath;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return false;
  }
}

class LeftMessageClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    var mPath = Path();

    mPath.moveTo(size.width * 0.6, size.height * 0.37);
    mPath.lineTo(size.width * 0.3, size.height * 0.68);
    mPath.lineTo(size.width, size.height * 0.55);

    return mPath;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) {
    return false;
  }
}
