import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class MessageReactionInfoSheet extends StatelessWidget {
  final String reactionsJson;

  const MessageReactionInfoSheet({super.key, required this.reactionsJson});

  Map<String, List<String>> get _reactions {
    try {
      final decoded = jsonDecode(reactionsJson);
      if (decoded is Map) {
        return Map<String, List<String>>.fromEntries(
          decoded.entries.map((e) => MapEntry(
                e.key.toString(),
                (e.value as List?)?.cast<String>() ?? const [],
              )),
        );
      }
    } catch (_) {}
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final reactions = _reactions;
    if (reactions.isEmpty) return const SizedBox.shrink();

    final chatController = Get.find<ChatController>();
    final myId = chatController.userController.userId;
    final contactController = Get.find<ContactController>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.62,
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color:
            Get.isDarkMode ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      child: SafeArea(
        top: false,
        child: Entrance(
            duration: const Duration(milliseconds: 280),
            slideOffset: const Offset(0, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Get.isDarkMode
                          ? CustomColor.kDarkDivider
                          : CustomColor.kLightBorder,
                      borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Text(
                      'Reactions',
                      style: AppTextStyles.titleLg.copyWith(
                          color: Get.isDarkMode
                              ? CustomColor.kTextOnDark
                              : CustomColor.kTextPrimary),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 30.r,
                        height: 30.r,
                        decoration: BoxDecoration(
                          color: Get.isDarkMode
                              ? CustomColor.kDarkSurface2
                              : CustomColor.kUltraLightBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16.r, color: CustomColor.kTextTertiary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: reactions.entries.map((entry) {
                      final emoji = entry.key;
                      final users = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(emoji, style: AppTextStyles.headingMd),
                                SizedBox(width: 8.w),
                                Text(
                                  '${users.length}',
                                  style: AppTextStyles.subtitle.copyWith(
                                      color: CustomColor.kPrimaryColor),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            ...users.map((userId) {
                              final isMe = userId == myId;
                              final name = isMe
                                  ? 'You'
                                  : _userName(contactController, userId);
                              final pic = isMe
                                  ? chatController
                                          .userController.user?.userImage ??
                                      ''
                                  : contactController.getUserProfilePic(userId);
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Row(
                                  children: [
                                    ClipOval(
                                      child: pic.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  '${Endpoints.mediaBaseUrl}$pic',
                                              width: 38.r,
                                              height: 38.r,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) =>
                                                  Image.asset(
                                                AppAssets.defaultProfilePic,
                                                width: 38.r,
                                                height: 38.r,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Image.asset(
                                              AppAssets.defaultProfilePic,
                                              width: 38.r,
                                              height: 38.r,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.label.copyWith(
                                            color: Get.isDarkMode
                                                ? CustomColor.kTextOnDark
                                                : CustomColor.kTextPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  String _userName(ContactController contacts, String userId) {
    final name = contacts.getUserNameById(userId);
    if (name.isNotEmpty) return name;
    final user =
        contacts.hummingContacts.firstWhereOrNull((e) => e.userId == userId);
    if (user != null) {
      final fallback =
          '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'.trim();
      if (fallback.isNotEmpty) return fallback;
      if ((user.userMobileNum ?? '').isNotEmpty) return user.userMobileNum!;
    }
    return 'User';
  }
}
