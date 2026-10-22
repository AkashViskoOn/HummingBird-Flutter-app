import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_icons.dart';

class ChatSearchBar extends StatelessWidget {
  const ChatSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl.w, vertical: AppSpacing.md.h),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        boxShadow: AppShadow.elevatedLight,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatController.searchController,
              autofocus: true,
              onChanged: (query) => chatController.searchInChat(query),
              decoration: InputDecoration(
                hintText: 'Search in chat...',
                hintStyle: AppTextStyles.bodyMd
                    .copyWith(color: CustomColor.kTextTertiary),
                prefixIcon: Icon(Icons.search_rounded,
                    color: CustomColor.kPrimaryColor, size: AppIcons.xl.r),
                suffixIcon: Obx(() => chatController.searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: Icon(Icons.close_rounded, size: AppIcons.lg.r),
                        onPressed: () => chatController.clearSearch(),
                      )
                    : const SizedBox.shrink()),
                filled: true,
                fillColor: CustomColor.kUltraLightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
