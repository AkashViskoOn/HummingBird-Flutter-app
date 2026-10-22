import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';

class ReactionPicker extends StatelessWidget {
  final String messageId;

  const ReactionPicker({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Container(
      height: 350.h,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl.r)),
        boxShadow: AppShadow.cardLight,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
            child: Container(
              width: 32.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.xxs.r),
              ),
            ),
          ),
          Expanded(
            child: EmojiPicker(
              textEditingController: TextEditingController(),
              config: Config(
                height: 300.h,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  buttonMode: ButtonMode.MATERIAL,
                  emojiSizeMax: 28 * 1.0,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: const CategoryViewConfig(),
                bottomActionBarConfig: const BottomActionBarConfig(
                  showSearchViewButton: false,
                ),
                searchViewConfig: const SearchViewConfig(),
              ),
              onEmojiSelected: (category, emoji) {
                chatController.toggleReaction(messageId, emoji.emoji);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
