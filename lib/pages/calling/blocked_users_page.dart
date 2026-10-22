import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/settings/clean_tiles.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();
    final contactController = Get.find<ContactController>();

    return Scaffold(

      appBar: CommonAppBar(title: 'Blocked Users'),
      body: GetBuilder<ContactController>(
        id: 'block-unblock',
        init: contactController,
        builder: (contactCtrl) => Obx(() {
          final chatBlocked = _chatBlockedIds();
          final callBlocked = controller.blockedCallUsers;
          if (chatBlocked.isEmpty && callBlocked.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadBlockedUsers();
              contactCtrl.update(['block-unblock']);
            },
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                if (chatBlocked.isNotEmpty) ...[
                  const CleanSectionLabel(text: 'BLOCKED FROM CHATS'),
                  ...chatBlocked.asMap().entries.map((entry) {
                    final i = entry.key;
                    final id = entry.value;
                    return Entrance(
                      delayFactor: (i % 8) * 0.05,
                      child: _ChatBlockedTile(
                        userId: id,
                        onUnblock: () {
                          final name = contactController
                                  .resolveUserNameLocal(id)
                                  .isNotEmpty
                              ? contactController.resolveUserNameLocal(id)
                              : 'this user';
                          contactController.unBlockUser(id, name, pop: false);
                        },
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                ],
                if (callBlocked.isNotEmpty) ...[
                  const CleanSectionLabel(text: 'BLOCKED FROM CALLS'),
                  ...callBlocked.asMap().entries.map((entry) {
                    final i = entry.key;
                    final user = entry.value;
                    final name = user['name']?.toString() ??
                        user['contactName']?.toString() ??
                        'Unknown';
                    return Entrance(
                      delayFactor: (i % 8) * 0.05,
                      child: _BlockedUserTile(
                        name: name,
                        subtitle: "Can't call you",
                        image: user['image']?.toString() ??
                            user['contactImage']?.toString() ??
                            '',
                        onUnblock: () => controller.unblockCallUser(
                          user['userId']?.toString() ?? '',
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  List<String> _chatBlockedIds() {
    try {
      final raw =
          Get.find<ContactController>().userController.user?.userBlockList;
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.map((e) => e.toString()).toList() : [];
    } catch (_) {
      return [];
    }
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.block_rounded,
      title: 'No blocked users',
      message: 'Blocked contacts cannot message or call you',
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String image;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.name,
    required this.subtitle,
    required this.image,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: CustomColor.kCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          border: Border.all(
            color: CustomColor.kLightBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: CustomColor.kDangerRed.withValues(alpha: 0.1),
              backgroundImage: image.isNotEmpty
                  ? CachedNetworkImageProvider(image.startsWith('http')
                      ? image
                      : '${Endpoints.mediaBaseUrl}$image')
                  : const AssetImage(AppAssets.defaultProfilePic)
                      as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd
                        .copyWith(color: CustomColor.kTextPrimary),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm
                        .copyWith(color: CustomColor.kTextTertiary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onUnblock,
              style: TextButton.styleFrom(
                backgroundColor:
                    CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              child: Text(
                'Unblock',
                style: AppTextStyles.label
                    .copyWith(color: CustomColor.kPrimaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile for chat-blocked users — resolves the user id to a real
/// name/number (server fetch + Hive cache) instead of showing "User".
class _ChatBlockedTile extends StatefulWidget {
  final String userId;
  final VoidCallback onUnblock;

  const _ChatBlockedTile({
    required this.userId,
    required this.onUnblock,
  });

  @override
  State<_ChatBlockedTile> createState() => _ChatBlockedTileState();
}

class _ChatBlockedTileState extends State<_ChatBlockedTile> {
  late final ContactController _contactController;
  late final Future<({String name, String number})> _identityFuture;

  @override
  void initState() {
    super.initState();
    _contactController = Get.find<ContactController>();
    _identityFuture = _contactController.resolveUserIdentity(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String name, String number})>(
      future: _identityFuture,
      initialData: (
        name: _contactController.resolveUserNameLocal(widget.userId),
        number: '',
      ),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '';
        final number = snapshot.data?.number ?? '';
        final hasName = name.isNotEmpty && name != number;
        final title =
            hasName ? name : (number.isNotEmpty ? number : widget.userId);
        final subtitle = hasName && number.isNotEmpty
            ? number
            : "Can't send you messages or call you";

        return _BlockedUserTile(
          name: title,
          subtitle: subtitle,
          image: '',
          onUnblock: widget.onUnblock,
        );
      },
    );
  }
}
