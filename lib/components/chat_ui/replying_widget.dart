import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:humming_bird/components/chat_ui/widgets/reply_media_thumb.dart';

class ReplyingMessageContainer extends StatelessWidget {
  const ReplyingMessageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return Obx(
      () => chatController.isReplyOnMessage.value
          ? Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl.w, vertical: AppSpacing.md.h),
              decoration: BoxDecoration(
                color: CustomColor.kDarkSurface2,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xxxl.r)),
                boxShadow: AppShadow.elevatedDark,
              ),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.xxs.w,
                    height: AppSpacing.page.h,
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryColor,
                      borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg.w),
                  if (chatController.repliedMessage!.mMessageType!.trim() !=
                      '0') ...[
                    ReplyMediaThumb(
                      message: chatController.repliedMessage!,
                      size: 36,
                    ),
                    SizedBox(width: AppSpacing.md.w),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Replying',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 11.sp,
                            color: CustomColor.kPrimaryColor,
                            letterSpacing: null,
                          ),
                        ),
                        Text(
                          chatController.repliedMessage!.mMessageType!.trim() ==
                                  '0'
                              ? (LinkPreviewService.isLink(
                                      chatController.repliedMessage!.mMessage)
                                  ? LinkPreviewService.linkSummary(
                                      chatController.repliedMessage!.mMessage)
                                  : (chatController.repliedMessage!.mMessage ??
                                      ''))
                              : AppHelper.getMediaName(
                                  fileType: chatController
                                      .repliedMessage!.mMessageType!),
                          style: AppTextStyles.subtitle.copyWith(
                            color:
                                CustomColor.kTextOnDark.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      chatController.isReplyOnMessage.value = false;
                      chatController.repliedMessage = null;
                      chatController.repliedOnId = null;
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md.r),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      child: Icon(
                        Icons.close_rounded,
                        color: CustomColor.kTextOnDark.withValues(alpha: 0.7),
                        size: AppIcons.xl.r,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
