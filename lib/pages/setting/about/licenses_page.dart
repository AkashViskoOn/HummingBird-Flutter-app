import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(
        title: 'Open Source Licenses',
        backgroundColor: CustomColor.kDarkBackground,
      ),
      body: LicensePage(
        applicationName: 'Humming Bird',
        applicationVersion: '1.0.0',
        applicationIcon: Icon(
          Icons.chat_bubble_rounded,
          size: 48.r,
          color: CustomColor.kPrimaryColor,
        ),
        applicationLegalese: '© 2026 Humming Bird',
      ),
    );
  }
}
