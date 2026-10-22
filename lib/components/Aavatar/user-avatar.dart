import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';

class UserAvatarList extends StatelessWidget {
  final String filename;
  final String name;
  final double radius;
  const UserAvatarList({
    super.key,
    required this.filename,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    // `name` was already required at every call site but never rendered, so
    // screen readers had an unlabelled image. Expose it as the image label.
    final label = name.trim();
    return Semantics(
      image: true,
      label: label.isEmpty ? 'Profile picture' : '$label profile picture',
      excludeSemantics: true,
      child: CircleAvatar(
        radius: radius + 4.r,
        backgroundColor: CustomColor.kPrimaryLight,
        child: CircleAvatar(
          radius: radius.r,
          backgroundImage: Image.asset("assets/images/$filename").image,
          onBackgroundImageError: (_, __) {},
        ),
      ),
    );
  }
}
