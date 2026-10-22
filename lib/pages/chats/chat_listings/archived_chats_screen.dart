import 'package:flutter/material.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/pages/chats/chat_listings/single_chats_listing.dart';
import 'package:humming_bird/res/colors.dart';

/// Dedicated Archived Chats screen. Reuses [SingleChatListing] with
/// `showArchived: true` so archived one-to-one AND group chats render with
/// the exact same tile component, long-press actions and unarchive flow as
/// the main chat list. Unarchiving instantly returns a chat to the main
/// list (HomeController.toggleArchive handles optimistic update + rollback).
class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      appBar: CommonAppBar(title: 'Archived'),
      body: const SingleChatListing(showArchived: true),
    );
  }
}
