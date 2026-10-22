import 'package:flutter/material.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_list.dart';
import 'package:humming_bird/res/colors.dart';

/// Standalone page wrapper for [ScheduleMessagesList] — the list itself is an
/// embeddable widget (used inside the Schedule tab) and contains Material
/// widgets (ChoiceChip etc.), so when pushed as its own route it must be
/// wrapped in a Scaffold with an AppBar.
class ScheduledMessagesPage extends StatelessWidget {
  final bool showHeader;

  const ScheduledMessagesPage({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? CustomColor.kDarkBackground
          : CustomColor.kUltraLightPrimaryColor,
      appBar: CommonAppBar(title: 'Scheduled Messages'),
      body: ScheduleMessagesList(showHeader: showHeader),
    );
  }
}
