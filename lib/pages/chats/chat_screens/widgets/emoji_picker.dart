import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:flutter/foundation.dart' as foundation;

class EmojiPickerSheet extends StatelessWidget {
  /// Prefers a dark premium palette (used by the dark create-schedule screen).
  /// Defaults to the ambient theme so existing chat surfaces stay unchanged.
  final bool dark;
  const EmojiPickerSheet({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    final useDark = dark || Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: useDark
            ? CustomColor.kDarkBackground
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl.r)),
        boxShadow: AppShadow.cardLight,
      ),
      child: EmojiPicker(
        textEditingController: chatController.textMessageController,
        config: Config(
          height: 300.h,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            buttonMode: ButtonMode.MATERIAL,
            emojiSizeMax: 28 *
                (foundation.defaultTargetPlatform == TargetPlatform.iOS
                    ? 1.20
                    : 1.0),
            backgroundColor:
                useDark ? CustomColor.kDarkSurface2 : CustomColor.kSurfaceTint,
            noRecents: Text(
              'No recents',
              style: TextStyle(
                fontSize: 14,
                color: useDark ? CustomColor.kTextOnDarkMuted : Colors.black26,
              ),
            ),
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: useDark
              ? const CategoryViewConfig(
                  backgroundColor: CustomColor.kDarkSurface,
                  indicatorColor: CustomColor.kPrimaryColor,
                  iconColor: CustomColor.kTextOnDarkMuted,
                  iconColorSelected: CustomColor.kPrimaryColor,
                  backspaceColor: CustomColor.kPrimaryMedium,
                  dividerColor: CustomColor.kDarkDivider,
                )
              : const CategoryViewConfig(),
          bottomActionBarConfig: const BottomActionBarConfig(),
          searchViewConfig: useDark
              ? const SearchViewConfig(
                  backgroundColor: CustomColor.kDarkSurface,
                  buttonIconColor: CustomColor.kTextOnDarkSecondary,
                  inputTextStyle:
                      TextStyle(color: CustomColor.kTextOnDark, fontSize: 14),
                  hintTextStyle: TextStyle(
                      color: CustomColor.kTextOnDarkMuted, fontSize: 13),
                )
              : const SearchViewConfig(),
        ),
      ),
    );
  }
}
