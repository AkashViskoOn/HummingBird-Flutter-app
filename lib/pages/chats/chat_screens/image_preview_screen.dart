import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/chat_ui/chat_text_field.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/common/widgets/image_error_placeholder.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_icons.dart';

class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final bool isScheduled;
  const ImagePreviewScreen(
      {super.key, required this.imageFile, this.isScheduled = false});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return SafeArea(
      child: Scaffold(
        backgroundColor: CustomColor.kDarkSecondaryColor,
        body: Entrance(
            fade: true,
            slide: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.w, vertical: AppSpacing.xs.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(
                      Icons.keyboard_backspace,
                      color: CustomColor.kTextOnDark,
                      size: 30.r,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: SizedBox(
                      width: double.maxFinite,
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => ImageErrorPlaceholder(
                          width: Get.width,
                          height: Get.height * 0.8,
                          iconColor: CustomColor.kOverlay70,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                    child: Row(
                      children: [
                        const Flexible(child: ChatTextField()),
                        SizedBox(
                          width: AppSpacing.xs.w,
                        ),
                        GestureDetector(
                            onTap: () {
                              chatController.sendMedia(
                                messageType: 1,
                                includeText: true,
                                isScheduled: isScheduled,
                              );
                              Get.back();
                            },
                            child: Container(
                              padding: EdgeInsets.all(AppSpacing.xs.r),
                              decoration: const BoxDecoration(
                                  color: CustomColor.k2LightsecondaryColor,
                                  shape: BoxShape.circle),
                              child: Icon(Icons.send,
                                  size: AppIcons.big.r,
                                  color: CustomColor.kDarkPrimaryColor),
                            )),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.lg.h,
                  ),
                ],
              ),
            )),
      ),
    );
  }
}
